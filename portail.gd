extends Node3D

## Un portail vers une autre scène. Un panneau (la « porte ») bloque le passage ;
## une fois ouvert, une zone détecte le joueur et bascule de scène.
## Sert dans le manoir (porte dev → quartier) et au retour (quartier → manoir).
## Les deux mondes ne partagent jamais le même espace : le portail est le seul
## pont, ce qui protège le manoir de la gravité par face du cube.

@export var scene_cible: String = ""
@export var ouvert_au_depart := false

const HAUTEUR_OUVERTURE := 2.3
const DUREE_OUVERTURE := 0.6

var ouvert := false

@onready var panneau: StaticBody3D = $Panneau
@onready var zone: Area3D = $Zone


func _ready() -> void:
	zone.body_entered.connect(_on_corps_entre)
	if ouvert_au_depart:
		ouvre()


## La porte coulisse vers le haut et libère le passage — comme les portes du
## manoir, jamais un panneau qui disparaît d'un coup.
func ouvre() -> void:
	ouvert = true
	panneau.get_node("CollisionShape3D").set_deferred("disabled", true)
	var glisse := create_tween()
	glisse.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	glisse.tween_property(panneau, "position:y",
		panneau.position.y + HAUTEUR_OUVERTURE, DUREE_OUVERTURE)


func _on_corps_entre(corps: Node3D) -> void:
	# Changer de scène est différé : on est dans un retour de physique, et libérer
	# la scène (donc des corps de collision) en plein callback est interdit.
	if ouvert and scene_cible != "" and corps is CharacterBody3D:
		get_tree().call_deferred("change_scene_to_file", scene_cible)
