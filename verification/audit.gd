extends SceneTree

# Sonde jetable — etape 3 : l'audit des emplacements.
# 1. Maison saine : audit vide, bandeau cache.
# 2. Sabotages : coffre dans un mur, reveil dans un meuble, porte rouge au
#    milieu de la piece -> l'audit doit nommer chaque probleme.
# 3. Reparation : audit vide a nouveau.
# 4. Cablage du bandeau : nouvelle partie sabotee des le chargement -> le
#    bandeau doit etre VISIBLE a l'ecran.

var jeu: Node3D = null
var frames := 0
var echecs := 0
var phase := 1
var sabote := false


func _process(_delta: float) -> bool:
	if jeu == null:
		jeu = load("res://jeu.tscn").instantiate()
		root.add_child(jeu)
		frames = 0
		sabote = false
		return false
	frames += 1
	if phase == 4 and not sabote and frames == 1:
		# Saboter AVANT que la maison soit prete : le bandeau doit s'allumer
		# tout seul au demarrage, sans que personne n'appelle l'audit.
		_deplace("Cuisine", "Coffre", Vector3(-2.5, 0.0, -8.9))
		sabote = true
	if not jeu.get_node("Rodeur").visible:
		if frames > 200:
			_exige("la maison devient prete", false)
			return _fin()
		return false
	if frames < 45:
		return false

	match phase:
		1:
			var problemes: Array = jeu.get_node("Maison").audit_emplacements()
			_exige("maison saine : audit vide (obtenu : %s)" % [problemes], problemes.is_empty())
			_exige("maison saine : bandeau cache",
				not jeu.get_node("Interface/MessageAudit").visible)
			phase = 2
			_suivant()
		2:
			_deplace("Cuisine", "Coffre", Vector3(-2.5, 0.0, -8.9))      # dans le mur nord
			_deplace("Chambre", "Reveil", Vector3(-4.5, 0.0, 6.0))       # dans l'armoire
			_deplace("Bureau", "Sortie", Vector3(7.0, 0.0, 5.0))         # en pleine piece
			var problemes: Array = jeu.get_node("Maison").audit_emplacements()
			print("   problemes remontes :")
			for p in problemes:
				print("     - %s" % p)
			_exige("sabotage : au moins 3 problemes", problemes.size() >= 3)
			_exige("le coffre de la Cuisine est nomme", _cite(problemes, "Cuisine", "coffre"))
			_exige("le reveil de la Chambre est nomme", _cite(problemes, "Chambre", "reveil"))
			_exige("la porte rouge du Bureau est nommee", _cite(problemes, "Bureau", "porte rouge"))
			_deplace("Cuisine", "Coffre", Vector3(-2.5, 0.0, -7.5))
			_deplace("Chambre", "Reveil", Vector3(-6.0, 0.0, 4.0))
			_deplace("Bureau", "Sortie", Vector3(6.8, 0.0, 8.75))
			phase = 3
			return false
		3:
			var problemes: Array = jeu.get_node("Maison").audit_emplacements()
			_exige("apres reparation : audit vide (obtenu : %s)" % [problemes], problemes.is_empty())
			phase = 4
			_suivant()
		4:
			_exige("partie sabotee : le bandeau est VISIBLE a l'ecran",
				jeu.get_node("Interface/MessageAudit").visible)
			print("   bandeau : %s" % jeu.get_node("Interface/MessageAudit").text.replace("\n", " | "))
			return _fin()
	return false


func _deplace(piece: String, repere: String, ou: Vector3) -> void:
	jeu.get_node("Maison/%s/%s" % [piece, repere]).global_position = ou


func _cite(problemes: Array, piece: String, quoi: String) -> bool:
	for p in problemes:
		if piece in p and quoi in p:
			return true
	return false


func _suivant() -> void:
	jeu.queue_free()
	jeu = null


func _fin() -> bool:
	print("=== ECHECS AUDIT: %d ===" % echecs)
	quit(1 if echecs > 0 else 0)
	return true


func _exige(nom: String, condition: bool) -> void:
	if condition:
		print("OK   %s" % nom)
	else:
		echecs += 1
		print("RATE %s" % nom)
