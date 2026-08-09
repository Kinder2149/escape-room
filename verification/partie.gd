extends Node

## Une partie GAGNÉE de bout en bout, jouée comme un joueur la jouerait.
##
## Ce que les autres sondes ne font pas : ici rien n'est forcé. On ne touche
## ni aux compteurs ni aux objets par le code — on **approche** chaque objet,
## on le **vise** avec le rayon du joueur, et on **appuie sur la touche
## d'action**. Si un coffre est mal orienté, hors d'atteinte, ou si sa zone de
## visée a bougé, la partie ne se gagne pas et la sonde le dit.
##
## Les rôdeurs sont écartés : on vérifie la chaîne, pas la traque.

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

	# ---- Tout est-il joignable À PIED depuis là où on se réveille ? ----
	var maison: Node3D = jeu.get_node("Maison")
	var depart: Vector3 = joueur.global_position
	for cible in [["premier coffre", jeu.get_node("CoffreA")],
			["second coffre", jeu.get_node("CoffreB")],
			["coffre-fort", jeu.get_node("CoffreFort")],
			["porte rouge", jeu.get_node("Sortie")]]:
		var m: float = maison.distance_de_marche(depart, cible[1].global_position)
		controle("%s joignable a pied depuis le reveil (%.1f m)" % [cible[0], m], m > 0.5)

	# ---- Les deux morceaux, en visant et en appuyant ----
	controle("au depart : « %s »" % jeu.compteur.text,
		jeu.compteur.text == "Morceaux de clé : 0 / 2")
	for nom in ["CoffreA", "CoffreB"]:
		var coffre: StaticBody3D = jeu.get_node(nom)
		controle("%s : on peut l'ouvrir (« %s »)" % [nom, jeu.message_action.text],
			await devant(coffre, 1.3, 0.25, "Ouvrir"))
		await agir_et_fouille()
		controle("%s : il propose son contenu (« %s »)" % [nom, jeu.message_action.text],
			await attendre("Prendre"))
		await agir_et_fouille()
	controle("les deux morceaux sont comptes (« %s »)" % jeu.compteur.text,
		jeu.compteur.text == "Morceaux de clé : 2 / 2")

	# ---- La porte refuse tant qu'on n'a pas le badge ----
	var porte: StaticBody3D = jeu.get_node("Sortie")
	controle("la porte se vise (« %s »)" % jeu.message_action.text,
		await devant(porte, 1.3, 1.1, "Ouvrir la porte"))
	agir()
	await get_tree().physics_frame
	controle("SANS LE BADGE la porte refuse et renvoie au coffre-fort (« %s »)"
		% jeu.message_refus.text,
		not jeu.partie_gagnee and "badge" in jeu.message_refus.text)

	# ---- Le coffre-fort, puis le badge ----
	var fort: StaticBody3D = jeu.get_node("CoffreFort")
	controle("le coffre-fort se vise (« %s »)" % jeu.message_action.text,
		await devant(fort, 1.6, 0.35, "Ouvrir"))
	await agir_et_fouille()
	controle("il s'ouvre avec les deux morceaux (« %s »)" % jeu.message_action.text,
		await attendre("Prendre"))
	await agir_et_fouille()
	controle("le badge est en poche (« %s »)" % jeu.compteur.text,
		jeu.badge and jeu.compteur.text == "Badge en poche")

	# ---- La porte, enfin ----
	controle("la porte se vise encore (« %s »)" % jeu.message_action.text,
		await devant(porte, 1.3, 1.1, "Ouvrir la porte"))
	agir()
	await get_tree().physics_frame
	controle("AVEC LE BADGE : PARTIE GAGNEE", jeu.partie_gagnee and porte.ouverte)
	controle("l'ecran affiche « Gagné »", jeu.message_gagne.visible)
	controle("le joueur est figé une fois gagné", not joueur.is_physics_processing())

	print("=== ECHECS PARTIE: %d ===" % echecs)
	get_tree().quit(1 if echecs > 0 else 0)


## Poser le joueur devant un objet et le laisser retomber AVANT de viser :
## la visée calculée en l'air part trop haut (leçon du banc principal).
##
## On ESSAIE plusieurs approches jusqu'à ce que la visée accroche : selon le
## tirage, l'endroit théorique devant un objet peut tomber dans un meuble ou
## dans un angle. Un joueur, lui, tournerait autour — la sonde fait pareil.
## Si aucune approche ne marche, l'objet est vraiment inabordable et le
## contrôle échoue, ce qui est bien le défaut qu'on veut détecter.
func devant(objet: Node3D, recul: float, hauteur_visee: float, voulu: String) -> bool:
	var c: Vector3 = objet.global_position
	var face: Vector3 = objet.global_transform.basis.z.normalized()
	var essais: Array = []
	for sens in [1.0, -1.0]:
		for distance in [recul, recul * 0.75, recul * 1.3]:
			essais.append(face * sens * distance)
	# Et par les côtés, si l'objet est coincé de face.
	var cote := objet.global_transform.basis.x.normalized()
	for sens in [1.0, -1.0]:
		essais.append(cote * sens * recul)

	var carte: RID = joueur.get_world_3d().navigation_map
	var cam: Camera3D = joueur.get_node("Camera3D")
	for ecart in essais:
		# On se pose sur du sol praticable, en gardant la distance à l'objet.
		var pose := NavigationServer3D.map_get_closest_point(carte, c + ecart)
		var vers := pose - c
		vers.y = 0.0
		if vers.length() < 0.3:
			vers = ecart
		var p: Vector3 = c + vers.normalized() * ecart.length()
		joueur.set_physics_process(true)
		joueur.global_position = Vector3(p.x, c.y + 0.1, p.z)
		joueur.rotation = Vector3.ZERO
		cam.rotation = Vector3.ZERO
		for i in 12:
			await get_tree().physics_frame
		cam.look_at(c + Vector3.UP * hauteur_visee, Vector3.UP)
		if await attendre(voulu):
			return true
	return false


## Attendre que la visée se stabilise : elle se calcule dans la physique.
func attendre(voulu: String) -> bool:
	for i in 30:
		if jeu.message_action.text == voulu:
			return true
		await get_tree().physics_frame
	return false


## La vraie touche d'action, pas un appel direct à la mécanique.
func agir() -> void:
	var e := InputEventAction.new()
	e.action = "agir"
	e.pressed = true
	joueur._unhandled_input(e)


## Comme un joueur : on appuie, puis on laisse la fouille aller à son terme —
## ouvrir un coffre ou prendre son contenu cloue le joueur un moment (jet 13).
## La sonde ne bouge pas pendant ce temps, donc la fouille n'est jamais annulée.
func agir_et_fouille() -> void:
	agir()
	while joueur.est_en_fouille():
		await get_tree().physics_frame


func controle(nom: String, condition: bool) -> void:
	if condition:
		print("OK   %s" % nom)
	else:
		echecs += 1
		print("RATE %s" % nom)
