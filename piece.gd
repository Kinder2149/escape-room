extends Node3D

## Une pièce de la maison : la source unique de ses emplacements.
## Le nom du nœud est le nom de la pièce. Les trois repères disent où se pose
## un coffre, où s'ouvre la porte rouge, où l'on se réveille — position ET
## orientation, visibles dans l'éditeur.
##
## Conventions d'orientation (le -Z du repère est son « devant ») :
##  - un coffre présente sa face avant au joueur ;
##  - la porte rouge regarde vers l'intérieur de sa pièce ;
##  - le réveil regarde vers l'intérieur de la maison, jamais vers le mur.
##
## Le Jeu et le Rôdeur interrogent les pièces (groupe « pieces ») : aucune
## coordonnée de pièce ne doit vivre ailleurs que dans maison.tscn.

@onready var coffre: Marker3D = $Coffre
@onready var sortie: Marker3D = $Sortie
@onready var reveil: Marker3D = $Reveil
@onready var plaque: Label3D = $Plaque

## Le nom lisible de la pièce, réglé par pièce (« Salle à manger ») : le nom du
## nœud est en CamelCase sans accent, impropre à l'affichage. Vide → on retombe
## sur le nom du nœud, le temps qu'il soit renseigné.
@export var nom_affiche := ""


func _ready() -> void:
	plaque.text = nom_affiche if nom_affiche != "" else String(name)
