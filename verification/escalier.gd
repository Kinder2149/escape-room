extends SceneTree

# Sonde jetable — jet 8, etape 1 : la verticalite.
# LA question du jet : la carte de navigation monte-t-elle l'escalier ?
# 1. Le bas de la cage est praticable et joignable depuis le rez-de-chaussee.
# 2. La rampe elle-meme est praticable, a la bonne altitude, sur toute sa montee.
# 3. Le palier de l'etage est praticable ET joignable EN MARCHANT depuis le bas.
# 4. Preuve finale : un rodeur envoye au palier y arrive vraiment.

var jeu: Node3D = null
var frames := 0
var echecs := 0
var phase := "controles"
var palier := Vector3(21.7, 3.3, 1.0)
var depart_rodeur := Vector3.ZERO


func _process(_delta: float) -> bool:
	if jeu == null:
		jeu = load("res://jeu.tscn").instantiate()
		root.add_child(jeu)
		return false
	var rodeur: CharacterBody3D = jeu.get_node("Rodeur")
	if not rodeur.visible:
		frames += 1
		if frames > 300:
			_exige("la maison devient prete", false)
			return _fin()
		return false

	frames += 1
	var carte: RID = jeu.get_node("Joueur").get_world_3d().navigation_map
	var maison: Node3D = jeu.get_node("Maison")

	if phase == "controles":
		# 1. Le bas de la cage
		_praticable(carte, "bas de la cage d'escalier", Vector3(25.3, 0.1, -8.0))
		_joignable(maison, "bas de la cage depuis le couloir ouest",
			Vector3(-7.0, 0.1, 0.0), Vector3(25.3, 0.1, -8.0))

		# 2. La rampe, du bas vers le haut (y attendu = (z+7) * 0.4)
		for z in [-6.0, -4.0, -2.0, 0.0]:
			var attendu: float = (z + 7.0) * 0.4
			_praticable(carte, "rampe a z=%.0f (y attendu %.1f)" % [z, attendu],
				Vector3(25.3, attendu + 0.1, z))

		# 3. Le palier de l'etage
		_praticable(carte, "palier de l'etage", palier)
		_joignable(maison, "PALIER JOIGNABLE EN MARCHANT depuis le rez-de-chaussee",
			Vector3(-7.0, 0.1, 0.0), palier)

		# 4. Le rodeur y va vraiment
		var joueur: CharacterBody3D = jeu.get_node("Joueur")
		joueur.set_physics_process(false)
		joueur.global_position = Vector3(-7.5, 0.1, -5.0)  # loin, hors de vue
		rodeur.global_position = Vector3(21.8, 0.0, -8.0)  # galerie, pres de la cage
		depart_rodeur = rodeur.global_position
		# Deux destinations minimum : sa regle « jamais deux fois la meme piece
		# de suite » le laisserait sans choix avec une seule.
		rodeur.destinations = {"Palier": palier, "Galerie": Vector3(21.8, 0.1, 5.0)}
		rodeur.piece_visee = "Galerie"
		rodeur.piece_a_eviter = ""
		rodeur.en_poursuite = false
		rodeur.en_battue = false
		rodeur.choisis_piece()
		phase = "montee"
		frames = 0
		return false

	if phase == "montee":
		var ici: Vector3 = rodeur.global_position
		if frames % 600 == 0:
			print("   ... il grimpe : y=%.2f (x=%.1f z=%.1f) cible=%s"
				% [ici.y, ici.x, ici.z, rodeur.piece_visee])
		if ici.y > 3.0 and Vector2(ici.x, ici.z).distance_to(Vector2(palier.x, palier.z)) < 3.0:
			_exige("LE RODEUR EST MONTE A L'ETAGE (y=%.2f)" % ici.y, true)
			return _fin()
		if frames > 3000:
			_exige("le rodeur monte a l'etage (bloque a y=%.2f, x=%.1f z=%.1f)"
				% [ici.y, ici.x, ici.z], false)
			return _fin()
		return false

	return false


func _praticable(carte: RID, nom: String, point: Vector3) -> void:
	var proche := NavigationServer3D.map_get_closest_point(carte, point)
	var ecart_plan := Vector2(proche.x, proche.z).distance_to(Vector2(point.x, point.z))
	var ecart_haut: float = absf(proche.y - point.y)
	_exige("%s : sol praticable (ecart %.2f m au sol, %.2f m en hauteur)"
		% [nom, ecart_plan, ecart_haut], ecart_plan < 0.6 and ecart_haut < 0.6)


func _joignable(maison: Node3D, nom: String, depuis: Vector3, vers: Vector3) -> void:
	var carte: RID = maison.get_node("Navigation").get_navigation_map()
	var chemin := NavigationServer3D.map_get_path(carte, depuis, vers, true)
	var arrive := false
	if chemin.size() > 0:
		var bout: Vector3 = chemin[chemin.size() - 1]
		arrive = Vector2(bout.x, bout.z).distance_to(Vector2(vers.x, vers.z)) < 0.8 \
			and absf(bout.y - vers.y) < 0.8
	var longueur: float = maison.distance_de_marche(depuis, vers)
	_exige("%s (%.1f m de marche, %d points)" % [nom, longueur, chemin.size()], arrive)


func _fin() -> bool:
	print("=== ECHECS ESCALIER: %d ===" % echecs)
	quit(1 if echecs > 0 else 0)
	return true


func _exige(nom: String, condition: bool) -> void:
	if condition:
		print("OK   %s" % nom)
	else:
		echecs += 1
		print("RATE %s" % nom)
