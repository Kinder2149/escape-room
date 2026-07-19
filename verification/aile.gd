extends SceneTree

# Sonde jetable — jet 7, etape 1 : les murs de l'aile Est.
# Chaque volume neuf est praticable et joignable depuis l'ancien couloir.
# Les boucles existent : on le prouve en verifiant que les DEUX portes de la
# buanderie et de la bibliotheque debouchent sur du sol praticable.

var jeu: Node3D = null
var frames := 0
var echecs := 0

# (nom, point a tester)
const POINTS := [
	["couloir prolonge", Vector3(15.4, 0.1, 0.0)],
	["galerie nord", Vector3(21.8, 0.1, -7.5)],
	["galerie centre (jonction couloir)", Vector3(21.8, 0.1, 0.0)],
	["galerie sud", Vector3(21.8, 0.1, 7.5)],
	["salle a manger (a cote de la table)", Vector3(12.2, 0.1, -7.0)],
	["buanderie (passage est, l'etendoir occupe l'ouest)", Vector3(19.2, 0.1, -5.2)],
	["bibliotheque", Vector3(15.5, 0.1, 5.2)],
	["porte salle a manger <-> couloir", Vector3(13.9, 0.1, -1.5)],
	["porte buanderie <-> couloir", Vector3(18.4, 0.1, -1.5)],
	["porte buanderie <-> galerie (boucle 1)", Vector3(20.0, 0.1, -5.2)],
	["porte bibliotheque <-> couloir", Vector3(15.5, 0.1, 1.5)],
	["porte bibliotheque <-> galerie (boucle 2)", Vector3(20.0, 0.1, 5.2)],
]
# Points qui doivent rester DANS le mur (aucun trou vers l'exterieur, murs conserves)
const MURS := [
	["mur est exterieur", Vector3(23.5, 0.1, 0.0)],
	["mur entre salle a manger et buanderie", Vector3(16.8, 0.1, -5.2)],
	["mur entre salon et salle a manger", Vector3(11.0, 0.1, -5.2)],
	["mur entre bureau et bibliotheque", Vector3(11.0, 0.1, 5.2)],
]


func _process(_delta: float) -> bool:
	if jeu == null:
		jeu = load("res://jeu.tscn").instantiate()
		root.add_child(jeu)
		return false
	frames += 1
	if not jeu.get_node("Rodeur").visible:
		if frames > 200:
			echecs += 1
			print("RATE la maison n'est jamais prete")
			return _fin()
		return false

	var carte: RID = jeu.get_node("Joueur").get_world_3d().navigation_map
	var depart := Vector3(-7.0, 0.1, 0.0)  # ancien couloir, cote ouest

	for p in POINTS:
		var proche := NavigationServer3D.map_get_closest_point(carte, p[1])
		var praticable: bool = Vector2(proche.x, proche.z).distance_to(Vector2(p[1].x, p[1].z)) < 0.4
		var chemin := NavigationServer3D.map_get_path(carte, depart, p[1], true)
		var longueur := 0.0
		for i in range(1, chemin.size()):
			longueur += chemin[i - 1].distance_to(chemin[i])
		var bout: Vector3 = chemin[chemin.size() - 1] if chemin.size() > 0 else Vector3.INF
		var joignable: bool = Vector2(bout.x, bout.z).distance_to(Vector2(p[1].x, p[1].z)) < 0.5
		_exige("%s : praticable et joignable (%.1f m de marche)" % [p[0], longueur],
			praticable and joignable)

	for m in MURS:
		var proche := NavigationServer3D.map_get_closest_point(carte, m[1])
		var dans_le_mur: bool = Vector2(proche.x, proche.z).distance_to(Vector2(m[1].x, m[1].z)) > 0.25
		_exige("%s : bien plein" % m[0], dans_le_mur)

	return _fin()


func _fin() -> bool:
	print("=== ECHECS AILE: %d ===" % echecs)
	quit(1 if echecs > 0 else 0)
	return true


func _exige(nom: String, condition: bool) -> void:
	if condition:
		print("OK   %s" % nom)
	else:
		echecs += 1
		print("RATE %s" % nom)
