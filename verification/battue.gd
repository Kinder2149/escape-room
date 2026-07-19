extends SceneTree

# Sonde jetable — jet 7, retour de Kinder : « il reprend sa ronde au lieu de
# me chercher ». Scenario : le joueur est vu DANS LE COULOIR, fuit dans la
# chambre et s'y cache sans etre vu entrer.
# Attendu : le rodeur ratisse PLUSIEURS pieces du coin (dont la chambre),
# au pas, sans jamais attraper le joueur cache, puis renonce et reprend sa ronde.

var jeu: Node3D = null
var frames := 0
var echecs := 0
var attrape := false
var phase := "attente"

var pieces_vues: Array = []
var vitesse_max := 0.0
var a_ratisse := false
var a_repris_la_ronde := false
var distance_min_chambre := INF
var loin_de_lancre := 0.0


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
		rodeur.joueur_attrape.connect(func() -> void: attrape = true)
		joueur.global_position = Vector3(-7.0, 0.1, 0.0)   # couloir ouest
		rodeur.global_position = Vector3(-2.0, 0.0, 0.0)   # couloir, le voit
		rodeur.rotation = Vector3(0.0, deg_to_rad(90.0), 0.0)
		rodeur.commence_poursuite()
		phase = "poursuite"
		frames = 0
		return false

	if phase == "poursuite":
		if frames < 6:
			return false
		_exige("il poursuit", rodeur.en_poursuite)
		_exige("sa derniere position connue est dans le couloir (z=%.1f)"
			% rodeur.derniere_position_connue.z,
			absf(rodeur.derniere_position_connue.z) < 1.4)
		joueur.entre_dans_cachette(jeu.get_node("CachetteArmoire"))
		_exige("le joueur est cache", joueur.est_cache())
		phase = "battue"
		frames = 0
		return false

	if phase == "battue":
		if rodeur.en_battue:
			a_ratisse = true
			for p in rodeur.pieces_fouillees:
				if not p in pieces_vues:
					pieces_vues.append(p)
			vitesse_max = maxf(vitesse_max,
				Vector2(rodeur.velocity.x, rodeur.velocity.z).length())
			var ici := Vector2(rodeur.global_position.x, rodeur.global_position.z)
			distance_min_chambre = minf(distance_min_chambre, ici.distance_to(Vector2(-6.0, 4.0)))
			loin_de_lancre = maxf(loin_de_lancre,
				ici.distance_to(Vector2(rodeur.ancre_battue.x, rodeur.ancre_battue.z)))
		elif a_ratisse and not rodeur.en_poursuite:
			a_repris_la_ronde = true

		# On attend la fin reelle de la battue (jusqu'a 30 s de jeu), pas un
		# nombre d'images : en headless les images defilent bien plus vite
		# que le temps de la physique.
		if a_repris_la_ronde or frames > 40000:
			_exige("il lance une battue au lieu de repartir en ronde", a_ratisse)
			_exige("il fouille PLUSIEURS pieces du coin (%d : %s)"
				% [pieces_vues.size(), ", ".join(pieces_vues)], pieces_vues.size() >= 2)
			_exige("il fouille la chambre, la ou le joueur a disparu",
				"Chambre" in pieces_vues)
			_exige("il s'approche vraiment du coeur de la chambre (%.1f m)"
				% distance_min_chambre, distance_min_chambre < 2.0)
			_exige("il s'eloigne de l'ancre pour ratisser (%.1f m)" % loin_de_lancre,
				loin_de_lancre > 3.0)
			_exige("il ratisse au pas (%.1f m/s max)" % vitesse_max,
				vitesse_max > 0.5 and vitesse_max <= rodeur.VITESSE_MARCHE + 0.3)
			_exige("il finit par renoncer et reprendre sa ronde", a_repris_la_ronde)
			_exige("il n'a JAMAIS attrape le joueur cache", not attrape)
			_exige("le joueur est toujours cache et vivant", joueur.est_cache())
			return _fin()
		return false

	return false


func _fin() -> bool:
	print("=== ECHECS BATTUE: %d ===" % echecs)
	quit(1 if echecs > 0 else 0)
	return true


func _exige(nom: String, condition: bool) -> void:
	if condition:
		print("OK   %s" % nom)
	else:
		echecs += 1
		print("RATE %s" % nom)
