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

# Une table : plateau fin + ceinture (jupe) + 4 pieds resserrés vers le bas
# (illusion d'un pied qui s'affine, avec deux blocs empilés par pied).
func _table(f: Dictionary, cu: float, cv: float, larg: float, prof: float, couleur: Color) -> void:
	_bloc_face(f, cu, cv, larg, prof, 0.68, 0.05, couleur)                    # plateau, fin
	_bloc_face(f, cu, cv, larg - 0.16, prof - 0.16, 0.58, 0.08, couleur)      # ceinture (jupe)
	var du := larg / 2.0 - 0.14
	var dv := prof / 2.0 - 0.14
	for su in [-1.0, 1.0]:
		for sv in [-1.0, 1.0]:
			_bloc_face(f, cu + su * du, cv + sv * dv, 0.11, 0.11, 0.28, 0.30, couleur)  # pied haut
			_bloc_face(f, cu + su * du, cv + sv * dv, 0.08, 0.08, 0.0, 0.28, couleur)   # pied bas, aminci

# Un canapé : quatre pieds courts + assise en deux coussins + dossier + accoudoirs.
func _canape(f: Dictionary, cu: float, cv: float, larg: float, couleur: Color) -> void:
	var du := larg / 2.0 - 0.35
	for su in [-1.0, 1.0]:
		for sv in [-1.0, 1.0]:
			_bloc_face(f, cu + su * du, cv + sv * 0.35, 0.09, 0.09, 0.0, 0.14, couleur)  # pieds
	var demi_larg := (larg - 0.5) / 2.0 - 0.03
	_bloc_face(f, cu - demi_larg / 2.0 - 0.015, cv - 0.05, demi_larg, 0.68, 0.14, 0.20, couleur)  # coussin g
	_bloc_face(f, cu + demi_larg / 2.0 + 0.015, cv - 0.05, demi_larg, 0.68, 0.14, 0.20, couleur)  # coussin d
	_bloc_face(f, cu, cv + 0.4, larg, 0.2, 0.14, 0.55, couleur)                                   # dossier
	_bloc_face(f, cu - larg / 2.0 + 0.12, cv, 0.24, 0.95, 0.14, 0.34, couleur)                    # accoudoir g
	_bloc_face(f, cu + larg / 2.0 - 0.12, cv, 0.24, 0.95, 0.14, 0.34, couleur)                    # accoudoir d

# Une étagère : plinthe + deux montants + panneau de fond + quatre tablettes + chapeau,
# et sur chaque tablette, un petit bric-à-brac (caisses/boîtes empilées, tailles et
# teintes variées) — une étagère nue lit comme un décor inachevé, jamais crédible.
func _etagere(f: Dictionary, cu: float, cv: float, larg: float, couleur: Color) -> void:
	_bloc_face(f, cu, cv + 0.19, larg, 0.04, 0.0, 0.08, couleur)                        # plinthe
	_bloc_face(f, cu, cv + 0.19, larg - 0.12, 0.04, 0.08, 1.86, couleur.darkened(0.15))  # panneau de fond
	_bloc_face(f, cu - larg / 2.0 + 0.06, cv, 0.1, 0.4, 0.08, 1.86, couleur)             # montant g
	_bloc_face(f, cu + larg / 2.0 - 0.06, cv, 0.1, 0.4, 0.08, 1.86, couleur)             # montant d
	var tablettes := [0.42, 0.90, 1.38, 1.84]
	for y in tablettes:
		_bloc_face(f, cu, cv, larg, 0.42, y, 0.05, couleur)
	_bloc_face(f, cu, cv, larg + 0.08, 0.46, 1.94, 0.05, couleur)                        # chapeau
	# bric-à-brac : trois objets par tablette (sauf la plus haute, moins encombrée),
	# décalés en cv pour rester bien posés sur la profondeur de la tablette.
	var offsets_larg := [-0.30, -0.02, 0.30]
	var hauteurs := [0.22, 0.30, 0.18]
	var teintes := [couleur.lightened(0.12), couleur.darkened(0.2), couleur.lightened(0.25)]
	for ti in tablettes.size():
		if ti == tablettes.size() - 1:
			continue  # tablette du haut, hors de portée : laissée nue
		var y_base: float = tablettes[ti] + 0.05
		for oi in offsets_larg.size():
			_bloc_face(f, cu + offsets_larg[oi] * larg, cv, 0.16, 0.20, y_base, hauteurs[oi], teintes[oi])

# Un lavabo : pied fin + vasque + rebord + robinet au mur.
func _lavabo(f: Dictionary, cu: float, cv: float, couleur: Color) -> void:
	_bloc_face(f, cu, cv, 0.16, 0.16, 0.0, 0.70, couleur.darkened(0.1))                 # pied
	_bloc_face(f, cu, cv, 0.62, 0.44, 0.70, 0.16, couleur)                              # vasque
	_bloc_face(f, cu, cv, 0.70, 0.50, 0.84, 0.03, couleur.lightened(0.1))               # rebord
	_bloc_face(f, cu, cv - 0.24, 0.06, 0.06, 0.86, 0.16, couleur.darkened(0.2))         # robinet

# Une machine à laver : caisson + hublot en creux (plus sombre) + bandeau de
# contrôle — un pavé nu ne lit pas comme un meuble reconnaissable.
func _machine_a_laver(f: Dictionary, cu: float, cv: float, couleur: Color) -> void:
	_bloc_face(f, cu, cv, 0.85, 0.85, 0.0, 0.95, couleur)                          # caisson
	_bloc_face(f, cu, cv - 0.44, 0.5, 0.06, 0.30, 0.5, couleur.darkened(0.35))     # hublot (creux)
	_bloc_face(f, cu, cv - 0.44, 0.75, 0.04, 0.82, 0.1, couleur.darkened(0.15))    # bandeau de contrôle

# ---- Les plaques de nom (même principe que le manoir, jet 15) ----------------

# Une plaque de nom, ombrée (révélée par la torche, jamais allumée), montée sur
# un mur à la hauteur "hauteur", et orientée pour faire face à "face_dir" —
# la direction (tangente, unitaire) vers laquelle le texte se tourne.
func _plaque(f: Dictionary, cu: float, cv: float, texte: String, face_dir: Vector3, hauteur: float = 1.7) -> void:
	var pos: Vector3 = f["pos"]
	var normale: Vector3 = f["normale"]
	var t := _tu_tv(normale)
	var tu: Vector3 = t[0]
	var tv: Vector3 = t[1]
	var label := Label3D.new()
	label.text = texte
	label.pixel_size = 0.006
	label.font_size = 64
	label.shaded = true
	label.no_depth_test = false
	var x_axis: Vector3 = normale.cross(face_dir).normalized()
	label.transform = Transform3D(Basis(x_axis, normale, face_dir),
		pos + normale * (EPAISSEUR / 2.0 + hauteur) + tu * cu + tv * cv + face_dir * 0.06)
	add_child(label)

# Pose une plaque sur le mur OPPOSÉ à la porte principale d'une pièce, tournée
# vers cette porte — visible en entrant, comme au manoir (jet 15).
func _plaque_piece(f: Dictionary, cu: float, cv: float, du: float, dv: float, texte: String, cote_porte: String) -> void:
	var t := _tu_tv(f["normale"])
	var tu: Vector3 = t[0]
	var tv: Vector3 = t[1]
	match cote_porte:
		"droite":
			_plaque(f, cu - du + 0.1, cv, texte, tu)
		"gauche":
			_plaque(f, cu + du - 0.1, cv, texte, -tu)
		"haut":
			_plaque(f, cu, cv - dv + 0.1, texte, tv)
		"bas":
			_plaque(f, cu, cv + dv - 0.1, texte, -tv)

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

# Le couloir central en croix (même principe que l'aile entrée, face 0) :
# QUADRANT est la distance du centre au coeur d'un quadrant plein (9 = HALL + demi-taille),
# DEMI_QUADRANT la demi-taille d'un quadrant plein (5,5). Le couloir occupe la bande
# |cu|<HALL ou |cv|<HALL, jamais construite, et rejoint donc les quatre bords de la face.
const HALL: float = 3.5
const DEMI_QUADRANT: float = 5.5
const QUADRANT: float = HALL + DEMI_QUADRANT   # 9.0

# L'agencement propre à chaque face (index 0..5) : bas, haut, nord, sud, ouest, est.
func _layout_face(f: Dictionary, idx: int) -> void:
	match idx:
		0:  # l'AILE ENTRÉE (arrivée), dense et meublée
			_aile_entree(f)
		1:  # quatre pièces égales, une par quadrant, chacune ouverte sur le couloir
			_face_quatre_pieces(f)
		2:  # deux pièces en diagonale, plus grandes ; les deux autres quadrants restent
			# une extension ouverte du couloir (loin de la porte du couloir d'entrée)
			_face_deux_grandes_pieces(f)
		3:  # six petites pièces : deux quadrants pleins, deux quadrants coupés en deux
			# (même schéma de découpe que le vestiaire/W.-C. de l'aile entrée, face 0)
			_face_six_pieces(f)
		4:  # trois pièces en enfilade, posées dans la moitié nord ; la moitié sud et
			# les côtés restent une extension ouverte du couloir.
			_face_enfilade(f)
		5:  # une grande pièce (tout l'ouest, un seul accès) et une petite (posée dans
			# l'est, dégagée tout autour) — comme le Bureau du manoir, en cul-de-sac partiel.
			_face_grande_et_petite(f)

# LA FACE 5 : une grande pièce (tout l'ouest, un seul accès) et une petite
# (posée dans l'est, dégagée tout autour) — comme le Bureau du manoir, en
# cul-de-sac partiel.
func _face_grande_et_petite(f: Dictionary) -> void:
	var bois := Color(0.26, 0.18, 0.11)
	var tissu := Color(0.30, 0.28, 0.27)
	var pierre := Color(0.30, 0.28, 0.25)
	# Ouest : Grande salle — un seul accès (droite), meublée en trois zones
	# étalées le long du mur du fond, loin de la porte.
	_piece(f, -QUADRANT, 0, DEMI_QUADRANT, 14.5, ["droite"])
	_plaque_piece(f, -QUADRANT, 0, DEMI_QUADRANT, 14.5, "Grande salle", "droite")
	_canape(f, -QUADRANT - 3.0, -9.0, 2.8, tissu)
	_table(f, -QUADRANT - 3.0, 0.0, 2.4, 1.1, bois)
	_etagere(f, -QUADRANT - 3.0, 9.0, 3.4, bois)
	# Est : Remise — petite pièce en cul-de-sac, dégagée tout autour.
	_piece(f, QUADRANT, 0, 3.0, 5.0, ["gauche"])
	_plaque_piece(f, QUADRANT, 0, 3.0, 5.0, "Remise", "gauche")
	_bloc_face(f, QUADRANT + 1.5, 0.0, 0.9, 0.9, 0.0, 0.9, pierre)  # caisse

# LA FACE 4 : trois pièces en enfilade (ouest→centre→est, portes qui
# s'enchaînent), posées dans la moitié nord ; la moitié sud et les côtés
# restent une extension ouverte du couloir.
func _face_enfilade(f: Dictionary) -> void:
	var bois := Color(0.26, 0.18, 0.11)
	var tissu := Color(0.30, 0.28, 0.27)
	# Ouest : Antichambre — un banc, et une patère au mur voisin (le banc seul
	# lisait comme un objet oublié).
	_piece(f, -9.6, QUADRANT, 4.8, DEMI_QUADRANT, ["droite", "bas"])
	_plaque_piece(f, -9.6, QUADRANT, 4.8, DEMI_QUADRANT, "Antichambre", "bas")
	_bloc_face(f, -9.6, QUADRANT + 3.5, 3.0, 0.5, 0.0, 0.45, bois)  # banc
	_bloc_face(f, -13.9, QUADRANT, 0.12, 2.6, 1.7, 0.1, bois)       # patère au mur gauche
	# Centre : Salle commune — table longue, coeur de l'enfilade, un banc adossé
	# au mur solide pour que la table ait de la compagnie.
	_piece(f, 0.0, QUADRANT, 4.8, DEMI_QUADRANT, ["droite"], ["gauche"])
	_plaque_piece(f, 0.0, QUADRANT, 4.8, DEMI_QUADRANT, "Salle commune", "droite")
	_table(f, 0.0, QUADRANT - 2.0, 3.2, 1.1, bois)
	_bloc_face(f, 0.0, QUADRANT + 3.7, 2.6, 0.4, 0.0, 0.45, bois)   # banc contre le mur du fond
	# Est : Réfectoire — un canapé et une petite table basse devant lui, cul-de-sac
	# de l'enfilade côté couloir sud.
	_piece(f, 9.6, QUADRANT, 4.8, DEMI_QUADRANT, ["bas"], ["gauche"])
	_plaque_piece(f, 9.6, QUADRANT, 4.8, DEMI_QUADRANT, "Réfectoire", "bas")
	_canape(f, 9.6, QUADRANT + 3.0, 2.6, tissu)
	_table(f, 9.6, QUADRANT + 0.8, 1.4, 0.8, bois)

# LA FACE 3 : six petites pièces — deux quadrants pleins (NE, SW) et deux
# quadrants coupés en deux le long de v (NW, SE), même découpe que le
# vestiaire/W.-C. de l'aile entrée (face 0).
func _face_six_pieces(f: Dictionary) -> void:
	var bois := Color(0.26, 0.18, 0.11)
	var email := Color(0.52, 0.51, 0.49)
	# NE plein : Chaufferie.
	_piece(f, QUADRANT, QUADRANT, DEMI_QUADRANT, DEMI_QUADRANT, ["gauche", "bas"])
	_plaque_piece(f, QUADRANT, QUADRANT, DEMI_QUADRANT, DEMI_QUADRANT, "Chaufferie", "gauche")
	_etagere(f, QUADRANT + 3.0, QUADRANT + 3.0, 3.2, bois)
	_bloc_face(f, QUADRANT + 2.5, QUADRANT - 1.0, 1.4, 1.4, 0.0, 1.6, email)  # cuve
	# SW plein : Local technique.
	_piece(f, -QUADRANT, -QUADRANT, DEMI_QUADRANT, DEMI_QUADRANT, ["droite", "haut"])
	_plaque_piece(f, -QUADRANT, -QUADRANT, DEMI_QUADRANT, DEMI_QUADRANT, "Local technique", "droite")
	_etagere(f, -QUADRANT - 3.0, -QUADRANT - 3.0, 3.2, bois)
	_table(f, -QUADRANT - 2.0, -QUADRANT + 2.0, 2.0, 1.0, bois)
	# NW coupé en deux le long de v : la pièce du coin (Vestiaires), puis celle
	# côté couloir (Casiers), cloison partagée en v = QUADRANT - 2.0.
	_piece(f, -QUADRANT, QUADRANT + 2.25, DEMI_QUADRANT, 3.25, ["droite", "bas"])
	_plaque_piece(f, -QUADRANT, QUADRANT + 2.25, DEMI_QUADRANT, 3.25, "Vestiaires", "droite")
	_bloc_face(f, -QUADRANT - 2.5, QUADRANT + 3.5, 3.4, 0.5, 0.0, 0.45, bois)  # banc
	_piece(f, -QUADRANT, QUADRANT - 3.25, DEMI_QUADRANT, 2.25, ["droite"], ["haut"])
	_plaque_piece(f, -QUADRANT, QUADRANT - 3.25, DEMI_QUADRANT, 2.25, "Casiers", "droite")
	_etagere(f, -QUADRANT - 2.5, QUADRANT - 3.6, 3.2, bois)
	# SE coupé en deux le long de v (même schéma, en miroir) : Infirmerie et Loge.
	# Chacune avait un seul meuble isolé — un second objet leur donne compagnie.
	_piece(f, QUADRANT, -QUADRANT - 2.25, DEMI_QUADRANT, 3.25, ["gauche", "haut"])
	_plaque_piece(f, QUADRANT, -QUADRANT - 2.25, DEMI_QUADRANT, 3.25, "Infirmerie", "gauche")
	_lavabo(f, QUADRANT + 2.5, -QUADRANT - 3.5, email)
	_etagere(f, QUADRANT + 2.5, -QUADRANT - 0.8, 2.4, bois)                       # armoire à pharmacie
	_piece(f, QUADRANT, -QUADRANT + 3.25, DEMI_QUADRANT, 2.25, ["gauche"], ["bas"])
	_plaque_piece(f, QUADRANT, -QUADRANT + 3.25, DEMI_QUADRANT, 2.25, "Loge", "gauche")
	_bloc_face(f, QUADRANT + 2.5, -QUADRANT + 3.6, 3.4, 0.5, 0.0, 0.45, bois)  # banc
	_etagere(f, QUADRANT + 2.5, -QUADRANT + 4.8, 2.0, bois)                       # petite étagère

# LA FACE 2 : deux grandes pièces en diagonale (les deux autres quadrants
# restent une extension ouverte du couloir, sans mur ni meuble).
func _face_deux_grandes_pieces(f: Dictionary) -> void:
	var bois := Color(0.26, 0.18, 0.11)
	var demi := DEMI_QUADRANT + 1.0
	# NW : Salle des machines — rangées d'étagères et un établi.
	_piece(f, -QUADRANT, QUADRANT, demi, demi, ["droite", "bas"])
	_plaque_piece(f, -QUADRANT, QUADRANT, demi, demi, "Salle des machines", "droite")
	_etagere(f, -QUADRANT - 3.0, QUADRANT + 3.5, 3.5, bois)
	_etagere(f, -QUADRANT - 3.0, QUADRANT - 1.5, 3.5, bois)
	_table(f, -QUADRANT + 1.5, QUADRANT + 4.0, 2.6, 1.0, bois)
	# SE : Entrepôt — trois rangées de stockage.
	_piece(f, QUADRANT, -QUADRANT, demi, demi, ["gauche", "haut"])
	_plaque_piece(f, QUADRANT, -QUADRANT, demi, demi, "Entrepôt", "gauche")
	_etagere(f, QUADRANT + 3.0, -QUADRANT - 3.5, 3.5, bois)
	_etagere(f, QUADRANT + 3.0, -QUADRANT + 0.0, 3.5, bois)
	_etagere(f, QUADRANT + 3.0, -QUADRANT + 3.5, 3.5, bois)

# LA FACE 1 : quatre pièces égales, une par quadrant, chacune ouverte sur le
# couloir par deux côtés. Meublée légèrement, chacune avec sa plaque (jet 15).
func _face_quatre_pieces(f: Dictionary) -> void:
	var bois := Color(0.26, 0.18, 0.11)
	var tissu := Color(0.30, 0.28, 0.27)
	# NW : Atelier — table et étagère groupées contre le mur ouest (sans porte),
	# loin des deux entrées (est, sud), au lieu de deux meubles séparés.
	_piece(f, -QUADRANT, QUADRANT, DEMI_QUADRANT, DEMI_QUADRANT, ["droite", "bas"])
	_plaque_piece(f, -QUADRANT, QUADRANT, DEMI_QUADRANT, DEMI_QUADRANT, "Atelier", "droite")
	_table(f, -QUADRANT - 2.0, QUADRANT + 2.5, 3.0, 1.1, bois)
	_etagere(f, -QUADRANT - 3.3, QUADRANT + 0.2, 2.6, bois)
	# NE : Réserve — deux étagères de stockage.
	_piece(f, QUADRANT, QUADRANT, DEMI_QUADRANT, DEMI_QUADRANT, ["gauche", "bas"])
	_plaque_piece(f, QUADRANT, QUADRANT, DEMI_QUADRANT, DEMI_QUADRANT, "Réserve", "gauche")
	_etagere(f, QUADRANT + 2.5, QUADRANT + 3.0, 3.2, bois)
	_etagere(f, QUADRANT + 2.5, QUADRANT - 3.0, 3.2, bois)
	# SW : Bureau — table et fauteuil groupés contre le mur ouest (sans porte),
	# loin des deux portes (est, nord) ; le fauteuil traînait près de la porte
	# nord, corrigé.
	_piece(f, -QUADRANT, -QUADRANT, DEMI_QUADRANT, DEMI_QUADRANT, ["droite", "haut"])
	_plaque_piece(f, -QUADRANT, -QUADRANT, DEMI_QUADRANT, DEMI_QUADRANT, "Bureau", "droite")
	_table(f, -QUADRANT - 2.5, -QUADRANT - 2.5, 1.8, 1.0, bois)
	_canape(f, -QUADRANT - 3.5, -QUADRANT + 1.0, 1.3, tissu)
	# SE : Chambre froide — canapé et petite table contre le mur est (sans porte),
	# loin des deux portes (ouest, nord) ; le canapé traînait près de la porte
	# nord, corrigé, et il avait un second meuble en compagnie.
	_piece(f, QUADRANT, -QUADRANT, DEMI_QUADRANT, DEMI_QUADRANT, ["gauche", "haut"])
	_plaque_piece(f, QUADRANT, -QUADRANT, DEMI_QUADRANT, DEMI_QUADRANT, "Chambre froide", "gauche")
	_canape(f, QUADRANT + 2.5, -QUADRANT - 2.5, 2.6, tissu)
	_table(f, QUADRANT + 2.5, -QUADRANT + 0.5, 1.4, 0.8, bois)

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
	# --- les plaques : sur le mur du fond, visibles en entrant (jet 15) ---
	_plaque_piece(f, -9, 11.25, 5.5, 3.25, "Vestiaire", "droite")
	_plaque_piece(f, -9, 5.75, 5.5, 2.25, "W.-C.", "droite")
	_plaque_piece(f, 9, 9, 5.5, 5.5, "Salon", "gauche")
	_plaque_piece(f, -9, -9, 5.5, 5.5, "Buanderie", "droite")
	_plaque_piece(f, 9, -5.75, 5.5, 2.25, "Débarras", "gauche")
	_plaque_piece(f, 9, -11.25, 5.5, 3.25, "Escalier", "gauche")
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
	# salon d'accueil : canapé (dossier au nord) + table basse groupée devant lui
	# (hors de la diagonale porte-gauche → porte-bas), fauteuil dans l'angle libre.
	_canape(f, 9, 13.3, 3.4, tissu)
	_table(f, 9, 11.7, 1.6, 0.9, bois)
	_canape(f, 11.5, 10.2, 1.3, tissu)                          # fauteuil rapproché du duo canapé/table
	# buanderie : machine à laver détaillée (hublot + bandeau) + évier, regroupés
	# contre le même mur (angle opposé aux deux portes).
	_machine_a_laver(f, -12.6, -12.6, email)
	_lavabo(f, -8.7, -12.6, pierre)
	# débarras : rayonnages + une caisse posée au sol à côté.
	_etagere(f, 12.6, -6.5, 3.2, bois)
	_bloc_face(f, 12.2, -4.2, 0.7, 0.7, 0.0, 0.6, bois)
	# cage d'escalier : trois marches montantes collées au mur du fond (le plus
	# loin de la porte), reculées de la face intérieure du mur pour ne plus la
	# chevaucher (le mur occupe cu 14.25-14.75, les marches restent sous 14.2).
	_bloc_face(f, 13.5, -11.25, 1.2, 4.0, 0.0, 0.5, pierre)
	_bloc_face(f, 12.6, -11.25, 1.2, 4.0, 0.0, 1.0, pierre)
	_bloc_face(f, 11.7, -11.25, 1.2, 4.0, 0.0, 1.5, pierre)

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
