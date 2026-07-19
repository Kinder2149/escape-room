extends SceneTree

# Jet 11, etape 3 : chaque allure a sa demarche.
#  A) en ronde (2 m/s)          -> Marche
#  B) en poursuite a vue (4 m/s)-> Course
#  C) plante a fouiller (0 m/s)  -> Guet
# Et l'ancienne silhouette, qui n'a pas d'animation, ne doit rien casser.

var jeu: Node3D = null
var frames := 0
var echecs := 0
var phase := "ronde"
var vues: Dictionary = {}

func _process(_d: float) -> bool:
	if jeu == null:
		jeu = load("res://jeu.tscn").instantiate()
		root.add_child(jeu)
		return false
	var l := get_nodes_in_group("rodeurs")
	if l.is_empty() or not l[0].visible:
		frames += 1
		return frames > 400
	var r: CharacterBody3D = l[0]
	var j: CharacterBody3D = jeu.get_node("Joueur")
	frames += 1
	if frames == 3:
		for x in l:
			x.joueur_attrape.disconnect(jeu._on_joueur_attrape)
		l[1].actif = false
		l[1].global_position = Vector3(0, 40, 0)
		j.set_physics_process(false)
		j.global_position = Vector3(0, 40, 0)
		_exige("l'ancienne silhouette n'a pas d'animation et ne plante pas",
			l[1].animations == null)
		return false

	var vitesse := Vector2(r.velocity.x, r.velocity.z).length()
	if frames > 20 and r.animations != null:
		var a: String = r.animations.current_animation
		if not vues.has(a): vues[a] = [0, 0.0]
		vues[a][0] += 1
		vues[a][1] = maxf(vues[a][1], vitesse)

	if phase == "ronde" and frames > 500:
		_exige("A) en ronde, il MARCHE (%s a %.1f m/s)"
			% [r.animations.current_animation, vitesse],
			r.animations.current_animation == "Marche")
		# Poursuite a vue, a des coordonnees CONNUES du couloir principal :
		# teleporter « devant lui » l'envoyait parfois dans un mur, cible
		# inatteignable, et il s'arretait au lieu de courir.
		r.global_position = Vector3(-2.0, 0.0, 0.0)
		r.rotation = Vector3(0.0, deg_to_rad(90.0), 0.0)
		j.global_position = Vector3(-9.0, 0.1, 0.0)
		r.en_battue = false
		r.commence_poursuite()
		phase = "course"
		frames = 480
		return false

	if phase == "course" and frames > 520:
		_exige("B) en poursuite a vue, il COURT (%s a %.1f m/s)"
			% [r.animations.current_animation, vitesse],
			r.animations.current_animation == "Course")
		# On le fige : c'est ce qu'il fait quand il balaie une piece.
		r.en_poursuite = false
		r.en_battue = true
		r.agent.target_position = r.global_position
		phase = "guet"
		frames = 500
		return false

	if phase == "guet" and frames > 560:
		_exige("C) a l'arret, il GUETTE (%s a %.1f m/s)"
			% [r.animations.current_animation, vitesse],
			r.animations.current_animation == "Guet")
		print("   demarches vues : %s" % [vues.keys()])
		print("=== ECHECS DEMARCHES: %d ===" % echecs)
		quit(1 if echecs > 0 else 0)
		return true
	return false

func _exige(nom: String, condition: bool) -> void:
	if condition:
		print("OK   %s" % nom)
	else:
		echecs += 1
		print("RATE %s" % nom)
