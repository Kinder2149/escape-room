extends SceneTree

# Sonde jetable — jet 11, etape 2 : le rodeur incarne marche-t-il sans glisser ?
# Le vrai piege : que le modele derive par rapport a son corps physique.
# On le laisse ronder et on mesure l'ecart entre le maillage et la capsule.

var jeu: Node3D = null
var frames := 0
var echecs := 0
var ecart_max := 0.0
var deplacement := 0.0
var depart := Vector3.ZERO
var anim_vue := ""


func _process(_delta: float) -> bool:
	if jeu == null:
		jeu = load("res://jeu.tscn").instantiate()
		root.add_child(jeu)
		return false
	var liste := get_nodes_in_group("rodeurs")
	if liste.is_empty() or not liste[0].visible:
		frames += 1
		return frames > 400
	var incarne: CharacterBody3D = liste[0]
	var ancien: CharacterBody3D = liste[1]
	frames += 1

	if frames == 3:
		for r in liste:
			r.joueur_attrape.disconnect(jeu._on_joueur_attrape)
		jeu.get_node("Joueur").set_physics_process(false)
		jeu.get_node("Joueur").global_position = Vector3(0.0, 40.0, 0.0)
		depart = incarne.global_position
		var lecteur: AnimationPlayer = incarne.animations
		_exige("le pantin a bien un lecteur d'animation", lecteur != null)
		if lecteur != null:
			anim_vue = lecteur.current_animation
			_exige("il joue « Marche » en boucle",
				anim_vue == "Marche" and lecteur.is_playing()
				and lecteur.get_animation("Marche").loop_mode == Animation.LOOP_LINEAR)
		_exige("celui de l'etage est incarne lui aussi",
			ancien.animations != null)
		return false

	if frames > 3:
		# L'ecart entre le maillage anime et le corps physique : c'est LA mesure.
		var m: MeshInstance3D = incarne.get_node("Modele/Armature/Skeleton3D/char1")
		var centre := m.global_transform.origin
		ecart_max = maxf(ecart_max, Vector2(centre.x - incarne.global_position.x,
			centre.z - incarne.global_position.z).length())
		deplacement = maxf(deplacement, incarne.global_position.distance_to(depart))

	if frames > 1200:
		_exige("il RONDE vraiment (parcouru %.1f m)" % deplacement, deplacement > 3.0)
		_exige("le pantin NE DERIVE PAS de son corps (ecart max %.3f m)" % ecart_max,
			ecart_max < 0.15)
		_exige("il reste au sol (y=%.2f)" % incarne.global_position.y,
			absf(incarne.global_position.y) < 0.3)
		print("=== ECHECS INCARNE: %d ===" % echecs)
		quit(1 if echecs > 0 else 0)
		return true
	return false


func _exige(nom: String, condition: bool) -> void:
	if condition:
		print("OK   %s" % nom)
	else:
		echecs += 1
		print("RATE %s" % nom)
