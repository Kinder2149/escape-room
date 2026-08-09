extends StaticBody3D

## Un coffre qu'on vise, qu'on ouvre, puis dont on prend le contenu.
## Deux gestes distincts : E pour ouvrir, E à nouveau pour prendre.
## Le joueur dialogue avec lui par « texte_action() » et « agir() ».
##
## Un coffre ordinaire s'ouvre à main nue. Un coffre-fort (« verrouille »)
## exige les morceaux de clé — mais il ne décide pas lui-même : il signale
## qu'on a essayé, et c'est le Jeu qui sait ce que le joueur détient.
## Même partage des rôles que la porte rouge.

signal morceau_pris
signal badge_pris
signal cle_intro_prise
signal tentative_ouverture

## Verrouillé : il faut les morceaux de clé pour l'ouvrir (voir jeu.gd).
@export var verrouille := false
## Ce qu'on y trouve : le badge pour le coffre-fort, un morceau pour les autres.
@export var contient_badge := false
## Le coffre du sas d'intro (jet 16) contient la clé d'intro : elle seule ouvre
## la porte du sas, et surtout PAS la porte rouge (que seul le badge ouvre).
@export var contient_cle_intro := false

const ANGLE_OUVERT := deg_to_rad(-110.0)
const DUREE_BASCULE := 0.35

## Ouvrir un coffre cloue le joueur sur place le temps de la fouille (jet 13) :
## c'est le geste qui l'expose. Prendre le contenu, coffre déjà ouvert, reste
## instantané. Durée validée à l'équilibrage le 27/07/2026.
const DUREE_FOUILLE := 2.0

## Le couvercle est cherché par son nom, pas par un chemin figé : chaque
## modèle 3D nomme le sien à sa façon (« Couvercle », « CouvercleFort »…),
## et un coffre sans couvercle doit se voir tout de suite, pas planter.
@onready var couvercle: Node3D = trouve_couvercle()
@onready var contenu: Node3D = $Morceau


func trouve_couvercle() -> Node3D:
	for enfant in $Modele.get_children():
		if enfant.name.begins_with("Couvercle"):
			return enfant
	push_error("%s : aucun couvercle dans son modèle 3D." % name)
	return null

var ouvert := false
var vide := false


func texte_action() -> String:
	if not ouvert:
		return "Ouvrir"
	if not vide:
		return "Prendre"
	return ""


## Combien de temps ce geste cloue le joueur. Seule l'OUVERTURE d'un coffre
## ordinaire est une fouille : c'est là qu'on s'affaire, dos au danger. Prendre
## le contenu une fois le coffre ouvert est instantané, et le coffre-fort
## verrouillé n'est pas une fouille locale (le Jeu décide de son ouverture).
func duree_fouille() -> float:
	if not ouvert and not verrouille:
		return DUREE_FOUILLE
	return 0.0


func agir() -> void:
	if not ouvert:
		if verrouille:
			tentative_ouverture.emit()
		else:
			ouvre()
	elif not vide:
		prend_contenu()


func ouvre() -> void:
	ouvert = true
	var bascule := create_tween()
	bascule.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	bascule.tween_property(couvercle, "rotation:x", ANGLE_OUVERT, DUREE_BASCULE)


func prend_contenu() -> void:
	vide = true
	contenu.hide()
	if contient_badge:
		badge_pris.emit()
	elif contient_cle_intro:
		cle_intro_prise.emit()
	else:
		morceau_pris.emit()
