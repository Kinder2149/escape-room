extends StaticBody3D

## Un meuble où se glisser. La cachette ne fait que se proposer : c'est le Jeu
## qui décide, et le Joueur qui porte l'état « caché ».
##
## Repère local : la face qu'on vise regarde vers -Z.
## Les neuf meubles n'ayant ni la même taille ni la même posture, tout se règle
## ici plutôt que dans neuf scènes séparées.

signal entree_demandee(cachette: Node3D)

## La plaque qu'on vise vit sur son propre calque : le corps du joueur la
## traverse, seule sa visée la voit. Elle peut donc être bien plus large que le
## meuble — sans quoi on se cognerait dans du vide devant une baignoire.
const CALQUE_VISEE := 2

## À partir de quelle distance le repère se montre.
const DISTANCE_REPERE := 4.5

## La zone qu'on vise pour se cacher. Elle n'a pas à épouser le meuble : mieux
## vaut large, sinon il faut chercher l'angle exact pour entrer.
@export var largeur_face := 1.5
@export var hauteur_face := 1.9

## Hauteur des yeux une fois planqué : debout dans une armoire, la tête juste
## au-dessus d'un dossier de canapé, au ras du sol sous un bureau.
@export var hauteur_vue := 1.5

## Où se met le point de vue par rapport à la face, le long du regard.
## Positif = devant le meuble (les meubles sont des blocs pleins : une caméra
## à l'intérieur ne verrait que du noir, c'est le masque qui fait l'illusion).
## Négatif = derrière le meuble, pour ce qui se contourne plutôt que s'ouvre.
@export var decalage_vue := 0.06

## À quelle distance devant le meuble le joueur réapparaît en sortant.
@export var recul_sortie := 0.5

@onready var point_de_vue: Marker3D = $PointDeVue
@onready var point_de_sortie: Marker3D = $PointDeSortie
@onready var repere: Label3D = $Repere

## Renseigné par le Jeu : sert à savoir quand montrer le repère.
var joueur: Node3D = null
var occupee := false


func _ready() -> void:
	collision_layer = CALQUE_VISEE
	collision_mask = 0

	var forme := BoxShape3D.new()
	forme.size = Vector3(largeur_face, hauteur_face, 0.04)
	$CollisionShape3D.shape = forme
	$CollisionShape3D.position = Vector3(0.0, hauteur_face / 2.0, 0.0)

	point_de_vue.position = Vector3(0.0, hauteur_vue, -decalage_vue)
	point_de_sortie.position = Vector3(0.0, 0.0, -recul_sortie)
	repere.position = Vector3(0.0, hauteur_face * 0.5, -0.08)
	repere.hide()


func _process(_delta: float) -> void:
	if joueur == null:
		return
	# Le repère ne s'allume qu'à courte distance : de plus loin, il trahirait
	# les neuf cachettes d'un coup et tuerait la pénombre.
	repere.visible = not occupee \
		and global_position.distance_to(joueur.global_position) < DISTANCE_REPERE


func texte_action() -> String:
	return "" if occupee else "Se cacher"


func agir() -> void:
	if occupee:
		return
	entree_demandee.emit(self)
