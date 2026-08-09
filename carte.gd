extends Control

## La carte du manoir (jet 17) : un plan en surimpression, ouvert/fermé à M.
## Chaque pièce est dessinée à l'échelle dans sa teinte de sol (jet 10), avec son
## nom ; rez à gauche, étage à droite. AUCUN objet n'y figure — elle situe, elle
## ne résout pas. Construite à partir des dalles de sol RÉELLES : elle colle
## toujours à la géométrie, et la cave s'y ajoutera d'elle-même le jour venu
## (un troisième niveau se lira à l'altitude, sans qu'on dessine rien).

## Au-dessus de cette altitude, une dalle appartient à l'étage.
const SEUIL_ETAGE := 1.5
const MARGE := 70.0
const COULEUR_FOND := Color(0.03, 0.03, 0.04, 0.97)
const COULEUR_MUR := Color(0.0, 0.0, 0.0, 0.55)
const COULEUR_NOM := Color(0.94, 0.93, 0.91)
const COULEUR_TITRE := Color(0.85, 0.78, 0.62)
const COULEUR_ICI := Color(0.45, 0.9, 1.0)

@onready var maison: Node3D = get_node("../../Maison")
@onready var joueur: Node3D = get_node("../../Joueur")

## Le joueur a-t-il la carte en poche ? Faux au départ : on la ramasse sur la
## table de l'intro (le Jeu passe ceci à vrai). Sans elle, M ne fait rien.
var disponible := false

var police: Font


func _ready() -> void:
	hide()
	police = ThemeDB.fallback_font
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _unhandled_input(evenement: InputEvent) -> void:
	if not disponible:
		return
	if evenement is InputEventKey and evenement.pressed and not evenement.echo \
			and evenement.keycode == KEY_M:
		visible = not visible


func _process(_delta: float) -> void:
	# Le point « tu es ici » suit le joueur tant que la carte est ouverte.
	if visible:
		queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), COULEUR_FOND)
	var rez: Array = []
	var etage: Array = []
	for sol in maison.get_node("SolsDesPieces").get_children():
		var p: Vector3 = sol.global_position
		var t: Vector2 = sol.mesh.size
		var d := {
			"x": p.x, "z": p.z, "sx": t.x, "sz": t.y,
			"col": sol.material_override.albedo_color,
			"nom": _nom_de(String(sol.name)),
		}
		if p.y < SEUIL_ETAGE:
			rez.append(d)
		else:
			etage.append(d)
	_dessine_niveau(rez, Rect2(0.0, 0.0, size.x * 0.5, size.y), "REZ-DE-CHAUSSÉE", true)
	_dessine_niveau(etage, Rect2(size.x * 0.5, 0.0, size.x * 0.5, size.y), "ÉTAGE", false)


## Un niveau, dessiné à l'échelle et centré dans sa moitié d'écran. Le monde
## (x, z) se projette sur l'écran (x, y) sans miroir : est à droite, et l'axe z
## descend — la carte garde la même main que le manoir.
func _dessine_niveau(dalles: Array, zone: Rect2, titre: String, est_rez: bool) -> void:
	if dalles.is_empty():
		return
	var minx := INF
	var maxx := -INF
	var minz := INF
	var maxz := -INF
	for d in dalles:
		minx = minf(minx, d.x - d.sx * 0.5)
		maxx = maxf(maxx, d.x + d.sx * 0.5)
		minz = minf(minz, d.z - d.sz * 0.5)
		maxz = maxf(maxz, d.z + d.sz * 0.5)
	var largeur: float = maxx - minx
	var hauteur: float = maxz - minz
	var echelle: float = minf(
		(zone.size.x - 2.0 * MARGE) / largeur,
		(zone.size.y - 2.0 * MARGE) / hauteur)
	var dx: float = zone.position.x + (zone.size.x - largeur * echelle) * 0.5
	var dz: float = zone.position.y + (zone.size.y - hauteur * echelle) * 0.5

	draw_string(police, Vector2(zone.position.x + MARGE, zone.position.y + MARGE * 0.7),
		titre, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, COULEUR_TITRE)

	for d in dalles:
		var coin := Vector2(dx + (d.x - d.sx * 0.5 - minx) * echelle,
			dz + (d.z - d.sz * 0.5 - minz) * echelle)
		var taille := Vector2(d.sx * echelle, d.sz * echelle)
		draw_rect(Rect2(coin, taille), d.col)
		draw_rect(Rect2(coin, taille), COULEUR_MUR, false, 2.0)
		if d.nom != "":
			draw_string(police, Vector2(coin.x, coin.y + taille.y * 0.5 + 5.0),
				d.nom, HORIZONTAL_ALIGNMENT_CENTER, taille.x, 13, COULEUR_NOM)

	var pj: Vector3 = joueur.global_position
	if (pj.y < SEUIL_ETAGE) == est_rez:
		var pt := Vector2(dx + (pj.x - minx) * echelle, dz + (pj.z - minz) * echelle)
		draw_circle(pt, 6.0, COULEUR_ICI)


## Le nom affiché d'une dalle : celui de la Pièce correspondante (« SolChambre »
## → la Pièce « Chambre » → son nom_affiche « Introduction »). Les circulations
## (couloirs, galerie, paliers) n'ont pas de Pièce : elles restent muettes.
func _nom_de(nom_sol: String) -> String:
	if not nom_sol.begins_with("Sol"):
		return ""
	var nom_piece := nom_sol.substr(3)
	for piece in get_tree().get_nodes_in_group("pieces"):
		if String(piece.name) == nom_piece:
			return piece.nom_affiche if piece.nom_affiche != "" else nom_piece
	return ""
