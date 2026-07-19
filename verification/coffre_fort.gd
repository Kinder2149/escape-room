extends SceneTree

# Sonde jetable — jet 9, etape 1 : le coffre-fort verrouille.
# A) Il refuse tant que les deux morceaux ne sont pas reunis, et DIT ce qui manque.
# B) Le message se met a jour quand il n'en manque plus qu'un.
# C) Avec les deux, il s'ouvre.
# D) 20 tirages : quatre pieces distinctes (sortie + 2 coffres + coffre-fort),
#    et toujours au moins un des TROIS objets a l'etage.

var jeu: Node3D = null
var frames := 0
var essais := 0
var echecs := 0
var phase := "mecanique"
var repartitions := {}


func _process(_delta: float) -> bool:
	if jeu == null:
		jeu = load("res://jeu.tscn").instantiate()
		root.add_child(jeu)
		frames = 0
		return false
	var liste := get_nodes_in_group("rodeurs")
	if liste.is_empty() or not liste[0].visible:
		frames += 1
		if frames > 400:
			_exige("la maison devient prete", false)
			return _fin()
		return false
	frames += 1
	if frames < 3:
		return false

	var fort: StaticBody3D = jeu.get_node("CoffreFort")

	if phase == "mecanique":
		for r in liste:
			r.actif = false
			r.joueur_attrape.disconnect(jeu._on_joueur_attrape)

		fort.agir()
		_exige("A) verrouille, il refuse (encore ferme)", not fort.ouvert)
		_exige("A) et il dit ce qui manque : « %s »" % jeu.message_refus.text,
			"2 morceaux de clé" in jeu.message_refus.text)

		jeu._on_morceau_pris()
		fort.agir()
		_exige("B) un morceau : il refuse encore", not fort.ouvert)
		_exige("B) et le compte a suivi : « %s »" % jeu.message_refus.text,
			"1 morceau de clé" in jeu.message_refus.text)

		jeu._on_morceau_pris()
		fort.agir()
		_exige("C) les deux morceaux : il s'ouvre", fort.ouvert)
		_exige("C) il propose alors son contenu (« %s »)" % fort.texte_action(),
			fort.texte_action() == "Prendre")
		phase = "tirages"
		jeu.queue_free()
		jeu = null
		return false

	var ps := _piece_de(jeu.get_node("Sortie").global_position, "Sortie")
	var pa := _piece_de(jeu.get_node("CoffreA").global_position, "Coffre")
	var pb := _piece_de(jeu.get_node("CoffreB").global_position, "Coffre")
	var pf := _piece_de(fort.global_position, "Coffre")
	_exige("D) tirage %d : tout est pose (%s / %s / %s / %s)" % [essais + 1, ps, pa, pb, pf],
		"(aucune)" not in [ps, pa, pb, pf])
	_exige("D) tirage %d : quatre pieces DISTINCTES" % [essais + 1],
		[ps, pa, pb, pf].size() == 4 and _tous_differents([ps, pa, pb, pf]))
	var en_haut := int(_en_haut(pa)) + int(_en_haut(pb)) + int(_en_haut(pf))
	_exige("D) tirage %d : au moins un des trois objets a l'etage" % [essais + 1], en_haut >= 1)
	if _en_haut(pf):
		repartitions["fort_en_haut"] = repartitions.get("fort_en_haut", 0) + 1

	jeu.queue_free()
	jeu = null
	essais += 1
	if essais >= 20:
		print("   (coffre-fort a l'etage : %d fois sur 20)" % repartitions.get("fort_en_haut", 0))
		return _fin()
	return false


func _tous_differents(noms: Array) -> bool:
	var vus := {}
	for n in noms:
		if vus.has(n):
			return false
		vus[n] = true
	return true


func _en_haut(nom: String) -> bool:
	for piece in get_nodes_in_group("pieces"):
		if String(piece.name) == nom:
			return piece.get_node("Reveil").global_position.y >= 1.0
	return false


func _piece_de(pos: Vector3, repere: String) -> String:
	for piece in get_nodes_in_group("pieces"):
		var m: Vector3 = piece.get_node(repere).global_position
		if Vector2(pos.x, pos.z).distance_to(Vector2(m.x, m.z)) < 0.35 \
				and absf(pos.y - m.y) < 1.5:
			return String(piece.name)
	return "(aucune)"


func _fin() -> bool:
	print("=== ECHECS COFFRE-FORT: %d ===" % echecs)
	quit(1 if echecs > 0 else 0)
	return true


func _exige(nom: String, condition: bool) -> void:
	if not condition:
		echecs += 1
		print("RATE %s" % nom)
	elif not nom.begins_with("D) tirage"):
		print("OK   %s" % nom)
