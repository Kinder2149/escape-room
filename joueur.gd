extends CharacterBody3D

## Joueur en vue première personne : ZQSD pour se déplacer, souris pour regarder,
## E pour agir sur ce qu'on vise. Une fois caché dans un meuble, il ne se déplace
## plus et ne voit que par une fente : le regard est bridé autour de son axe.

## Émis quand ce que le joueur peut faire change. Texte vide = rien à faire.
signal cible_changee(texte: String)
## Émis quand le joueur entre dans une cachette ou en ressort.
signal cache_change(est_cache: bool)

const VITESSE := 4.5
const SENSIBILITE_SOURIS := 0.0025
const ANGLE_VERTICAL_MAX := deg_to_rad(89.0)

## Débattement du regard une fois glissé dans un meuble : juste de quoi balayer
## la fente, pas de quoi se retourner.
const ANGLE_CACHE_H := deg_to_rad(22.0)
const ANGLE_CACHE_V := deg_to_rad(14.0)
## Hauteur des yeux : sert à poser le corps pour que la caméra tombe pile
## sur le point de vue de la cachette.
const HAUTEUR_YEUX := 1.6

@onready var camera: Camera3D = $Camera3D
@onready var visee: RayCast3D = $Camera3D/Visee
@onready var torche: SpotLight3D = $Camera3D/Torche

var cible: Node3D = null
var dernier_texte := ""
var cachette: Node3D = null
var cap_cachette := 0.0
## La fouille en cours (jet 13) : le coffre qu'on ouvre, le temps qu'il reste
## avant que le couvercle bascule, et la durée totale (pour la barre à l'écran).
## Pendant ce temps le joueur est cloué, le regard fixe, mais un pas l'annule.
var fouille_cible: Node3D = null
var fouille_reste := 0.0
var fouille_duree := 0.0


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	visee.add_exception(self)


func est_cache() -> bool:
	return cachette != null


## Fouille-t-il un coffre en ce moment ? Cloué, le regard fixe, mais libre de
## tout annuler d'un pas — c'est ce qui rend l'exposition un choix, pas un piège.
func est_en_fouille() -> bool:
	return fouille_cible != null


## Où en est la fouille, de 0 (tout juste commencée) à 1 (le coffre s'ouvre).
## La barre à l'écran s'en sert pour montrer que l'ouverture est en cours.
func fouille_fraction() -> float:
	if fouille_duree <= 0.0:
		return 0.0
	return clampf(1.0 - fouille_reste / fouille_duree, 0.0, 1.0)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if est_cache():
			regarde_par_la_fente(event.relative)
		elif est_en_fouille():
			pass  # Regard fixe : le danger se lit à l'oreille, pas à l'œil.
		else:
			regarde(event.relative)
	elif event.is_action_pressed("agir"):
		if est_cache():
			sors_de_cachette()
		elif est_en_fouille():
			pass  # La touche est inerte pendant la fouille ; seul un pas l'annule.
		elif cible != null:
			commence_ou_agit(cible)
	elif event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func regarde(mouvement: Vector2) -> void:
	rotate_y(-mouvement.x * SENSIBILITE_SOURIS)
	camera.rotation.x = clamp(
		camera.rotation.x - mouvement.y * SENSIBILITE_SOURIS,
		-ANGLE_VERTICAL_MAX,
		ANGLE_VERTICAL_MAX
	)


## Caché, on ne tourne que de quelques degrés autour de l'axe du meuble.
func regarde_par_la_fente(mouvement: Vector2) -> void:
	var voulu := rotation.y - mouvement.x * SENSIBILITE_SOURIS
	var ecart := angle_difference(cap_cachette, voulu)
	rotation.y = cap_cachette + clamp(ecart, -ANGLE_CACHE_H, ANGLE_CACHE_H)
	camera.rotation.x = clamp(
		camera.rotation.x - mouvement.y * SENSIBILITE_SOURIS,
		-ANGLE_CACHE_V,
		ANGLE_CACHE_V
	)


func entre_dans_cachette(ou: Node3D) -> void:
	if est_cache():
		return
	cachette = ou
	ou.occupee = true
	set_physics_process(false)
	velocity = Vector3.ZERO

	var vue: Transform3D = ou.point_de_vue.global_transform
	# Le corps est posé de sorte que les yeux tombent pile sur le point de vue.
	global_position = vue.origin - Vector3.UP * HAUTEUR_YEUX
	cap_cachette = vue.basis.get_euler().y
	rotation.y = cap_cachette
	camera.rotation.x = 0.0

	cible = null
	dernier_texte = ""
	cible_changee.emit("")
	cache_change.emit(true)


func sors_de_cachette() -> void:
	if not est_cache():
		return
	var sortie: Transform3D = cachette.point_de_sortie.global_transform
	cachette.occupee = false
	cachette = null

	global_position = sortie.origin
	rotation.y = sortie.basis.get_euler().y
	camera.rotation.x = 0.0

	set_physics_process(true)
	cache_change.emit(false)


## Agir sur ce qu'on vise. Si l'objet demande une fouille (ouvrir un coffre,
## prendre son contenu), le geste cloue le joueur le temps qu'elle dure et
## n'aboutit qu'à la fin ; sinon il est instantané (se cacher, la porte).
func commence_ou_agit(sur_qui: Node3D) -> void:
	var duree: float = sur_qui.duree_fouille() if sur_qui.has_method("duree_fouille") else 0.0
	if duree > 0.0:
		fouille_cible = sur_qui
		fouille_reste = duree
		fouille_duree = duree
	else:
		sur_qui.agir()
		maj_visee()


## Un pas suffit à décrocher : la fouille est abandonnée, le coffre reste fermé
## ou l'objet non pris. On retrouve la main immédiatement pour fuir.
func annule_fouille() -> void:
	fouille_cible = null
	fouille_reste = 0.0


## La fouille est allée à son terme : le geste aboutit enfin — le coffre s'ouvre
## ou l'objet est pris.
func termine_fouille() -> void:
	var abouti: Node3D = fouille_cible
	fouille_cible = null
	fouille_reste = 0.0
	if abouti != null:
		abouti.agir()
	maj_visee()


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	var saisie := Input.get_vector("gauche", "droite", "avancer", "reculer")

	# Cloué le temps de la fouille — mais un pas la rompt et rend la main aussitôt.
	# On repart les mains vides : c'est le coût de décrocher.
	if est_en_fouille():
		if saisie.length() > 0.0:
			annule_fouille()
		else:
			fouille_reste -= delta
			velocity.x = 0.0
			velocity.z = 0.0
			move_and_slide()
			if fouille_reste <= 0.0:
				termine_fouille()
			return

	var direction := (transform.basis * Vector3(saisie.x, 0.0, saisie.y)).normalized()
	velocity.x = direction.x * VITESSE
	velocity.z = direction.z * VITESSE

	move_and_slide()
	maj_visee()


## Regarde ce qui est dans la ligne de mire et signale ce qu'on peut en faire.
func maj_visee() -> void:
	cible = null
	if visee.is_colliding():
		var touche := visee.get_collider()
		if touche != null and touche.has_method("texte_action") and touche.has_method("agir"):
			cible = touche

	var texte: String = "" if cible == null else cible.texte_action()
	if texte == "":
		cible = null
	if texte != dernier_texte:
		dernier_texte = texte
		cible_changee.emit(texte)
