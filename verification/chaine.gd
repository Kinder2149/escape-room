extends SceneTree

# Sonde jetable — jet 9, etape 2 : la chaine complete.
# 2 morceaux -> coffre-fort -> badge -> porte rouge.
# Le piege a verifier : avec les deux morceaux mais SANS badge, la porte doit
# refuser. C'est tout le sens du jet ; si elle s'ouvrait, le coffre-fort ne
# servirait a rien.

var jeu: Node3D = null
var frames := 0
var echecs := 0


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
	if frames < 3:
		return false

	for r in liste:
		r.actif = false
		r.joueur_attrape.disconnect(jeu._on_joueur_attrape)
	var fort: StaticBody3D = jeu.get_node("CoffreFort")
	var porte: StaticBody3D = jeu.get_node("Sortie")

	# --- Depart : rien en poche ---
	_exige("l'affichage compte les morceaux (« %s »)" % jeu.compteur.text,
		jeu.compteur.text == "Morceaux de clé : 0 / 2")
	porte.agir()
	_exige("porte a mains nues : elle refuse", not jeu.partie_gagnee)
	_exige("et elle nomme le coffre-fort (« %s »)" % jeu.message_refus.text,
		"badge" in jeu.message_refus.text and "coffre-fort" in jeu.message_refus.text)

	# --- LE PIEGE : les deux morceaux, mais pas le badge ---
	jeu.get_node("CoffreA").agir()
	jeu.get_node("CoffreA").agir()
	jeu.get_node("CoffreB").agir()
	jeu.get_node("CoffreB").agir()
	_exige("les deux morceaux sont comptes (« %s »)" % jeu.compteur.text,
		jeu.compteur.text == "Morceaux de clé : 2 / 2")
	porte.agir()
	_exige("LES DEUX MORCEAUX NE SUFFISENT PLUS : la porte refuse",
		not jeu.partie_gagnee and not porte.ouverte)

	# --- Le coffre-fort, puis le badge ---
	fort.agir()
	_exige("le coffre-fort s'ouvre avec les deux morceaux", fort.ouvert)
	_exige("il propose son contenu (« %s »)" % fort.texte_action(),
		fort.texte_action() == "Prendre")
	fort.agir()
	_exige("le badge est en poche (« %s »)" % jeu.compteur.text,
		jeu.badge and jeu.compteur.text == "Badge en poche")
	_exige("le coffre-fort est vide (« %s »)" % fort.texte_action(),
		fort.texte_action() == "")

	# --- La porte, enfin ---
	porte.agir()
	_exige("AVEC LE BADGE : la porte s'ouvre et la partie est GAGNEE",
		jeu.partie_gagnee and porte.ouverte)
	_exige("le message « Gagné » est affiche", jeu.message_gagne.visible)

	print("=== ECHECS CHAINE: %d ===" % echecs)
	quit(1 if echecs > 0 else 0)
	return true


func _exige(nom: String, condition: bool) -> void:
	if condition:
		print("OK   %s" % nom)
	else:
		echecs += 1
		print("RATE %s" % nom)
