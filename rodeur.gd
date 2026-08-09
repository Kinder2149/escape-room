extends CharacterBody3D

## Le rôdeur. Il patrouille lentement de pièce en pièce, au hasard.
## S'il aperçoit le joueur dans le cône de sa torche, il le poursuit tant qu'il
## le voit. Perdu de vue, il fonce vers sa dernière position connue et cherche
## quelques secondes avant d'abandonner. S'il le touche, c'est perdu.

signal joueur_attrape
## Émis quand il repère le joueur : porte sa position, que le Jeu relaie à
## l'autre rôdeur pour l'étau (jet 14).
signal repere_le_joueur(ou: Vector3)

const VITESSE_MARCHE := 2.0
## Jamais plus rapide que le joueur (4.5) : on prend de l'avance en ligne droite.
## Mais courir ne suffit pas — il ne lâche que si on lui échappe du regard.
const VITESSE_POURSUITE := 4.0
## Il ne le voit plus mais suit encore sa piste : il ne sprinte plus après une
## ombre, il traque. C'est ce qui rend une rupture de vue payante.
const VITESSE_TRAQUE := 3.0
## Le temps qu'il marque, immobile, à l'instant où il perd sa trace.
const DUREE_HESITATION := 0.6
const VITESSE_ROTATION := 6.0

## Combien de temps il met à rejoindre le point de fuite présumé avant de
## lancer la battue.
const DUREE_RECHERCHE := 4.0
## Jusqu'où il prolonge la course du joueur quand il le perd de vue. Il ne
## s'arrête pas là où il l'a aperçu pour la dernière fois : il continue dans
## la direction où il le voyait courir. C'est ce qui fait la différence entre
## chercher et fouiller au hasard.
const DISTANCE_EXTRAPOLATION := 6.0

## LA BATTUE — il a perdu le joueur, mais il sait qu'il est dans le coin.
## Il ratisse : la pièce où il l'a vu disparaître, puis les plus proches.
## Combien de pièces il fouille avant de renoncer.
const PIECES_A_FOUILLER := 3
## Le temps qu'il passe planté au cœur de chaque pièce, à balayer du regard.
const DUREE_FOUILLE := 4.0
## Le plafond : passé ce délai il renonce, même s'il n'a pas tout fouillé.
## Sans lui, une battue s'éterniserait dans un manoir plein de recoins.
const DUREE_BATTUE := 30.0
## Jusqu'où s'étend « le coin » : une pièce plus loin que ça, en marchant,
## n'est plus un voisinage plausible. Aucune liste de voisins n'est écrite
## nulle part — le voisinage se déduit, sinon il faudrait le tenir à jour
## à chaque pièce ajoutée.
const RAYON_BATTUE := 20.0
## En deçà de cet écart d'altitude, deux endroits sont au même niveau.
const ECART_MEME_NIVEAU := 1.5
## À quelle vitesse il balaie du regard, planté au cœur d'une pièce.
const VITESSE_BALAYAGE := 0.9
## À quelle distance d'une cachette il l'ouvre. Il vise le point de sortie du
## meuble, donc là où le joueur se tiendrait s'il en ressortait.
const DISTANCE_OUVERTURE := 1.0

## En deçà, l'écart au point suivant est trop court pour en tirer une direction.
const DISTANCE_DIRECTION_FIABLE := 0.1

const PORTEE_VUE := 10.0
const DEMI_ANGLE_VUE := 25.0
## À bout portant, un cône de 25° ne couvre plus rien : à 1 m il ne protège que
## 50 cm de côté. En deçà de ce rayon, il repère le joueur quel que soit l'angle.
const RAYON_PROXIMITE := 2.0
const DISTANCE_CONTACT := 0.9
## À portée et à vue, il lâche la carte de navigation et fonce droit sur le
## joueur. Sans ça, il reste bloqué à la limite de ce que la carte autorise —
## 0,55 m des murs — pendant que le joueur, lui, peut s'y coller. Collé dans
## un angle, on devenait intouchable et le rôdeur piétinait à côté.
const DISTANCE_CHARGE := 2.5
const HAUTEUR_TORSE := 1.0

## L'ÉTAU (jet 14) — un rôdeur qui voit le joueur prévient l'autre. Le prévenu ne
## rejoint que s'il peut arriver à temps pour servir : au plus
## (BUDGET_ALERTE - MARGE_ALERTE) × VITESSE_TRAQUE mètres de marche, soit 18 m.
## Le budget se recharge tant qu'on voit le joueur ; épuisé, le rôdeur rentre.
const BUDGET_ALERTE := 10.0
const MARGE_ALERTE := 4.0

@onready var agent: NavigationAgent3D = $NavigationAgent3D
@onready var torche: SpotLight3D = $Torche
## Le lecteur d'animation n'existe que si le modèle en a un : la silhouette
## d'origine n'en a pas, le pantin incarné oui. Le script accepte les deux.
@onready var animations: AnimationPlayer = trouve_animations()


func trouve_animations() -> AnimationPlayer:
	for enfant in $Modele.get_children():
		if enfant is AnimationPlayer:
			return enfant
	return null


func _ready() -> void:
	if animations == null:
		return
	# Les animations arrivent en « une seule fois » : sans ça, le rôdeur fait
	# un pas puis se fige.
	for nom in animations.get_animation_list():
		animations.get_animation(nom).loop_mode = Animation.LOOP_LINEAR
	animations.play("Marche")

var joueur: CharacterBody3D = null
## Les pièces de SON niveau : sa ronde, et là où il rentre après avoir renoncé.
## C'est ce qui fait qu'il « appartient » à un étage sans que rien ne le déclare.
var destinations := {}
## Toutes les pièces du manoir : il n'y touche que pour ratisser le niveau où
## il vient de perdre la trace — même si ce n'est pas le sien.
var toutes_les_pieces := {}
var piece_visee := ""
## La pièce du réveil du joueur, à éviter tant qu'il ne s'est pas réellement
## éloigné de son point de départ. Le critère est la distance parcourue, et
## non « une route est calculée » : l'agent se déclare « arrivé » par
## intermittence dans les premières images, et chacun de ces re-tirages
## pouvait envoyer le rôdeur droit sur le joueur.
var piece_a_eviter := ""
var depart_ronde := Vector3.ZERO
## Ce qu'il doit avoir parcouru pour que la protection du réveil soit levée.
const DISTANCE_FIN_PROTECTION := 3.0
var actif := false
var en_poursuite := false
## Le dernier mètre : il fonce droit sur le joueur, hors carte.
var charge := false
## L'ÉTAU (jet 14) : prévenu par l'autre, il converge vers un point de contact.
var en_alerte := false
var cible_alerte := Vector3.ZERO
var temps_alerte := 0.0
## Il a perdu le joueur et ratisse la zone, pièce par pièce.
var en_battue := false
var ancre_battue := Vector3.ZERO
## L'étage sur lequel se déroule la battue en cours : celui de la fuite.
var niveau_battue := 0.0
var pieces_fouillees: Array = []
var temps_battue := 0.0
var temps_sur_place := 0.0
var temps_sans_voir := 0.0
## Dans quelle direction il le voyait courir au dernier instant. Vide s'il
## était à l'arrêt : on n'extrapole pas une course qui n'existait pas.
var direction_de_fuite := Vector3.ZERO
var fuite_extrapolee := false
## La maison, reçue au démarrage : elle sait mesurer une distance de marche.
var maison: Node3D = null
var derniere_position_connue := Vector3.ZERO
## Le meuble où il a vu le joueur se glisser. Le seul qu'il ouvrira jamais.
var cachette_reperee: Node3D = null


func demarre(cible: CharacterBody3D, points_de_son_niveau: Dictionary,
		points_du_manoir: Dictionary, piece_du_reveil := "",
		la_maison: Node3D = null) -> void:
	joueur = cible
	destinations = points_de_son_niveau
	toutes_les_pieces = points_du_manoir
	maison = la_maison
	actif = true
	# Sa première ronde évite la pièce du réveil : le tirage garantit un départ
	# lointain, ceci garantit qu'il ne marche pas droit sur le joueur dans la
	# foulée. Dès la ronde suivante, toutes les pièces redeviennent son terrain.
	piece_a_eviter = piece_du_reveil
	depart_ronde = global_position
	choisis_piece()


## Il ne tire jamais deux fois la même pièce de suite.
func choisis_piece() -> void:
	var pieces := destinations.keys()
	pieces.erase(piece_visee)
	if piece_a_eviter != "":
		pieces.erase(piece_a_eviter)
	piece_visee = pieces.pick_random()
	agent.target_position = destinations[piece_visee]


## Le sas d'intro rejoint le monde du rôdeur une fois ses portes ouvertes
## (jet 16) : il entre dans le ratissage de TOUS, et dans la ronde de ceux dont
## c'est l'étage. Avant la clé, il en était exclu pour qu'aucun rôdeur ne fonce
## se coincer contre la porte verrouillée.
func reintegre(nom: String, pos: Vector3, plain_pied: bool) -> void:
	toutes_les_pieces[nom] = pos
	if _ma_ronde_est_de_plain_pied() == plain_pied:
		destinations[nom] = pos


## Mon étage, lu sur ma ronde : mes destinations sont toutes d'un même niveau.
func _ma_ronde_est_de_plain_pied() -> bool:
	for point in destinations.values():
		return point.y < 1.0
	return false


func _physics_process(delta: float) -> void:
	if not actif:
		return
	if not is_on_floor():
		velocity += get_gravity() * delta

	if cachette_reperee != null:
		fonce_sur_cachette()
	elif en_poursuite:
		poursuit(delta)
	elif en_battue:
		bat_la_zone(delta)
	elif en_alerte:
		converge(delta)
	else:
		if piece_a_eviter != "" \
				and global_position.distance_to(depart_ronde) > DISTANCE_FIN_PROTECTION:
			# Il s'est vraiment éloigné : sa ronde a commencé, tout le manoir
			# redevient son terrain.
			piece_a_eviter = ""
		if agent.is_navigation_finished():
			choisis_piece()
		if voit_joueur():
			commence_poursuite()

	avance(delta, allure())
	maj_demarche()


## Sa démarche raconte ce qu'il fait : il marche en ronde, court après une
## proie qu'il voit, et se fige à guetter quand il fouille une pièce.
## Elle se lit sur sa vitesse réelle, pas sur son état : c'est la vitesse que
## le joueur voit, et elle reste juste quel que soit le détour du code.
const VITESSE_COURSE_MINI := 3.5
const VITESSE_ARRET := 0.2

func maj_demarche() -> void:
	if animations == null:
		return
	var vitesse := Vector2(velocity.x, velocity.z).length()
	var voulue := "Marche"
	var cadence := 1.0
	if vitesse < VITESSE_ARRET:
		voulue = "Guet"
	elif vitesse > VITESSE_COURSE_MINI:
		voulue = "Course"
		cadence = vitesse / VITESSE_POURSUITE
	else:
		# Le pas suit l'allure : sans ça il glisse au sol quand il traque.
		cadence = clampf(vitesse / VITESSE_MARCHE, 0.6, 1.8)
	if animations.current_animation != voulue:
		animations.play(voulue)
	animations.speed_scale = cadence


## Il ne court à fond que sur une proie qu'il voit — ou sur le meuble où il
## l'a vue se glisser. Dès qu'il perd sa trace il ralentit : il marque un
## temps, puis traque, puis ratisse au pas. C'est ce qui laisse une chance de
## le semer, et le temps de le voir passer depuis un meuble.
func allure() -> float:
	if cachette_reperee != null:
		return VITESSE_POURSUITE
	if en_alerte:
		return VITESSE_TRAQUE
	if not en_poursuite:
		return VITESSE_MARCHE
	if is_zero_approx(temps_sans_voir):
		return VITESSE_POURSUITE
	if temps_sans_voir < DUREE_HESITATION:
		return 0.0
	return VITESSE_TRAQUE


func commence_poursuite() -> void:
	en_poursuite = true
	en_battue = false
	en_alerte = false
	temps_sans_voir = 0.0
	fuite_extrapolee = false
	garde_la_trace()
	repere_le_joueur.emit(joueur.global_position)


func poursuit(delta: float) -> void:
	# Un joueur glissé dans un meuble ne s'attrape pas au corps à corps : il
	# n'existe plus pour lui, même s'il le frôle en fouillant. Seul
	# « a_vu_entrer » le trahit.
	if not joueur.est_cache() \
			and global_position.distance_to(joueur.global_position) < DISTANCE_CONTACT:
		joueur_attrape.emit()
		return

	# La charge ne dépend PAS du cône de la torche : à deux pas, sans rien
	# entre eux, il fonce — même si son regard a glissé de côté une image.
	# Sinon un simple angle mort le faisait renoncer alors qu'il le touchait
	# presque, et se blottir dans un recoin suffisait à devenir intouchable.
	charge = not joueur.est_cache() \
		and global_position.distance_to(joueur.global_position) < DISTANCE_CHARGE \
		and rien_entre(torche.global_position,
			joueur.global_position + Vector3.UP * HAUTEUR_TORSE, joueur)

	if voit_joueur():
		# Tant qu'il le voit, il ne lâche rien.
		temps_sans_voir = 0.0
		garde_la_trace()
		return

	if charge:
		# Il l'a sous le nez : ce n'est pas le moment d'aller fouiller ailleurs.
		temps_sans_voir = 0.0
		return

	# Premier instant sans le voir : il ne s'arrête pas où il l'a aperçu, il
	# file là où la course du joueur le menait.
	if not fuite_extrapolee:
		fuite_extrapolee = true
		agent.target_position = fuite_presumee()

	temps_sans_voir += delta
	# « Chemin terminé » ne veut dire « je suis arrivé » que s'il a vraiment
	# marché. Quand la cible est hors de la carte — un joueur plaqué contre un
	# mur — l'agent l'annonce dès la première image, et il renonçait aussitôt.
	if temps_sans_voir >= DUREE_RECHERCHE \
			or (agent.is_navigation_finished() and temps_sans_voir > DUREE_HESITATION):
		commence_battue()


## Là où sa course le menait. Un joueur vu en train de fuir vers le nord n'est
## pas resté sur le pas de la porte : il est plus loin, au nord. Sans ça, le
## rôdeur fouille au plus près de lui — et part souvent à l'opposé.
func fuite_presumee() -> Vector3:
	if direction_de_fuite == Vector3.ZERO:
		return derniere_position_connue
	var vise := derniere_position_connue + direction_de_fuite * DISTANCE_EXTRAPOLATION
	# Ramené sur le sol praticable : une course peut pointer vers un mur.
	return NavigationServer3D.map_get_closest_point(agent.get_navigation_map(), vise)


## Il a perdu le joueur, mais il sait qu'il était là il y a trois secondes :
## il ne repart pas en ronde, il ratisse. La pièce où le joueur s'est
## volatilisé d'abord, puis les plus proches en marchant.
func commence_battue() -> void:
	en_poursuite = false
	en_battue = true
	# La battue s'organise autour de l'endroit où il CROIT le joueur — au bout
	# de sa fuite — et non autour du dernier point de contact.
	ancre_battue = fuite_presumee()
	niveau_battue = niveau_de(ancre_battue)
	pieces_fouillees = []
	temps_battue = 0.0
	fouille_suivante()


## L'étage d'un endroit : celui de la pièce la plus proche en marchant. Sert à
## ratisser LÀ OÙ LE JOUEUR A FUI — et non là où le rôdeur se tient. Sans ça,
## perdre sa trace en haut d'un escalier le clouait à l'étage du haut, et
## changer de niveau suffisait à le semer.
func niveau_de(endroit: Vector3) -> float:
	var niveau := endroit.y
	var ecart := INF
	for nom in toutes_les_pieces:
		var distance := distance_de_marche(endroit, toutes_les_pieces[nom])
		if distance < ecart:
			ecart = distance
			niveau = toutes_les_pieces[nom].y
	return niveau


func bat_la_zone(delta: float) -> void:
	# Le revoir relance tout : la battue n'est qu'un pis-aller.
	if voit_joueur():
		commence_poursuite()
		return

	temps_battue += delta
	if temps_battue >= DUREE_BATTUE:
		abandonne()
		return

	if agent.is_navigation_finished():
		# Planté au cœur de la pièce, il balaie lentement de sa torche.
		temps_sur_place += delta
		rotation.y += VITESSE_BALAYAGE * delta
		if temps_sur_place >= DUREE_FOUILLE:
			fouille_suivante()


## Au suivant. Plus rien à fouiller dans le coin : il renonce.
func fouille_suivante() -> void:
	temps_sur_place = 0.0
	var piece := piece_a_fouiller()
	if piece == "":
		abandonne()
		return
	pieces_fouillees.append(piece)
	agent.target_position = toutes_les_pieces[piece]


## La pièce non encore fouillée la plus plausible : la plus proche de l'endroit
## où il croit le joueur — pas la plus proche de LUI, sinon il commence par
## fouiller ce qu'il a dans le dos. Mesuré en marchant, jamais à vol d'oiseau :
## un mur ferait passer pour voisine une pièce à l'autre bout du manoir.
##
## Une battue ne franchit JAMAIS les étages : il ratisse le niveau où il vient
## de perdre la trace — le sien, ou celui où il a suivi le joueur — puis rentre
## chez lui (voir abandonne). Sans cette borne, les deux rôdeurs finiraient
## mélangés et les niveaux ne voudraient plus rien dire.
func piece_a_fouiller() -> String:
	if pieces_fouillees.size() >= PIECES_A_FOUILLER:
		return ""
	var meilleure := ""
	var ecart := INF
	for nom in toutes_les_pieces:
		if nom in pieces_fouillees:
			continue
		var ou: Vector3 = toutes_les_pieces[nom]
		if absf(ou.y - niveau_battue) > ECART_MEME_NIVEAU:
			continue
		var distance := distance_de_marche(ancre_battue, ou)
		if distance > RAYON_BATTUE:
			continue
		if distance < ecart:
			ecart = distance
			meilleure = nom
	return meilleure


func distance_de_marche(depuis: Vector3, vers: Vector3) -> float:
	return maison.distance_de_marche(depuis, vers)


## Mémorise où est le joueur et s'y dirige, sans relancer un calcul de chemin
## à chaque frame.
func garde_la_trace() -> void:
	# On retient aussi vers où il court : c'est cette direction, et non le
	# seul point de contact, qui dira où le chercher une fois disparu.
	var course := joueur.velocity
	course.y = 0.0
	direction_de_fuite = course.normalized() if course.length() > 0.5 else Vector3.ZERO

	var p := joueur.global_position
	if p.distance_to(derniere_position_connue) > 0.5:
		derniere_position_connue = p
		agent.target_position = p
		# L'étau, suivi vivant (jet 14, étape 2) : tant qu'on voit le joueur, on
		# transmet sa position à l'autre rôdeur — il suit le mouvement au lieu de
		# foncer sur le point de départ, et son budget d'alerte se recharge.
		repere_le_joueur.emit(p)


func abandonne() -> void:
	en_poursuite = false
	en_battue = false
	charge = false
	choisis_piece()


## L'ÉTAU — prévenu par l'autre rôdeur (relais dans jeu.gd) : le joueur a été vu
## là-bas. On ne s'en mêle que si l'on est tranquille en ronde, et seulement si
## l'on peut arriver à temps pour être utile — sinon on reste sur sa ronde. Déjà
## alerté, on rafraîchit la cible et on recharge le budget.
func recois_alerte(ou: Vector3) -> void:
	if not actif or en_poursuite or en_battue or cachette_reperee != null:
		return
	if not en_alerte:
		var distance := distance_de_marche(global_position, ou)
		if distance > (BUDGET_ALERTE - MARGE_ALERTE) * VITESSE_TRAQUE:
			return
		en_alerte = true
	cible_alerte = ou
	temps_alerte = BUDGET_ALERTE
	agent.target_position = ou


## Il converge vers le point de contact à l'allure de traque. Le joueur en vue,
## c'est une vraie poursuite. Sinon, le budget épuisé, il reprend sa ronde.
func converge(delta: float) -> void:
	if voit_joueur():
		commence_poursuite()
		return
	temps_alerte -= delta
	if temps_alerte <= 0.0:
		fin_alerte()


## Budget épuisé sans avoir retrouvé le joueur : il lâche l'étau et reprend sa
## ronde — qui puise dans les pièces de son étage, donc le ramène chez lui.
func fin_alerte() -> void:
	en_alerte = false
	choisis_piece()


## Le joueur s'est glissé dans un meuble sous ses yeux : il sait où il est,
## et il va l'y chercher. Il n'abandonne pas — inutile de compter les secondes.
func a_vu_entrer(cachette: Node3D) -> void:
	cachette_reperee = cachette
	en_poursuite = false
	agent.target_position = cachette.point_de_sortie.global_position


## Le joueur est ressorti de lui-même : le meuble n'a plus d'intérêt.
func oublie_cachette() -> void:
	cachette_reperee = null
	choisis_piece()


func fonce_sur_cachette() -> void:
	var devant: Vector3 = cachette_reperee.point_de_sortie.global_position
	if global_position.distance_to(devant) < DISTANCE_OUVERTURE:
		joueur_attrape.emit()
		return
	agent.target_position = devant


func avance(delta: float, vitesse: float) -> void:
	var ecart: Vector3
	if charge:
		# Droit sur lui, sans passer par la carte. C'est move_and_slide qui
		# gère les murs : il les longe au lieu de s'arrêter à distance.
		ecart = joueur.global_position - global_position
	elif agent.is_navigation_finished():
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		return
	else:
		ecart = agent.get_next_path_position() - global_position
	ecart.y = 0.0

	# Collé au point suivant, la direction n'est plus que du bruit : on garde
	# le cap au lieu de pivoter dans le vide.
	if ecart.length() < DISTANCE_DIRECTION_FIABLE:
		move_and_slide()
		return

	var direction := ecart.normalized()
	velocity.x = direction.x * vitesse
	velocity.z = direction.z * vitesse
	move_and_slide()

	# Se tourner vers là où il marche : sa torche doit éclairer devant lui.
	var vise := atan2(-direction.x, -direction.z)
	rotation.y = lerp_angle(rotation.y, vise, VITESSE_ROTATION * delta)


## Le joueur est vu s'il est à portée, sans obstacle, et soit dans le cône de la
## torche, soit assez près pour être remarqué quel que soit l'angle.
func voit_joueur() -> bool:
	if joueur == null:
		return false
	# Glissé dans un meuble, le joueur n'existe plus pour lui : sa torche peut
	# le balayer de tout près, il ne verra rien. Seul « a_vu_entrer » le trahit.
	if joueur.est_cache():
		return false

	var depuis := torche.global_position
	var vers := joueur.global_position + Vector3.UP * HAUTEUR_TORSE
	var ecart := vers - depuis
	var distance := ecart.length()
	if distance > PORTEE_VUE:
		return false

	# Au-delà de la bulle de perception, seul le cône de la torche compte.
	# L'angle se mesure À PLAT : mesuré en 3D, un joueur qui dévale un escalier
	# sort du cône en une seconde — descendre d'un étage suffisait à le semer.
	# La hauteur reste bornée par la portée et par les murs.
	if distance > RAYON_PROXIMITE:
		var regard := -global_transform.basis.z
		var vers_lui := ecart
		regard.y = 0.0
		vers_lui.y = 0.0
		if regard.length() < 0.01 or vers_lui.length() < 0.01:
			return false
		if rad_to_deg(regard.normalized().angle_to(vers_lui.normalized())) > DEMI_ANGLE_VUE:
			return false

	return rien_entre(depuis, vers, joueur)


## Depuis ce point de départ, finirait-il par voir quelqu'un posé là-bas ?
## Portée et obstacles de voit_joueur, mais sans le cône : en patrouille il
## pivote, sa torche finit toujours par balayer la ligne. Sert au tirage,
## pour ne jamais commencer une partie sous son regard.
func verrait_depuis(pied_rodeur: Vector3, cible: CharacterBody3D) -> bool:
	var depuis := pied_rodeur + Vector3.UP * torche.position.y
	var vers := cible.global_position + Vector3.UP * HAUTEUR_TORSE
	if depuis.distance_to(vers) > PORTEE_VUE:
		return false
	return rien_entre(depuis, vers, cible)


## Un mur — ou un meuble — entre les deux, et il ne voit rien, même de tout près.
## On ne regarde que le calque 1 : les zones de visée des cachettes (calque 2)
## ne sont pas des obstacles, elles lui cacheraient le joueur pour rien.
## La cible est exclue du rayon : elle est le point d'arrivée, pas un obstacle.
func rien_entre(depuis: Vector3, vers: Vector3, cible: CharacterBody3D) -> bool:
	var params := PhysicsRayQueryParameters3D.create(depuis, vers, 1, [get_rid(), cible.get_rid()])
	return get_world_3d().direct_space_state.intersect_ray(params).is_empty()
