extends Node

## Le JOUEUR lui-même — jamais testé jusqu'ici, alors que tout passe par lui.
## On vérifie ce qu'il fait, pas ce que le manoir fait : avancer, être arrêté
## par un mur, entrer et sortir d'une cachette, et ne plus pouvoir bouger ni
## se retourner librement une fois caché.

var jeu: Node3D
var joueur: CharacterBody3D
var echecs := 0


func _ready() -> void:
	jeu = load("res://jeu.tscn").instantiate()
	add_child(jeu)
	await jeu.get_node("Maison").navigation_prete
	for i in 20:
		await get_tree().physics_frame
	joueur = jeu.get_node("Joueur")
	for r in get_tree().get_nodes_in_group("rodeurs"):
		r.actif = false
		r.joueur_attrape.disconnect(jeu._on_joueur_attrape)
		r.global_position = Vector3(0.0, 60.0, 0.0)

	# ---- Il avance ----
	joueur.set_physics_process(false)
	joueur.global_position = Vector3(0.0, 0.1, 0.0)   # couloir principal
	joueur.rotation = Vector3.ZERO
	await get_tree().physics_frame
	var depart: Vector3 = joueur.global_position
	for i in 40:
		joueur.velocity = Vector3(-3.0, 0.0, 0.0)
		joueur.move_and_slide()
		await get_tree().physics_frame
	var parcouru: float = depart.distance_to(joueur.global_position)
	controle("il avance quand on le pousse (%.2f m)" % parcouru, parcouru > 1.0)

	# ---- Un mur l'arrête ----
	joueur.global_position = Vector3(-10.2, 0.1, 0.0)  # contre le bout ouest
	await get_tree().physics_frame
	var avant_mur: Vector3 = joueur.global_position
	for i in 40:
		joueur.velocity = Vector3(-4.0, 0.0, 0.0)
		joueur.move_and_slide()
		await get_tree().physics_frame
	var traverse: float = absf(joueur.global_position.x - avant_mur.x)
	controle("un mur l'arrête (poussé 40 images, avancé de %.2f m)" % traverse,
		traverse < 1.0)

	# ---- Il reste au sol ----
	controle("il reste au sol (y=%.2f)" % joueur.global_position.y,
		absf(joueur.global_position.y) < 0.3)

	# ---- Les cachettes, vues du côté du joueur ----
	var cachettes := get_tree().get_nodes_in_group("cachettes")
	controle("les neuf cachettes sont là", cachettes.size() == 9)
	var abri: Node3D = cachettes[0]
	var regard: Vector3 = -abri.global_transform.basis.z
	var p: Vector3 = abri.global_position + regard * 1.5
	joueur.set_physics_process(true)
	joueur.global_position = Vector3(p.x, abri.global_position.y + 0.1, p.z)
	joueur.rotation = Vector3.ZERO
	var cam: Camera3D = joueur.get_node("Camera3D")
	cam.rotation = Vector3.ZERO
	for i in 10:
		await get_tree().physics_frame
	cam.look_at(abri.global_position + Vector3.UP * 1.3, Vector3.UP)
	for i in 5:
		await get_tree().physics_frame

	agir()
	await get_tree().physics_frame
	controle("il entre dans une cachette", joueur.est_cache())
	controle("caché, il ne se déplace plus", not joueur.is_physics_processing())
	controle("caché, l'écran affiche la fente", jeu.fente.visible)
	controle("caché, on lui propose de sortir (« %s »)" % jeu.message_action.text,
		jeu.message_action.text == "Sortir")

	# Le regard est bridé : on pousse la souris à fond, il ne doit pas pivoter.
	var cap_avant: float = joueur.rotation.y
	for i in 10:
		var m := InputEventMouseMotion.new()
		m.relative = Vector2(400.0, 0.0)
		joueur.regarde_par_la_fente(m.relative)
	var pivot: float = absf(angle_difference(cap_avant, joueur.rotation.y))
	controle("caché, son regard reste bridé (%.0f° de débattement)" % rad_to_deg(pivot),
		rad_to_deg(pivot) < 30.0)

	agir()
	await get_tree().physics_frame
	controle("il ressort de la cachette", not joueur.est_cache())
	controle("dehors, il se redéplace", joueur.is_physics_processing())
	controle("dehors, la fente disparaît", not jeu.fente.visible)

	print("=== ECHECS CONTROLES: %d ===" % echecs)
	get_tree().quit(1 if echecs > 0 else 0)


func agir() -> void:
	var e := InputEventAction.new()
	e.action = "agir"
	e.pressed = true
	joueur._unhandled_input(e)


func controle(nom: String, condition: bool) -> void:
	if condition:
		print("OK   %s" % nom)
	else:
		echecs += 1
		print("RATE %s" % nom)
