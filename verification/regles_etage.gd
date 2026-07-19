extends SceneTree

# Sonde jetable — jet 8, etape 3 : les deux regles qui donnent son sens a l'etage.
# 30 tirages. Attendu a CHAQUE fois :
#  - la porte rouge est de plain-pied (jamais a l'etage) ;
#  - au moins un coffre est a l'etage ;
#  - tout est pose sur un repere, sortie et coffres dans 3 pieces differentes ;
#  - le reveil peut monter (on verifie que ca arrive au moins une fois).

var jeu: Node3D = null
var frames := 0
var essais := 0
var echecs := 0
var reveils_en_haut := 0
var coffres_en_haut_total := 0
var sorties := {}


func _process(_delta: float) -> bool:
	if jeu == null:
		jeu = load("res://jeu.tscn").instantiate()
		root.add_child(jeu)
		frames = 0
		return false
	if not jeu.get_node("Rodeur").visible:
		frames += 1
		if frames > 400:
			_exige("la maison devient prete", false)
			return _fin()
		return false
	frames += 1
	if frames < 3:
		return false

	var piece_sortie := _piece_de(jeu.get_node("Sortie").global_position, "Sortie")
	var pa := _piece_de(jeu.get_node("CoffreA").global_position, "Coffre")
	var pb := _piece_de(jeu.get_node("CoffreB").global_position, "Coffre")
	var pf := _piece_de(jeu.get_node("CoffreFort").global_position, "Coffre")
	var pr := _piece_de(jeu.get_node("Joueur").global_position, "Reveil")

	_exige("tirage %d : tout est pose sur un repere (sortie=%s A=%s B=%s reveil=%s)"
		% [essais + 1, piece_sortie, pa, pb, pr],
		"(aucune)" not in [piece_sortie, pa, pb, pf, pr])
	_exige("tirage %d : sortie et les TROIS objets dans 4 pieces differentes" % [essais + 1],
		{piece_sortie: 0, pa: 0, pb: 0, pf: 0}.size() == 4)
	_exige("tirage %d : LA PORTE ROUGE EST DE PLAIN-PIED (%s)" % [essais + 1, piece_sortie],
		_en_haut(piece_sortie) == false)
	# La regle porte sur les TROIS objets a chercher depuis le jet 9, pas deux.
	var n_haut := int(_en_haut(pa)) + int(_en_haut(pb)) + int(_en_haut(pf))
	_exige("tirage %d : AU MOINS UN DES TROIS OBJETS A L'ETAGE (%s / %s / %s)"
		% [essais + 1, pa, pb, pf], n_haut >= 1)
	coffres_en_haut_total += n_haut
	if _en_haut(pr):
		reveils_en_haut += 1
	sorties[piece_sortie] = true

	jeu.queue_free()
	jeu = null
	essais += 1
	if essais >= 30:
		_exige("le joueur se reveille parfois a l'etage (%d fois sur 30)" % reveils_en_haut,
			reveils_en_haut > 0)
		_exige("la sortie varie bien (%d pieces differentes sur 30)" % sorties.size(),
			sorties.size() >= 5)
		print("   (coffres a l'etage : %.2f par partie en moyenne)"
			% (float(coffres_en_haut_total) / essais))
		return _fin()
	return false


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
	print("=== ECHECS REGLES: %d ===" % echecs)
	quit(1 if echecs > 0 else 0)
	return true


func _exige(nom: String, condition: bool) -> void:
	if not condition:
		echecs += 1
		print("RATE %s" % nom)
