extends SceneTree

# Sonde jetable — jet 8, etape 2 : les murs de l'etage.
# Chaque piece et chaque passage praticable ET joignable a pied depuis le RDC.
# La boucle verticale : les deux escaliers relient bien les deux niveaux.
# Le sud de l'etage doit rester PLEIN (l'etage est plus petit que le RDC).

var jeu: Node3D = null
var frames := 0
var echecs := 0
const RDC := Vector3(-7.0, 0.1, 0.0)

const LIEUX := [
	["salle d'eau (etage)", Vector3(-7.5, 3.3, -5.2)],
	["chambre d'amis (etage)", Vector3(-0.7, 3.3, -5.2)],
	["chambre de maitre (etage)", Vector3(6.8, 3.3, -5.2)],
	["dressing (etage)", Vector3(14.0, 3.3, -5.2)],
	["couloir etage ouest", Vector3(-8.0, 3.3, 0.0)],
	["couloir etage centre", Vector3(3.0, 3.3, 0.0)],
	["couloir etage est", Vector3(17.0, 3.3, 0.0)],
	["palier est (etage)", Vector3(21.7, 3.3, 1.0)],
	["porte entre les deux chambres", Vector3(2.7, 3.3, -5.2)],
	["bas cage ouest", Vector3(-12.9, 0.1, -8.3)],
	["haut cage ouest", Vector3(-12.9, 3.3, 0.7)],
	["bas cage est", Vector3(25.3, 0.1, -8.0)],
	["haut cage est", Vector3(25.3, 3.3, 1.75)],
]
# Doivent rester PLEINS : le sud de l'etage, et la dalle entre les niveaux.
const PLEINS := [
	["sud de l'etage (chambre RDC dessous)", Vector3(-7.5, 3.3, 5.2)],
	["sud de l'etage (bureau RDC dessous)", Vector3(6.8, 3.3, 5.2)],
	["sud de l'etage (bibliotheque dessous)", Vector3(15.5, 3.3, 5.2)],
	["au-dessus de la buanderie (hors etage)", Vector3(18.4, 3.3, -5.2)],
]


func _process(_delta: float) -> bool:
	if jeu == null:
		jeu = load("res://jeu.tscn").instantiate()
		root.add_child(jeu)
		return false
	if not jeu.get_node("Rodeur").visible:
		frames += 1
		if frames > 400:
			_exige("la maison devient prete", false)
			return _fin()
		return false

	var maison: Node3D = jeu.get_node("Maison")
	var carte: RID = maison.get_node("Navigation").get_navigation_map()

	for l in LIEUX:
		_praticable_et_joignable(maison, carte, l[0], l[1])
	for p in PLEINS:
		_plein(carte, p[0], p[1])

	# La boucle verticale : depuis le haut d'un escalier, on doit pouvoir
	# rejoindre le bas de l'AUTRE — sinon l'etage est un cul-de-sac.
	_chemin(maison, "boucle : haut cage EST -> bas cage OUEST",
		Vector3(25.3, 3.3, 1.75), Vector3(-12.9, 0.1, -8.3))
	_chemin(maison, "boucle : haut cage OUEST -> bas cage EST",
		Vector3(-12.9, 3.3, 0.7), Vector3(25.3, 0.1, -8.0))
	return _fin()


func _praticable_et_joignable(maison: Node3D, carte: RID, nom: String, point: Vector3) -> void:
	var proche := NavigationServer3D.map_get_closest_point(carte, point)
	var plan := Vector2(proche.x, proche.z).distance_to(Vector2(point.x, point.z))
	var haut: float = absf(proche.y - point.y)
	if plan > 0.6 or haut > 0.6:
		_exige("%s : praticable (ecart %.2f / %.2f)" % [nom, plan, haut], false)
		return
	_chemin(maison, nom, RDC, point)


func _chemin(maison: Node3D, nom: String, depuis: Vector3, vers: Vector3) -> void:
	var carte: RID = maison.get_node("Navigation").get_navigation_map()
	var chemin := NavigationServer3D.map_get_path(carte, depuis, vers, true)
	var arrive := false
	if chemin.size() > 0:
		var bout: Vector3 = chemin[chemin.size() - 1]
		arrive = Vector2(bout.x, bout.z).distance_to(Vector2(vers.x, vers.z)) < 0.9 \
			and absf(bout.y - vers.y) < 0.9
	var m: float = maison.distance_de_marche(depuis, vers)
	_exige("%s : joignable a pied (%.1f m)" % [nom, m], arrive)


## En 3D : au sol, le plancher du RDC est juste dessous et passerait pour du
## sol « au meme endroit ». C'est la distance reelle qui compte.
func _plein(carte: RID, nom: String, point: Vector3) -> void:
	var proche := NavigationServer3D.map_get_closest_point(carte, point)
	var d: float = proche.distance_to(point)
	_exige("%s : bien plein (rien de marchable a %.2f m en 3D)" % [nom, d], d > 0.6)


func _fin() -> bool:
	print("=== ECHECS ETAGE: %d ===" % echecs)
	quit(1 if echecs > 0 else 0)
	return true


func _exige(nom: String, condition: bool) -> void:
	if condition:
		print("OK   %s" % nom)
	else:
		echecs += 1
		print("RATE %s" % nom)
