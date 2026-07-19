extends SceneTree

# Sonde jetable : le joueur glisse-t-il apres avoir ete pose sur un repere ?
# Points de reveil codes en dur (identiques jet 5 / etape 1). 20 essais.


var jeu: Node3D = null
var frames := 0
var essais := 0
var glissements := 0


func _process(_delta: float) -> bool:
	if jeu == null:
		jeu = load("res://jeu.tscn").instantiate()
		root.add_child(jeu)
		frames = 0
		return false
	frames += 1
	if frames < 5:
		return false
	var pos: Vector3 = jeu.get_node("Joueur").global_position
	var piece := "(aucune)"
	var ecart := 999.0
	# Les reperes sont lus dans l'arbre, en 3D : une liste recopiee oubliait
	# les pieces de l'etage, et chaque reveil en haut passait pour un glissement.
	for p in get_nodes_in_group("pieces"):
		var m: Vector3 = p.get_node("Reveil").global_position
		var d: float = Vector2(pos.x, pos.z).distance_to(Vector2(m.x, m.z)) 			+ absf(pos.y - m.y)
		if d < ecart:
			ecart = d
			piece = String(p.name)
	if ecart > 0.1:
		glissements += 1
		print("GLISSEMENT essai %d : joueur a %.2f m du reveil %s (pos %v)" %
			[essais + 1, ecart, piece, pos])
	else:
		print("ok essai %d : joueur pile sur %s" % [essais + 1, piece])
	jeu.queue_free()
	jeu = null
	essais += 1
	if essais >= 20:
		print("=== GLISSEMENTS: %d / 20 ===" % glissements)
		quit(0)
		return true
	return false
