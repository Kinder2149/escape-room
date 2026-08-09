extends StaticBody3D

## La porte verrouillée du sas d'introduction (jet 16). Comme la porte rouge,
## elle se vise et s'ouvre avec E — mais c'est le Jeu qui sait si le joueur a la
## clé d'intro : la porte ne fait que signaler qu'on a essayé. Même partage des
## rôles que la porte rouge et le coffre-fort.
##
## Verrouillée, son corps bloque le joueur dans le sas ; ouverte, elle libère le
## passage vers le manoir. Elle vit dans jeu.tscn, PAS dans maison.tscn : posée
## là, elle bloque le corps sans entrer dans la carte de navigation (bakée du
## seul CSG de la maison). Les rôdeurs continuent d'ignorer le sas, et la porte
## ne trouble aucun de leurs trajets.

signal tentative_ouverture

## De combien le battant se relève pour dégager l'ouverture (2,2 m de haut).
const HAUTEUR_OUVERTURE := 2.3
const DUREE_OUVERTURE := 0.6

var ouverte := false

@onready var battant: MeshInstance3D = $Battant
@onready var collision: CollisionShape3D = $CollisionShape3D


func texte_action() -> String:
	return "" if ouverte else "Ouvrir la porte"


func agir() -> void:
	if ouverte:
		return
	tentative_ouverture.emit()


## Ouverte par le Jeu, clé en poche : le corps cesse de bloquer aussitôt, et le
## battant se relève pour dégager le passage.
func ouvre() -> void:
	ouverte = true
	collision.set_deferred("disabled", true)
	var glisse := create_tween()
	glisse.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	glisse.tween_property(battant, "position:y",
		battant.position.y + HAUTEUR_OUVERTURE, DUREE_OUVERTURE)
