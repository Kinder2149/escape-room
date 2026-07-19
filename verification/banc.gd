extends Node

## Le banc de vérification du projet — l'outil de la machine, pas du joueur.
## À lancer en ligne de commande, sans fenêtre :
##   godot --headless --path . res://verification/banc.tscn
## Il rejoue les règles sensibles (vision du rôdeur, les quatre cachettes,
## les visées) et passe le même audit d'emplacements que le bandeau rouge
## de l'écran (voir maison.gd). « === ECHECS: 0 === » attendu ; tout autre
## nombre = un contrôle a raté, et le processus sort en erreur.

var jeu: Node3D
var joueur: CharacterBody3D
var rodeur: CharacterBody3D
var echecs := 0


func _ready() -> void:
	jeu = load("res://jeu.tscn").instantiate()
	add_child(jeu)
	await jeu.get_node("Maison").navigation_prete
	for i in 10:
		await get_tree().physics_frame
	joueur = jeu.get_node("Joueur")
	rodeur = jeu.get_node("Rodeur")
	joueur.set_physics_process(false)
	# TOUS les rôdeurs, pas seulement celui du rez-de-chaussée : depuis le
	# jet 8 celui de l'étage pourrait attraper le joueur en pleine mesure et
	# relancer la partie sous le banc.
	for r in get_tree().get_nodes_in_group("rodeurs"):
		r.joueur_attrape.disconnect(jeu._on_joueur_attrape)
		if r != rodeur:
			r.actif = false
			r.global_position = Vector3(0.0, 20.0, 0.0)

	# ---- La vue du rodeur ne doit pas etre bouchee par les zones de visee ----
	await pose(Vector3(-5, 0, 0), -90.0, Vector3(-1, 0, 0))
	controle("Il voit droit devant, a 4 m", rodeur.voit_joueur())
	await pose(Vector3(-5, 0, 0), -90.0, Vector3(-8.5, 0, 0))
	controle("A 3,5 m dans son dos : invisible", not rodeur.voit_joueur())
	await pose(Vector3(-5, 0, 0), -90.0, Vector3(-6.5, 0, 0))
	controle("A 1,5 m dans son dos : repere", rodeur.voit_joueur())
	await pose(Vector3(2, 0, 0), 180.0, Vector3(2, 0, 4))
	controle("Une cloison le cache", not rodeur.voit_joueur())

	# Le cas critique : le joueur juste devant une cachette, en vue du rôdeur.
	# La zone de visée ne doit pas servir d'écran.
	var c: Node3D = jeu.get_node("CachetteArmoire")
	var devant: Vector3 = c.global_position - c.global_transform.basis.z * 1.0
	joueur.global_position = Vector3(devant.x, 0.1, devant.z)
	rodeur.global_position = Vector3(devant.x - 3.0, 0.0, devant.z)
	rodeur.rotation = Vector3(0.0, deg_to_rad(-90.0), 0.0)
	for i in 3:
		await get_tree().physics_frame
	controle("Devant une cachette, le joueur reste visible", rodeur.voit_joueur())

	# ---- Les cachettes marchent toujours ----
	for cachette in get_tree().get_nodes_in_group("cachettes"):
		await devant_cachette(cachette)
		controle("%s : se vise (« %s »)" % [cachette.name, jeu.message_action.text],
			jeu.message_action.text == "Se cacher")
		agir()
		await get_tree().physics_frame
		controle("%s : on y entre" % cachette.name, joueur.est_cache())
		controle("%s : cache, il est invisible" % cachette.name, not rodeur.voit_joueur())
		agir()
		await get_tree().physics_frame
		controle("%s : on en ressort" % cachette.name, not joueur.est_cache())

	# La visée des coffres et de la porte n'est plus contrôlée ici : « partie »
	# le fait bien mieux — les quatre objets, huit approches chacun, avec la
	# vraie touche d'action et jusqu'à la victoire. Ce contrôle-ci ne tentait
	# qu'une approche et ratait selon le tirage : rafistolé deux fois, retiré.
	for r in get_tree().get_nodes_in_group("rodeurs"):
		r.actif = false

	# ---- Le même filet que le bandeau rouge de l'écran ----
	var problemes: Array = jeu.get_node("Maison").audit_emplacements()
	controle("L'audit des emplacements est vide" if problemes.is_empty()
		else "L'audit des emplacements est vide (obtenu : %s)" % ", ".join(problemes),
		problemes.is_empty())

	print("=== ECHECS: %d ===" % echecs)
	get_tree().quit(1 if echecs > 0 else 0)


func pose(pos_r: Vector3, cap_deg: float, pos_j: Vector3) -> void:
	rodeur.global_position = pos_r
	rodeur.rotation = Vector3(0.0, deg_to_rad(cap_deg), 0.0)
	rodeur.en_poursuite = false
	joueur.global_position = pos_j + Vector3.UP * 0.1
	for i in 3:
		await get_tree().physics_frame


func devant_cachette(c: Node3D) -> void:
	var regard: Vector3 = -c.global_transform.basis.z
	var p: Vector3 = c.global_position + regard * 1.5
	# Le rôdeur est amené face à la cachette : sans ça, « caché, il est
	# invisible » passait pour de mauvaises raisons — il était simplement loin.
	rodeur.global_position = c.global_position + regard * 2.5
	rodeur.look_at(c.global_position + Vector3.UP * 1.0, Vector3.UP)
	rodeur.rotation = Vector3(0.0, rodeur.rotation.y, 0.0)
	rodeur.en_poursuite = false
	joueur.set_physics_process(true)
	joueur.global_position = Vector3(p.x, c.global_position.y + 0.1, p.z)
	joueur.rotation = Vector3.ZERO
	var cam: Camera3D = joueur.get_node("Camera3D")
	cam.rotation = Vector3.ZERO
	# On vise droit devant, à hauteur d'homme : plus besoin de chercher l'angle.
	cam.look_at(c.global_position + Vector3.UP * 1.3, Vector3.UP)
	for i in 5:
		await get_tree().physics_frame


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
