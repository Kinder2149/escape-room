extends SceneTree

# Sonde jetable — retour de Kinder : « je descends d'un etage, il me lache ».
# Scenario : le rodeur de l'ETAGE voit le joueur, qui devale l'escalier est
# vers le rez-de-chaussee. Attendu :
#  A) il le VOIT encore pendant la descente (cone mesure a plat) ;
#  B) il le SUIT physiquement en bas ;
#  C) le joueur disparu, il ratisse EN BAS (la ou il l'a perdu), pas en haut ;
#  D) puis il remonte chez lui.

var jeu: Node3D = null
var frames := 0
var echecs := 0
var phase := "attente"
var vu_en_descendant := false
var y_min := 99.0
var battue_en_bas := false
var remonte := false
var rentre_juge := false
## Echeances en temps REEL (voir mur.gd).
var echeance := 0


func _process(_delta: float) -> bool:
	if jeu == null:
		jeu = load("res://jeu.tscn").instantiate()
		root.add_child(jeu)
		return false
	var liste := get_nodes_in_group("rodeurs")
	if liste.is_empty() or not liste[0].visible:
		frames += 1
		return frames > 400
	frames += 1
	var joueur: CharacterBody3D = jeu.get_node("Joueur")
	var haut: CharacterBody3D = liste[1]
	var bas: CharacterBody3D = liste[0]

	if phase == "attente":
		for r in liste:
			r.joueur_attrape.disconnect(jeu._on_joueur_attrape)
		bas.actif = false
		bas.global_position = Vector3(0.0, 30.0, 0.0)
		joueur.set_physics_process(false)
		# Joueur en haut de la volee est, rodeur de l'etage juste derriere lui.
		joueur.global_position = Vector3(25.3, 3.3, 1.0)
		haut.global_position = Vector3(25.3, 3.2, 2.2)
		haut.rotation = Vector3(0.0, deg_to_rad(180.0), 0.0)
		haut.commence_poursuite()
		echeance = Time.get_ticks_msec() + 15000
		phase = "descente"
		frames = 0
		return false

	if phase == "descente":
		# Le joueur devale la volee : de (z=1, y=3.2) a (z=-7, y=0).
		var t: float = minf(frames / 150.0, 1.0)
		joueur.global_position = Vector3(25.3, 3.3 - t * 3.2, 1.0 - t * 8.0)
		joueur.velocity = Vector3(0.0, 0.0, -4.0)
		if t > 0.25 and t < 0.9 and haut.voit_joueur():
			vu_en_descendant = true
		y_min = minf(y_min, haut.global_position.y)
		if Time.get_ticks_msec() > echeance:
			_exige("A) il le VOIT pendant la descente (cone a plat)", vu_en_descendant)
			_exige("B) il le SUIT jusqu'en bas (descendu a y=%.2f)" % y_min, y_min < 1.0)
			joueur.global_position = Vector3(-7.5, 0.1, -5.0)
			joueur.velocity = Vector3.ZERO
			phase = "battue"
			frames = 0
			echeance = Time.get_ticks_msec() + 120000
		return false

	if phase == "battue":
		if haut.en_battue and haut.niveau_battue < 1.5:
			battue_en_bas = true
		# On lit son INTENTION, pas son trajet : des que la battue est finie,
		# sa ronde doit viser une piece de SON etage. Attendre qu'il ait
		# physiquement remonte 46 m d'escalier prenait jusqu'a une minute et
		# ratait des que la machine etait chargee — on testait la marche,
		# pas la regle.
		if not haut.en_battue and battue_en_bas and haut.piece_visee != "":
			remonte = _piece_a_l_etage(haut.piece_visee)
			rentre_juge = true
		if rentre_juge or Time.get_ticks_msec() > echeance:
			_exige("C) il ratisse EN BAS, la ou il l'a perdu (niveau=%.1f)"
				% haut.niveau_battue, battue_en_bas)
			_exige("D) puis il REPART CHEZ LUI : sa ronde vise « %s », a l'etage"
				% haut.piece_visee, remonte)
			return _fin()
		return false

	return false


## Une pièce est-elle à l'étage ? On le lit sur l'altitude de son repère.
func _piece_a_l_etage(nom: String) -> bool:
	for p in get_nodes_in_group("pieces"):
		if String(p.name) == nom:
			return p.get_node("Reveil").global_position.y > 1.5
	return false


func _fin() -> bool:
	print("=== ECHECS DESCENTE: %d ===" % echecs)
	quit(1 if echecs > 0 else 0)
	return true


func _exige(nom: String, condition: bool) -> void:
	if condition:
		print("OK   %s" % nom)
	else:
		echecs += 1
		print("RATE %s" % nom)
