extends Node

## La partie PERDUE — l'autre moitié du jeu, jamais vérifiée.
## Attrapé, le joueur doit être figé, l'écran doit le dire, et les deux
## rôdeurs doivent s'arrêter net.
##
## Limite assumée : la remise à zéro elle-même (le rechargement de la scène)
## ne peut pas être vérifiée ici. Une sonde instancie le jeu à la main, elle
## n'est pas la scène principale — recharger n'aurait aucun sens. Ce dernier
## maillon reste au test manuel de Kinder.

var jeu: Node3D
var echecs := 0


func _ready() -> void:
	jeu = load("res://jeu.tscn").instantiate()
	add_child(jeu)
	await jeu.get_node("Maison").navigation_prete
	for i in 20:
		await get_tree().physics_frame
	var joueur: CharacterBody3D = jeu.get_node("Joueur")
	var rodeurs := get_tree().get_nodes_in_group("rodeurs")

	controle("avant : la partie n'est ni gagnée ni perdue",
		not jeu.partie_perdue and not jeu.partie_gagnee)
	controle("avant : le joueur se déplace", joueur.is_physics_processing())
	controle("avant : les deux rôdeurs sont actifs",
		rodeurs[0].actif and rodeurs[1].actif)

	# Un rôdeur touche le joueur : on déclenche sa capture comme le jeu le fait.
	rodeurs[0].joueur_attrape.emit()
	await get_tree().physics_frame

	controle("attrapé : la partie est perdue", jeu.partie_perdue)
	controle("attrapé : l'écran affiche « Attrapé »", jeu.message_perdu.visible)
	controle("attrapé : le joueur est figé", not joueur.is_physics_processing())
	controle("attrapé : il ne répond plus aux touches",
		not joueur.is_processing_unhandled_input())
	controle("attrapé : les DEUX rôdeurs s'arrêtent",
		not rodeurs[0].actif and not rodeurs[1].actif)
	controle("attrapé : plus aucun texte d'action à l'écran",
		jeu.message_action.text == "")

	# Une seconde capture ne doit rien relancer.
	var etat: bool = jeu.partie_perdue
	rodeurs[1].joueur_attrape.emit()
	await get_tree().physics_frame
	controle("une seconde capture ne change rien", jeu.partie_perdue == etat
		and not jeu.partie_gagnee)

	print("=== ECHECS DEFAITE: %d ===" % echecs)
	get_tree().quit(1 if echecs > 0 else 0)


func controle(nom: String, condition: bool) -> void:
	if condition:
		print("OK   %s" % nom)
	else:
		echecs += 1
		print("RATE %s" % nom)
