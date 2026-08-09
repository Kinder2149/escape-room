extends Node3D

# LE QUARTIER DE JEUX (zone cube, à part du manoir).
# Un cube creux, 6 faces vues de l'intérieur, gravité par face (basculement dans
# joueur_cube). On y arrive depuis le manoir par la porte-portail, dans un COULOIR
# d'entrée. Le couloir rejoint le cube par une porte dans la face nord (avec un
# garde-fou contre le trou côté intérieur).
#
# Étape C : cube agrandi (arête 40). Chaque face porte de VRAIES PIÈCES CLOSES
# (4 murs + une porte), SANS PLAFOND (on voit à travers le vide central), et
# CHAQUE FACE A UN AGENCEMENT DIFFÉRENT. Une bordure libre au bord de chaque face
# permet de basculer.

const JoueurCube := preload("res://joueur_cube.tscn")
const Portail := preload("res://portail.tscn")

const COTE: float = 40.0
const EPAISSEUR: float = 0.5
const DEMI: float = COTE / 2.0

# La porte du cube vers le couloir (face nord, au ras du sol).
const PORTE_DEMI_LARGEUR: float = 2.5
const PORTE_HAUTEUR: float = 4.0

# Les pièces posées sur chaque face.
const MARGE_BORD: float = 5.0                   # bordure libre au bord (pour basculer)
const PORTE_PIECE: float = 4.0                  # largeur des portes des pièces
const H_MUR: float = 5.0                        # hauteur des murs (sans plafond)

# Sol teinté par face — sourd et sombre (repère d'orientation, jamais criard).
var _faces := [
	{ "pos": Vector3(0, -DEMI, 0), "size": Vector3(COTE, EPAISSEUR, COTE), "normale": Vector3.UP,    "couleur": Color(0.34, 0.29, 0.23) },
	{ "pos": Vector3(0,  DEMI, 0), "size": Vector3(COTE, EPAISSEUR, COTE), "normale": Vector3.DOWN,  "couleur": Color(0.28, 0.25, 0.31) },
	{ "pos": Vector3(0, 0, -DEMI), "size": Vector3(COTE, COTE, EPAISSEUR), "normale": Vector3.BACK,  "couleur": Color(0.25, 0.31, 0.26) },
	{ "pos": Vector3(0, 0,  DEMI), "size": Vector3(COTE, COTE, EPAISSEUR), "normale": Vector3.FORWARD,"couleur": Color(0.35, 0.29, 0.21) },
	{ "pos": Vector3(-DEMI, 0, 0), "size": Vector3(EPAISSEUR, COTE, COTE), "normale": Vector3.RIGHT, "couleur": Color(0.29, 0.25, 0.33) },
	{ "pos": Vector3( DEMI, 0, 0), "size": Vector3(EPAISSEUR, COTE, COTE), "normale": Vector3.LEFT,  "couleur": Color(0.24, 0.29, 0.33) },
]

# Les murs de pièce : pierre sombre, la même partout (comme le manoir) — c'est le
# SOL qui porte la couleur, pas les murs.
const COULEUR_MUR := Color(0.20, 0.185, 0.17)

func _ready() -> void:
	_construire_eclairage()
	_construire_cube()
	_construire_couloir()
	_placer_joueur()

func _construire_eclairage() -> void:
	# Lampe centrale chaude, AVEC OMBRES : c'est ce qui donne du relief aux pièces
	# et aux meubles (sinon tout est plat = jouet).
	var lampe := OmniLight3D.new()
	lampe.omni_range = 85.0
	lampe.light_energy = 8.0
	lampe.light_color = Color(1.0, 0.9, 0.78)
	lampe.shadow_enabled = true
	add_child(lampe)
	var monde := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.04, 0.035, 0.045)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.42, 0.41, 0.44)
	env.ambient_light_energy = 0.5
	monde.environment = env
	add_child(monde)

func _boite(taille: Vector3, position: Vector3, couleur: Color) -> void:
	var corps := StaticBody3D.new()
	corps.position = position
	var visuel := MeshInstance3D.new()
	var fv := BoxMesh.new()
	fv.size = taille
	var mat := StandardMaterial3D.new()
	mat.albedo_color = couleur
	mat.roughness = 0.95           # mat, pas plastique — comme le manoir
	fv.material = mat
	visuel.mesh = fv
	corps.add_child(visuel)
	var col := CollisionShape3D.new()
	var forme := BoxShape3D.new()
	forme.size = taille
	col.shape = forme
	corps.add_child(col)
	add_child(corps)

func _construire_cube() -> void:
	for i in _faces.size():
		var f: Dictionary = _faces[i]
		if is_equal_approx((f["pos"] as Vector3).z, -DEMI):
			_construire_face_nord(f["couleur"])
		else:
			_boite(f["size"], f["pos"], f["couleur"])
		_layout_face(f, i)

# La face nord, percée d'une porte au ras du sol (vers le couloir), avec un
# garde-fou côté intérieur pour ne pas tomber dans le trou quand on marche dessus.
func _construire_face_nord(couleur: Color) -> void:
	var z := -DEMI
	var reste := DEMI - PORTE_DEMI_LARGEUR
	var cx := PORTE_DEMI_LARGEUR + reste / 2.0
	_boite(Vector3(reste, COTE, EPAISSEUR), Vector3(-cx, 0, z), couleur)
	_boite(Vector3(reste, COTE, EPAISSEUR), Vector3( cx, 0, z), couleur)
	var y_haut := -DEMI + PORTE_HAUTEUR
	var haut_pan := DEMI - y_haut
	_boite(Vector3(PORTE_DEMI_LARGEUR * 2.0, haut_pan, EPAISSEUR),
		Vector3(0, y_haut + haut_pan / 2.0, z), couleur)
	# Garde-fou : un muret en haut de la porte, côté intérieur, qui bloque le
	# joueur AVANT le trou quand il marche sur cette face. Passe au-dessus de la
	# tête du joueur qui sort par la porte (il n'y touche pas).
	_boite(Vector3(PORTE_DEMI_LARGEUR * 2.0, EPAISSEUR, 1.6),
		Vector3(0, y_haut, z + 0.8 + EPAISSEUR / 2.0), couleur.darkened(0.2))

# ---- Les pièces par face -----------------------------------------------------

func _tu_tv(normale: Vector3) -> Array:
	var tu: Vector3 = Vector3.RIGHT if absf(normale.dot(Vector3.RIGHT)) < 0.5 else Vector3.UP
	var tv: Vector3 = normale.cross(tu).normalized()
	return [tu, tv]

# Un mur posé sur une face, à la position locale (cu, cv), d'extents locaux
# (lu le long de tu, lv le long de tv), de hauteur H_MUR.
func _mur_local(f: Dictionary, cu: float, cv: float, lu: float, lv: float) -> void:
	var pos: Vector3 = f["pos"]
	var normale: Vector3 = f["normale"]
	var t := _tu_tv(normale)
	var tu: Vector3 = t[0]
	var tv: Vector3 = t[1]
	var taille: Vector3 = tu.abs() * lu + tv.abs() * lv + normale.abs() * H_MUR
	var position: Vector3 = pos + normale * (EPAISSEUR / 2.0 + H_MUR / 2.0) + tu * cu + tv * cv
	_boite(taille, position, COULEUR_MUR)

# Un meuble posé sur une face : comme un mur, mais d'une hauteur libre (bas) et
# d'une couleur propre. Il a une collision (on le contourne, comme au manoir).
func _meuble(f: Dictionary, cu: float, cv: float, lu: float, lv: float, haut: float, couleur: Color) -> void:
	_bloc_face(f, cu, cv, lu, lv, 0.0, haut, couleur)

# Une brique de meuble : un bloc posé sur la face, entre y_bas et y_bas+haut
# au-dessus du sol. C'est avec ça qu'on compose de vrais meubles (creux dessous).
func _bloc_face(f: Dictionary, cu: float, cv: float, lu: float, lv: float, y_bas: float, haut: float, couleur: Color) -> void:
	var pos: Vector3 = f["pos"]
	var normale: Vector3 = f["normale"]
	var t := _tu_tv(normale)
	var tu: Vector3 = t[0]
	var tv: Vector3 = t[1]
	var taille: Vector3 = tu.abs() * lu + tv.abs() * lv + normale.abs() * haut
	var position: Vector3 = pos + normale * (EPAISSEUR / 2.0 + y_bas + haut / 2.0) + tu * cu + tv * cv
	_boite(taille, position, couleur)

# ---- Meubles composites (à la manière du manoir) -----------------------------

# Une table : plateau sur 4 pieds (creux dessous).
func _table(f: Dictionary, cu: float, cv: float, larg: float, prof: float, couleur: Color) -> void:
	_bloc_face(f, cu, cv, larg, prof, 0.66, 0.07, couleur)
	var du := larg / 2.0 - 0.12
	var dv := prof / 2.0 - 0.12
	for su in [-1.0, 1.0]:
		for sv in [-1.0, 1.0]:
			_bloc_face(f, cu + su * du, cv + sv * dv, 0.12, 0.12, 0.0, 0.66, couleur)

# Un canapé : socle + assise + dossier (côté +v) + deux accoudoirs.
func _canape(f: Dictionary, cu: float, cv: float, larg: float, couleur: Color) -> void:
	_bloc_face(f, cu, cv, larg, 0.95, 0.0, 0.16, couleur)                     # socle
	_bloc_face(f, cu, cv - 0.05, larg - 0.4, 0.7, 0.16, 0.18, couleur)        # assise
	_bloc_face(f, cu, cv + 0.4, larg, 0.2, 0.16, 0.55, couleur)              # dossier
	_bloc_face(f, cu - larg / 2.0 + 0.12, cv, 0.24, 0.95, 0.16, 0.34, couleur) # accoudoir g
	_bloc_face(f, cu + larg / 2.0 - 0.12, cv, 0.24, 0.95, 0.16, 0.34, couleur) # accoudoir d

# Une étagère : deux montants + quatre tablettes.
func _etagere(f: Dictionary, cu: float, cv: float, larg: float, couleur: Color) -> void:
	_bloc_face(f, cu - larg / 2.0 + 0.06, cv, 0.1, 0.42, 0.0, 1.9, couleur)
	_bloc_face(f, cu + larg / 2.0 - 0.06, cv, 0.1, 0.42, 0.0, 1.9, couleur)
	for y in [0.35, 0.85, 1.35, 1.8]:
		_bloc_face(f, cu, cv, larg, 0.42, y, 0.05, couleur)

# Un lavabo : vasque sur pied.
func _lavabo(f: Dictionary, cu: float, cv: float, couleur: Color) -> void:
	_bloc_face(f, cu, cv, 0.7, 0.5, 0.72, 0.22, couleur)
	_bloc_face(f, cu, cv, 0.26, 0.26, 0.0, 0.72, couleur)

# Un côté de pièce (mur long de "longueur" le long de l'axe "u" ou "v"), avec ou
# sans porte (un trou PORTE_PIECE au milieu).
func _cote(f: Dictionary, cu: float, cv: float, longueur: float, axe: String, porte: bool) -> void:
	# Côté trop court pour caser un mur + une porte : on le laisse entièrement
	# ouvert (une alcôve), plutôt qu'un mur de taille négative.
	if porte and longueur <= PORTE_PIECE + 0.3:
		return
	if not porte:
		if axe == "u":
			_mur_local(f, cu, cv, longueur, EPAISSEUR)
		else:
			_mur_local(f, cu, cv, EPAISSEUR, longueur)
		return
	var off := (longueur + PORTE_PIECE) / 4.0
	var sl := (longueur - PORTE_PIECE) / 2.0
	if axe == "u":
		_mur_local(f, cu - off, cv, sl, EPAISSEUR)
		_mur_local(f, cu + off, cv, sl, EPAISSEUR)
	else:
		_mur_local(f, cu, cv - off, EPAISSEUR, sl)
		_mur_local(f, cu, cv + off, EPAISSEUR, sl)

# Une pièce close : 4 murs autour du rectangle centré (cu,cv), demi-extents
# (du,dv), avec une porte sur un côté ("bas"/"haut"/"gauche"/"droite").
func _piece(f: Dictionary, cu: float, cv: float, du: float, dv: float, portes: Array, sautes: Array = []) -> void:
	# portes : côtés avec une porte. sautes : côtés SANS mur du tout (le voisin
	# le bâtit — évite les murs en double sur une cloison partagée).
	if not "bas" in sautes:
		_cote(f, cu, cv - dv, du * 2.0, "u", "bas" in portes)
	if not "haut" in sautes:
		_cote(f, cu, cv + dv, du * 2.0, "u", "haut" in portes)
	if not "gauche" in sautes:
		_cote(f, cu - du, cv, dv * 2.0, "v", "gauche" in portes)
	if not "droite" in sautes:
		_cote(f, cu + du, cv, dv * 2.0, "v", "droite" in portes)

# L'agencement propre à chaque face (index 0..5) : bas, haut, nord, sud, ouest, est.
func _layout_face(f: Dictionary, idx: int) -> void:
	match idx:
		0:  # l'AILE ENTRÉE (arrivée), dense et meublée
			_aile_entree(f)
		1:  # deux pièces empilées
			_piece(f, 0, -7, 12, 6, ["bas"])
			_piece(f, 0, 7, 12, 6, ["haut"])
		2:  # deux pièces (décalées vers l'intérieur, loin de la porte du couloir)
			_piece(f, -7, 4, 6, 9, ["gauche"])
			_piece(f, 7, 4, 6, 9, ["droite"])
		3:  # quatre petites pièces (quadrants)
			_piece(f, -7, -7, 6, 6, ["gauche"])
			_piece(f, 7, -7, 6, 6, ["droite"])
			_piece(f, -7, 7, 6, 6, ["gauche"])
			_piece(f, 7, 7, 6, 6, ["droite"])
		4:  # trois pièces en enfilade
			_piece(f, -9, 0, 4, 12, ["gauche"])
			_piece(f, 0, 0, 4, 12, ["bas"])
			_piece(f, 9, 0, 4, 12, ["droite"])
		5:  # une grande et une petite
			_piece(f, -4, 0, 9, 12, ["gauche"])
			_piece(f, 10, 0, 3, 12, ["droite"])

# L'AILE ENTRÉE (face du bas). Un hall central en croix qui rejoint les 4 bords
# (circulation + basculements vers les ailes voisines) ; tout autour, des pièces
# variées ; et du mobilier pour l'identité. On arrive par le nord (haut en v).
func _aile_entree(f: Dictionary) -> void:
	# --- les pièces : chacune a DEUX entrées, et certaines COMMUNIQUENT entre
	#     elles (des routes qui ne passent pas toutes par le hall). ---
	# NW : Vestiaire au-dessus du W.-C., cloison partagée (une seule) en v=8.
	_piece(f, -9, 11.25, 5.5, 3.25, ["droite", "bas"])       # Vestiaire : hall + W.-C.
	_piece(f, -9, 5.75, 5.5, 2.25, ["droite"], ["haut"])     # W.-C. : hall (mur haut = celui du vestiaire)
	# NE : Salon, deux entrées sur le hall (deux côtés différents).
	_piece(f, 9, 9, 5.5, 5.5, ["gauche", "bas"])             # Salon d'accueil
	# SW : Buanderie, deux entrées sur le hall.
	_piece(f, -9, -9, 5.5, 5.5, ["droite", "haut"])          # Buanderie
	# SE : Débarras au-dessus de l'Escalier, cloison partagée en v=-8.
	_piece(f, 9, -5.75, 5.5, 2.25, ["gauche", "bas"])        # Débarras : hall + escalier
	_piece(f, 9, -11.25, 5.5, 3.25, ["gauche"], ["haut"])    # Escalier : hall (mur haut = celui du débarras)
	# --- le mobilier (bois brun mat, tissu sourd, pierre, émail sourd) ---
	var bois := Color(0.26, 0.18, 0.11)
	var tissu := Color(0.30, 0.28, 0.27)
	var pierre := Color(0.30, 0.28, 0.25)
	var email := Color(0.52, 0.51, 0.49)
	# hall d'entrée : une console
	_table(f, 0, 13.7, 1.8, 0.5, bois)
	# vestiaire : un banc + une barre à patères au mur
	_bloc_face(f, -9, 13.7, 3.4, 0.5, 0.0, 0.45, bois)
	_bloc_face(f, -13.7, 9, 0.12, 3.0, 1.7, 0.1, bois)
	# W.-C. : cuvette + abattant
	_bloc_face(f, -12.6, 5.5, 0.6, 0.55, 0.0, 0.4, email)
	_bloc_face(f, -12.6, 5.5, 0.55, 0.4, 0.4, 0.12, email)
	# salon d'accueil : canapé (dossier au nord), table basse, fauteuil
	_canape(f, 9, 13.3, 3.4, tissu)
	_table(f, 9, 10, 1.6, 0.9, bois)
	_canape(f, 12.8, 6, 1.3, tissu)
	# buanderie : machine + évier
	_bloc_face(f, -12.6, -6, 0.85, 0.85, 0.0, 0.95, email)
	_lavabo(f, -6, -12.6, pierre)
	# débarras : rayonnages
	_etagere(f, 12.6, -6.5, 3.2, bois)
	# cage d'escalier : trois marches montantes
	_bloc_face(f, 9, -10.6, 3.0, 0.9, 0.0, 0.5, pierre)
	_bloc_face(f, 9, -11.5, 3.0, 0.9, 0.0, 1.0, pierre)
	_bloc_face(f, 9, -12.4, 3.0, 0.9, 0.0, 1.5, pierre)

# ---- Le couloir d'entrée -----------------------------------------------------

func _construire_couloir() -> void:
	var gris := Color(0.40, 0.40, 0.44)
	var sol_haut := -DEMI + EPAISSEUR / 2.0
	_boite(Vector3(PORTE_DEMI_LARGEUR * 2.0, EPAISSEUR, 9.0),
		Vector3(0, sol_haut - EPAISSEUR / 2.0, -DEMI - 3.5), gris)
	var h := PORTE_HAUTEUR
	var cy := sol_haut + h / 2.0
	_boite(Vector3(EPAISSEUR, h, 8.0), Vector3(-PORTE_DEMI_LARGEUR, cy, -DEMI - 4.0), gris)
	_boite(Vector3(EPAISSEUR, h, 8.0), Vector3( PORTE_DEMI_LARGEUR, cy, -DEMI - 4.0), gris)
	_boite(Vector3(PORTE_DEMI_LARGEUR * 2.0, h, EPAISSEUR), Vector3(0, cy, -DEMI - 8.0), gris)
	var retour := Portail.instantiate()
	retour.scene_cible = "res://jeu.tscn"
	retour.ouvert_au_depart = true
	retour.position = Vector3(0, sol_haut, -DEMI - 7.3)
	retour.scale = Vector3(3, 1, 1)
	add_child(retour)

func _placer_joueur() -> void:
	var j := JoueurCube.instantiate()
	j.demi_cube = DEMI
	j.ouverture_bas = Vector3.DOWN
	j.ouverture_dir = Vector3(0, 0, -1)
	j.ouverture_demi_largeur = PORTE_DEMI_LARGEUR
	j.position = Vector3(0, -DEMI + EPAISSEUR / 2.0 + 0.95, -DEMI - 6.0)
	add_child(j)
	j.get_node("PivotYaw").rotation.y = PI
