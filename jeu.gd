extends Node3D

## Gestionnaire de la partie : tirage au sort de la distribution à chaque
## lancement (porte rouge, coffres, réveil du joueur, départ du rôdeur),
## décompte des morceaux de clé, et ouverture de la porte rouge une fois
## les deux morceaux réunis. Attrapé → tout repart à zéro, nouveau tirage.
##
## Les pièces et leurs emplacements vivent dans la maison (scène Pièce,
## groupe « pieces ») : ici on tire et on pose, on ne connaît aucune coordonnée.

const MORCEAUX_REQUIS := 2
## En deçà de cette distance de marche (la vraie, en suivant portes et
## couloirs), un départ du rôdeur est trop proche : il pourrait être sur le
## joueur avant qu'il ait compris où il se réveille.
## Réglage de ressenti : à ajuster en jouant.
const DISTANCE_DEPART_MIN := 9.0
## Au-dessous de cette altitude, une pièce est de plain-pied. Rien n'est
## déclaré pièce par pièce : le niveau se lit sur le repère de réveil, et la
## cave en héritera sans qu'on touche à quoi que ce soit.
const HAUTEUR_PLAIN_PIED := 1.0
const DUREE_REFUS := 2.5
## Le temps de lire « Attrapé » avant que tout ne reparte à zéro.
const DUREE_AVANT_RELANCE := 2.0

@onready var message_gagne: Label = $Interface/MessageGagne
@onready var message_perdu: Label = $Interface/MessagePerdu
@onready var message_action: Label = $Interface/MessageAction
@onready var message_refus: Label = $Interface/MessageRefus
@onready var compteur: Label = $Interface/Compteur
@onready var fente: Control = $Interface/Fente
@onready var message_audit: Label = $Interface/MessageAudit

var partie_gagnee := false
var partie_perdue := false
var morceaux := 0
## Le badge, tiré du coffre-fort : le seul objet qui ouvre la porte rouge.
var badge := false
var minuteur_refus: Tween = null
## La pièce du réveil, retenue entre le tirage et la pose du rôdeur.
var piece_reveil: Node3D = null


func _ready() -> void:
	message_gagne.hide()
	message_perdu.hide()
	message_action.text = ""
	message_refus.text = ""
	message_audit.hide()
	fente.hide()
	maj_compteur()

	tire_au_sort()

	for coffre in [$CoffreA, $CoffreB]:
		coffre.morceau_pris.connect(_on_morceau_pris)
	$CoffreFort.tentative_ouverture.connect(_on_tentative_coffre_fort)
	$CoffreFort.badge_pris.connect(_on_badge_pris)
	$Joueur.cible_changee.connect(_on_cible_changee)
	$Joueur.cache_change.connect(_on_cache_change)
	$Sortie.tentative_ouverture.connect(_on_tentative_ouverture)
	for cachette in get_tree().get_nodes_in_group("cachettes"):
		cachette.entree_demandee.connect(_on_entree_cachette_demandee)
		cachette.joueur = $Joueur

	for rodeur in rodeurs():
		rodeur.joueur_attrape.connect(_on_joueur_attrape)

	# Les rôdeurs ne peuvent ni vérifier une ligne de vue ni chercher leur
	# chemin avant que la maison ait ses murs et sa carte.
	await $Maison.navigation_prete
	affiche_audit()
	lance_les_rodeurs()


func rodeurs() -> Array:
	return get_tree().get_nodes_in_group("rodeurs")


## Un rôdeur par niveau : chacun ronde chez lui, et y rentre après avoir
## renoncé. Le jour où la cave arrivera, il suffira d'ajouter un rôdeur de
## plus dans la scène : le niveau se distribuera tout seul.
func lance_les_rodeurs() -> void:
	var niveaux := niveaux_de_pieces()
	var liste := rodeurs()
	var partout := points_des(pieces())
	for i in liste.size():
		var chez_lui: Array = niveaux[i % niveaux.size()]
		place_rodeur(liste[i], chez_lui)
		liste[i].demarre($Joueur, points_des(chez_lui), partout,
			String(piece_reveil.name), $Maison)


## Les pièces groupées par niveau, du bas vers le haut. Rien n'est déclaré :
## l'altitude des repères suffit — la cave s'y rangera d'elle-même.
func niveaux_de_pieces() -> Array:
	var par_altitude := {}
	for piece in pieces():
		var etage := int(round(piece.reveil.global_position.y / 3.2))
		if not par_altitude.has(etage):
			par_altitude[etage] = []
		par_altitude[etage].append(piece)
	var cles := par_altitude.keys()
	cles.sort()
	var niveaux := []
	for cle in cles:
		niveaux.append(par_altitude[cle])
	return niveaux


## Le contrôle de la maison, à l'écran — pas dans les journaux que personne ne
## lit : un emplacement cassé se voit au premier lancement, en rouge.
func affiche_audit() -> void:
	var problemes: Array[String] = $Maison.audit_emplacements()
	if problemes.is_empty():
		return
	message_audit.text = "EMPLACEMENTS À CORRIGER\n" + "\n".join(problemes)
	message_audit.show()


## Chaque partie est distribuée au hasard, sous six garde-fous :
##  - la sortie et les deux coffres tombent dans trois pièces différentes,
##    sinon il n'y a rien à chercher ;
##  - la porte rouge est TOUJOURS de plain-pied : à l'étage elle donnerait
##    sur le vide ;
##  - au moins un coffre est TOUJOURS à l'étage : sans ça près d'une partie
##    sur deux se jouerait sans jamais monter, et l'étage ne servirait à rien ;
##  - on ne se réveille jamais dans la pièce de la sortie, sinon la partie
##    dure dix secondes ;
##  - le rôdeur ne commence jamais là où il pourrait voir le joueur — sinon
##    on meurt avant d'avoir bougé (voir place_rodeur) ;
##  - un coffre peut tomber dans la pièce de réveil : c'est de la chance.
func tire_au_sort() -> void:
	var de_plain_pied := pieces().filter(est_de_plain_pied)
	var a_l_etage := pieces().filter(func(piece: Node3D) -> bool:
		return not est_de_plain_pied(piece))

	var piece_sortie: Node3D = de_plain_pied.pick_random()
	pose($Sortie, piece_sortie.sortie)

	# Les trois objets à chercher, dans trois pièces distinctes de la sortie.
	# L'une d'elles est forcément à l'étage — c'est ce qui donne une raison de
	# monter. Lequel des trois y tombe est ensuite tiré au sort : le coffre-fort
	# n'est pas plus souvent en haut qu'un coffre ordinaire.
	var restantes := pieces()
	restantes.erase(piece_sortie)
	var candidats_en_haut := a_l_etage.filter(func(piece: Node3D) -> bool:
		return piece != piece_sortie)
	var chez_le_haut: Node3D = candidats_en_haut.pick_random() \
		if not candidats_en_haut.is_empty() else restantes.pick_random()
	restantes.erase(chez_le_haut)
	restantes.shuffle()
	var trois: Array = [chez_le_haut, restantes[0], restantes[1]]
	trois.shuffle()
	pose($CoffreA, trois[0].coffre)
	pose($CoffreB, trois[1].coffre)
	pose($CoffreFort, trois[2].coffre)

	var ou_se_reveiller := pieces()
	ou_se_reveiller.erase(piece_sortie)
	piece_reveil = ou_se_reveiller.pick_random()
	# Le joueur se pose légèrement au-dessus du sol : il tombe dessus à la
	# première image de physique.
	pose($Joueur, piece_reveil.reveil, Vector3.UP * 0.1)


## Le niveau d'une pièce se lit à l'altitude de son repère de réveil.
func est_de_plain_pied(piece: Node3D) -> bool:
	return piece.reveil.global_position.y < HAUTEUR_PLAIN_PIED


## Un rôdeur ne commence jamais là où il pourrait voir le joueur — des portes
## alignées de part et d'autre du couloir suffisent à condamner un départ —
## ni à moins de DISTANCE_DEPART_MIN de marche réelle : voisin de mur à mur,
## il serait sur le joueur avant que celui-ci ait compris où il est.
## On tire parmi les départs sûrs de SON niveau ; s'il n'en restait aucun,
## la pièce la plus éloignée du joueur en marchant.
## Jusque-là il attend, invisible, rangé dans un couloir (voir jeu.tscn).
func place_rodeur(rodeur: CharacterBody3D, pieces_du_niveau: Array) -> void:
	var candidats := pieces_du_niveau.duplicate()
	candidats.erase(piece_reveil)
	if candidats.is_empty():
		return
	var surs := candidats.filter(func(piece: Node3D) -> bool:
		return not rodeur.verrait_depuis(piece.reveil.global_position, $Joueur) \
			and distance_de_marche(piece.reveil.global_position, $Joueur.global_position) \
				>= DISTANCE_DEPART_MIN)

	var depart: Node3D
	if surs.is_empty():
		candidats.sort_custom(func(a: Node3D, b: Node3D) -> bool:
			return distance_de_marche(a.reveil.global_position, $Joueur.global_position) \
				> distance_de_marche(b.reveil.global_position, $Joueur.global_position))
		depart = candidats[0]
	else:
		depart = surs.pick_random()

	pose(rodeur, depart.reveil, Vector3.UP * 0.1)
	rodeur.show()


func distance_de_marche(depuis: Vector3, vers: Vector3) -> float:
	return $Maison.distance_de_marche(depuis, vers)


func pieces() -> Array:
	return get_tree().get_nodes_in_group("pieces")


## Un point dégagé par pièce pour la ronde des rôdeurs : le repère de réveil.
func points_des(liste: Array) -> Dictionary:
	var points := {}
	for piece in liste:
		points[String(piece.name)] = piece.reveil.global_position
	return points


func pose(noeud: Node3D, repere: Marker3D, decalage: Vector3 = Vector3.ZERO) -> void:
	noeud.global_position = repere.global_position + decalage
	noeud.rotation = Vector3(0.0, repere.global_rotation.y, 0.0)


func _on_cible_changee(texte: String) -> void:
	message_action.text = texte


func _on_entree_cachette_demandee(cachette: Node3D) -> void:
	if partie_gagnee or partie_perdue:
		return
	# On demande aux rôdeurs ce qu'ils voient AVANT que le joueur ne disparaisse :
	# c'est ce seul instant qui décide si l'un d'eux viendra ouvrir le meuble.
	# Celui qui l'a vu entrer est le seul à venir — les autres ne savent rien.
	var temoin: CharacterBody3D = null
	for rodeur in rodeurs():
		if rodeur.actif and rodeur.voit_joueur():
			temoin = rodeur
			break
	$Joueur.entre_dans_cachette(cachette)
	if temoin != null:
		temoin.a_vu_entrer(cachette)


func _on_cache_change(est_cache: bool) -> void:
	fente.visible = est_cache
	message_action.text = "Sortir" if est_cache else ""
	if not est_cache:
		for rodeur in rodeurs():
			rodeur.oublie_cachette()


func _on_morceau_pris() -> void:
	morceaux += 1
	maj_compteur()


func _on_badge_pris() -> void:
	badge = true
	maj_compteur()


## Les morceaux comptent jusqu'à ce que le badge les rende inutiles : à partir
## de là, une seule chose importe et l'affichage ne dit plus que celle-là.
func maj_compteur() -> void:
	compteur.text = "Badge en poche" if badge \
		else "Morceaux de clé : %d / %d" % [morceaux, MORCEAUX_REQUIS]


func _on_joueur_attrape() -> void:
	if partie_gagnee or partie_perdue:
		return
	partie_perdue = true
	message_perdu.show()
	message_action.text = ""
	message_refus.text = ""
	fige_joueur()
	for rodeur in rodeurs():
		rodeur.actif = false

	# Tout repart à zéro : coffres refermés, morceaux perdus, nouveau tirage.
	await get_tree().create_timer(DUREE_AVANT_RELANCE).timeout
	get_tree().reload_current_scene()


func fige_joueur() -> void:
	var joueur: CharacterBody3D = $Joueur
	joueur.set_physics_process(false)
	joueur.set_process_unhandled_input(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


## La porte rouge ne compte plus les morceaux : elle exige le badge, et lui
## seul. C'est le dernier maillon de la chaîne.
func _on_tentative_ouverture() -> void:
	if partie_gagnee or partie_perdue:
		return
	if badge:
		gagne()
	else:
		refuse_ouverture()


## Le coffre-fort ne s'ouvre qu'avec les deux morceaux. Verrouillé, il dit ce
## qu'il attend : c'est ainsi que le joueur apprend à quoi servent les morceaux
## qu'il ramasse, sans qu'on le lui explique.
func _on_tentative_coffre_fort() -> void:
	if partie_gagnee or partie_perdue:
		return
	if morceaux < MORCEAUX_REQUIS:
		annonce_refus("Verrouillé — %s" % ce_qui_manque())
	else:
		$CoffreFort.ouvre()


## La porte dit ce qui manque, puis se tait. Elle nomme le coffre-fort : c'est
## par elle que le joueur qui n'en a pas encore croisé apprend qu'il existe.
func refuse_ouverture() -> void:
	annonce_refus("Il te faut le badge, dans le coffre-fort")


func ce_qui_manque() -> String:
	var manque := MORCEAUX_REQUIS - morceaux
	return "il te manque %d morceau%s de clé" % [manque, "x" if manque > 1 else ""]


## Un message qui s'affiche puis se tait de lui-même.
func annonce_refus(texte: String) -> void:
	message_refus.text = texte
	if minuteur_refus != null and minuteur_refus.is_valid():
		minuteur_refus.kill()
	minuteur_refus = create_tween()
	minuteur_refus.tween_interval(DUREE_REFUS)
	minuteur_refus.tween_callback(func() -> void: message_refus.text = "")


func gagne() -> void:
	partie_gagnee = true
	$Sortie.ouverte = true
	message_gagne.show()
	message_action.text = ""
	message_refus.text = ""
	fige_joueur()
	for rodeur in rodeurs():
		rodeur.actif = false
