extends SceneTree

# Sonde jetable — retour de Kinder : « il ne part pas dans la direction où il
# m'a vu fuir ».
#
# Piege monte expres : le joueur est vu dans le couloir a (-7, 0, 0) et fuit
# vers le NORD (l'Entree, a z=-5). Mais la Chambre (z=+4) est PLUS PROCHE de
# ce dernier point de contact. Sans extrapolation de la fuite, le rodeur part
# donc fouiller la Chambre — a l'oppose. Avec, il doit filer vers l'Entree.

var jeu: Node3D = null
var frames := 0
var echecs := 0
var phase := "attente"
var premiere_piece := ""
var ancre := Vector3.ZERO
var derniere_vue := Vector3.ZERO


func _process(_delta: float) -> bool:
	if jeu == null:
		jeu = load("res://jeu.tscn").instantiate()
		root.add_child(jeu)
		return false
	var rodeur: CharacterBody3D = jeu.get_node("Rodeur")
	if not rodeur.visible:
		frames += 1
		if frames > 200:
			_exige("la maison devient prete", false)
			return _fin()
		return false

	var joueur: CharacterBody3D = jeu.get_node("Joueur")
	frames += 1

	if phase == "attente":
		joueur.set_physics_process(false)
		joueur.global_position = Vector3(-7.0, 0.1, 0.0)
		joueur.velocity = Vector3(0.0, 0.0, -4.5)   # il COURT vers le nord
		rodeur.global_position = Vector3(-2.0, 0.0, 0.0)
		rodeur.rotation = Vector3(0.0, deg_to_rad(90.0), 0.0)
		rodeur.commence_poursuite()
		phase = "fuite"
		frames = 0
		return false

	if phase == "fuite":
		joueur.velocity = Vector3(0.0, 0.0, -4.5)  # on maintient la course
		if frames < 8:
			return false
		_exige("il poursuit et voit sa course", rodeur.en_poursuite)
		_exige("il a retenu une direction de fuite vers le NORD (z=%.2f)"
			% rodeur.direction_de_fuite.z, rodeur.direction_de_fuite.z < -0.8)
		derniere_vue = rodeur.derniere_position_connue
		# Le joueur disparait : teleporte loin, hors de vue.
		joueur.global_position = Vector3(8.5, 0.1, 3.5)   # Bureau
		joueur.velocity = Vector3.ZERO
		phase = "battue"
		frames = 0
		return false

	if phase == "battue":
		if rodeur.en_battue and premiere_piece == "":
			if rodeur.pieces_fouillees.size() > 0:
				premiere_piece = rodeur.pieces_fouillees[0]
				ancre = rodeur.ancre_battue
		if premiere_piece != "" or frames > 20000:
			_exige("il vise un point AU-DELA du dernier contact, vers le nord "
				+ "(contact z=%.1f -> ancre z=%.1f)" % [derniere_vue.z, ancre.z],
				ancre.z < derniere_vue.z - 3.0)
			_exige("il fouille d'abord l'Entree, dans la direction de la fuite "
				+ "(obtenu : %s)" % premiere_piece, premiere_piece == "Entree")
			_exige("il ne part PAS dans la Chambre, pourtant plus proche du contact",
				premiere_piece != "Chambre")
			return _fin()
		return false

	return false


func _fin() -> bool:
	print("=== ECHECS DIRECTION: %d ===" % echecs)
	quit(1 if echecs > 0 else 0)
	return true


func _exige(nom: String, condition: bool) -> void:
	if condition:
		print("OK   %s" % nom)
	else:
		echecs += 1
		print("RATE %s" % nom)
