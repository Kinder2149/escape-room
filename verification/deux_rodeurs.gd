extends SceneTree

# Sonde jetable — jet 8, etape 6 : un rodeur par niveau.
# A) 12 tirages : chacun demarre CHEZ LUI, un par niveau, jamais les deux au
#    meme etage, et chacun ne ronde que sur les pieces de son niveau.
# B) La poursuite franchit l'escalier : le rodeur du bas voit le joueur monter
#    et le suit a l'etage.
# C) Perdu de vue en haut, il ratisse le niveau ou il l'a perdu, puis REDESCEND
#    chez lui (sa ronde ne connait que le rez-de-chaussee).

var jeu: Node3D = null
var frames := 0
var essais := 0
var echecs := 0
var phase := "tirages"
var suivi := false
var y_max_suivi := 0.0
var redescendu := false


func _process(_delta: float) -> bool:
	if jeu == null:
		jeu = load("res://jeu.tscn").instantiate()
		root.add_child(jeu)
		frames = 0
		return false
	var liste := get_nodes_in_group("rodeurs")
	if liste.is_empty() or not liste[0].visible:
		frames += 1
		if frames > 400:
			_exige("la maison devient prete", false)
			return _fin()
		return false
	frames += 1
	if frames < 3:
		return false

	if phase == "tirages":
		_exige("il y a bien deux rodeurs", liste.size() == 2)
		var bas: CharacterBody3D = liste[0]
		var haut: CharacterBody3D = liste[1]
		_exige("tirage %d : le premier demarre au rez-de-chaussee (y=%.2f)"
			% [essais + 1, bas.global_position.y], bas.global_position.y < 1.5)
		_exige("tirage %d : le second demarre a l'etage (y=%.2f)"
			% [essais + 1, haut.global_position.y], haut.global_position.y > 1.5)
		_exige("tirage %d : sa ronde du bas ne connait que le plain-pied" % [essais + 1],
			_toutes_au_niveau(bas.destinations, 0.0))
		_exige("tirage %d : sa ronde du haut ne connait que l'etage" % [essais + 1],
			_toutes_au_niveau(haut.destinations, 3.2))
		_exige("tirage %d : chacun connait tout le manoir pour ratisser" % [essais + 1],
			bas.toutes_les_pieces.size() == 12 and haut.toutes_les_pieces.size() == 12)
		jeu.queue_free()
		jeu = null
		essais += 1
		if essais >= 12:
			phase = "poursuite"
		return false

	if phase == "poursuite":
		var bas: CharacterBody3D = liste[0]
		var haut: CharacterBody3D = liste[1]
		# Sans ca, la poursuite se termine par une capture : la partie s'arrete
		# et les rodeurs sont figes — on mesurerait un cadavre.
		for r in liste:
			r.joueur_attrape.disconnect(jeu._on_joueur_attrape)
		haut.actif = false
		haut.global_position = Vector3(0.0, 20.0, 0.0)
		var joueur: CharacterBody3D = jeu.get_node("Joueur")
		joueur.set_physics_process(false)
		# Le joueur au pied de l'escalier est, le rodeur du bas juste derriere.
		joueur.global_position = Vector3(25.3, 0.1, -7.0)
		bas.global_position = Vector3(25.3, 0.0, -8.4)
		bas.rotation = Vector3(0.0, deg_to_rad(180.0), 0.0)
		bas.commence_poursuite()
		phase = "montee"
		frames = 0
		return false

	if phase == "montee":
		var bas: CharacterBody3D = liste[0]
		var joueur: CharacterBody3D = jeu.get_node("Joueur")
		# Le joueur grimpe : on le remonte progressivement le long de la volee.
		var t: float = minf(frames / 120.0, 1.0)
		joueur.global_position = Vector3(25.3, 0.1 + t * 3.2, -7.0 + t * 8.0)
		joueur.velocity = Vector3(0.0, 0.0, 4.0)
		y_max_suivi = maxf(y_max_suivi, bas.global_position.y)
		if bas.global_position.y > 2.0:
			suivi = true
		if frames > 900:
			_exige("le rodeur du BAS suit le joueur dans l'escalier (monte a y=%.2f)"
				% y_max_suivi, suivi)
			# Le joueur disparait : il doit ratisser en haut puis redescendre.
			joueur.global_position = Vector3(-7.5, 0.1, -5.0)
			joueur.velocity = Vector3.ZERO
			phase = "retour"
			frames = 0
		return false

	if phase == "retour":
		var bas: CharacterBody3D = liste[0]
		if frames % 2000 == 0:
			var ag: NavigationAgent3D = bas.get_node("NavigationAgent3D")
			var suiv := ag.get_next_path_position()
			print("   t=%d pos=%v vit=%.2f battue=%s vise=%s suivant=%v fini=%s"
				% [frames, bas.global_position,
					Vector2(bas.velocity.x, bas.velocity.z).length(),
					bas.en_battue, bas.piece_visee, suiv, ag.is_navigation_finished()])
		if bas.global_position.y < 1.0 and not bas.en_poursuite and not bas.en_battue:
			redescendu = true
		if redescendu or frames > 12000:
			_exige("puis il REDESCEND a son etage (y=%.2f, ronde=%s)"
				% [bas.global_position.y, bas.piece_visee], redescendu)
			return _fin()
		return false

	return false


func _toutes_au_niveau(points: Dictionary, y: float) -> bool:
	if points.is_empty():
		return false
	for nom in points:
		if absf(points[nom].y - y) > 1.5:
			return false
	return true


func _fin() -> bool:
	print("=== ECHECS DEUX RODEURS: %d ===" % echecs)
	quit(1 if echecs > 0 else 0)
	return true


func _exige(nom: String, condition: bool) -> void:
	if not condition:
		echecs += 1
		print("RATE %s" % nom)
	elif not nom.begins_with("tirage"):
		print("OK   %s" % nom)
