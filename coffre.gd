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
signal tentative_ouverture

## Verrouillé : il faut les morceaux de clé pour l'ouvrir (voir jeu.gd).
@export var verrouille := false
## Ce qu'on y trouve : le badge pour le coffre-fort, un morceau pour les autres.
@export var contient_badge := false

const ANGLE_OUVERT := deg_to_rad(-110.0)
const DUREE_BASCULE := 0.35

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
	else:
		morceau_pris.emit()
