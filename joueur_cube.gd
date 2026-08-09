extends CharacterBody3D

# Le joueur du QUARTIER DE JEUX (zone cube, à part du manoir — jet cube).
# Contrôleur bâti autour d'un "vecteur bas" propre au joueur. En marchant vers le
# bord d'une face, on bascule de 90deg sur la face voisine : la vue tourne AUTOUR
# DE L'OEIL (qui reste fixe dans l'espace) pour ne pas donner la nausée, puis la
# nouvelle gravité pose le joueur sur la face voisine.
# Porté tel quel depuis le prototype cube3D (validé "super clean").

@export var vitesse: float = 5.0
@export var gravite: float = 20.0
@export var sensibilite: float = 0.003
@export var demi_cube: float = 6.0            # demi-arete du cube (regle par le monde)

# Reglages du basculement (a affiner a l'etape 5).
@export var duree_bascule: float = 0.45       # duree de la bascule, en secondes
@export var marge_arete: float = 1.2          # a quelle distance du bord on declenche
const V_SEUIL: float = 0.5                    # vitesse mini vers le bord pour declencher

# Une OUVERTURE (couloir) : sur la face "ouverture_bas", en marchant vers le bord
# "ouverture_dir", on ne bascule PAS si l'on est aligne avec la porte (a moins de
# ouverture_demi_largeur de son axe). C'est ce qui laisse SORTIR du cube vers un
# couloir sans se retourner. Regle par le monde (quartier.gd) ; a zero, aucune
# ouverture (le cube nu du prototype).
@export var ouverture_bas: Vector3 = Vector3.ZERO
@export var ouverture_dir: Vector3 = Vector3.ZERO
@export var ouverture_demi_largeur: float = 0.0

# Le "bas" du joueur. Reste toujours aligne sur un axe (on ne tourne que par 90deg).
var bas: Vector3 = Vector3.DOWN

var pitch: float = 0.0

# Etat du basculement.
var en_basculement: bool = false
var t_bascule: float = 0.0
var axe_bascule: Vector3 = Vector3.ZERO
var pivot_bascule: Vector3 = Vector3.ZERO     # position de l'oeil, fixe pendant la bascule
var basis_depart: Basis
var origine_depart: Vector3
var bas_cible: Vector3 = Vector3.DOWN
var cooldown: float = 0.0

@onready var pivot_yaw: Node3D = $PivotYaw
@onready var camera: Camera3D = $PivotYaw/Camera3D

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	# On gele le regard pendant la bascule : seul le basculement fait tourner la vue.
	if en_basculement:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		pivot_yaw.rotate_object_local(Vector3.UP, -event.relative.x * sensibilite)
		pitch = clamp(pitch - event.relative.y * sensibilite, -1.4, 1.4)
		camera.rotation.x = pitch

func _physics_process(delta: float) -> void:
	if en_basculement:
		_animer_bascule(delta)
		return

	if cooldown > 0.0:
		cooldown -= delta

	var haut: Vector3 = -bas
	up_direction = haut

	# Gravite le long du vecteur bas.
	velocity += bas * gravite * delta

	# Deplacement relatif au regard, projete sur le plan de la face.
	var entree: Vector2 = Input.get_vector("gauche", "droite", "avancer", "reculer")
	var dir: Vector3 = pivot_yaw.global_transform.basis * Vector3(entree.x, 0.0, entree.y)
	dir = dir - haut * dir.dot(haut)
	if dir.length() > 0.001:
		dir = dir.normalized()

	var v_vertical: Vector3 = haut * velocity.dot(haut)
	var v_horizontal: Vector3 = dir * vitesse
	velocity = v_horizontal + v_vertical

	move_and_slide()

	if cooldown <= 0.0:
		_verifier_arete()

# Detecte si le joueur atteint un bord de sa face en marchant vers lui.
func _verifier_arete() -> void:
	for axe in [Vector3.RIGHT, Vector3.UP, Vector3.BACK]:
		if absf(bas.dot(axe)) > 0.5:
			continue  # cet axe est celui du bas : ce n'est pas une tangente
		var coord: float = global_position.dot(axe)
		var v: float = velocity.dot(axe)
		if coord > demi_cube - marge_arete and v > V_SEUIL:
			if not _ouverture_bloque(axe):
				_declencher_bascule(axe)
			return
		elif coord < -(demi_cube - marge_arete) and v < -V_SEUIL:
			if not _ouverture_bloque(-axe):
				_declencher_bascule(-axe)
			return


## Un couloir s'ouvre-t-il dans cette direction, ici ? Alors on ne bascule pas :
## on laisse passer le joueur (sortie ou entree du cube) sans le retourner.
func _ouverture_bloque(t: Vector3) -> bool:
	if ouverture_demi_largeur <= 0.0:
		return false
	if not bas.is_equal_approx(ouverture_bas):
		return false
	if not t.is_equal_approx(ouverture_dir):
		return false
	var perp: Vector3 = bas.cross(t).normalized()
	return absf(global_position.dot(perp)) < ouverture_demi_largeur

# t = direction (unitaire, axe) vers le bord franchi ; deviendra le nouveau bas.
func _declencher_bascule(t: Vector3) -> void:
	axe_bascule = bas.cross(t).normalized()
	bas_cible = t
	pivot_bascule = camera.global_position   # l'oeil reste fixe pendant la bascule
	basis_depart = global_transform.basis
	origine_depart = global_transform.origin
	t_bascule = 0.0
	en_basculement = true
	velocity = Vector3.ZERO

func _animer_bascule(delta: float) -> void:
	t_bascule += delta
	var p: float = clampf(t_bascule / duree_bascule, 0.0, 1.0)
	var lisse: float = p * p * (3.0 - 2.0 * p)   # accelere puis ralentit
	var angle: float = (PI / 2.0) * lisse
	var rot: Basis = Basis(axe_bascule, angle)

	var tf: Transform3D = global_transform
	tf.basis = rot * basis_depart
	tf.origin = pivot_bascule + rot * (origine_depart - pivot_bascule)
	global_transform = tf

	if p >= 1.0:
		# Fin de bascule : on remet la vue parfaitement droite pour que l'enchainement
		# de plusieurs faces ne cumule aucune imprecision (pas de monde qui "penche").
		tf.basis = tf.basis.orthonormalized()
		global_transform = tf
		bas = bas_cible
		en_basculement = false
		cooldown = 0.3
		velocity = Vector3.ZERO
