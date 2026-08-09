extends Node3D

## Gestionnaire de la partie : panneau d'accueil, tirage au sort de la
## distribution à chaque lancement (porte rouge, coffres, réveil du joueur,
## départ des rôdeurs), décompte des morceaux de clé, et ouverture de la porte
## rouge à qui détient le BADGE — pas les morceaux : ils n'ouvrent que le
## coffre-fort, qui contient le badge (chaîne du jet 9).
## Attrapé → tout repart à zéro, nouveau tirage.
##
## Les pièces et leurs emplacements vivent dans la maison (scène Pièce,
## groupe « pieces ») : ici on tire et on pose, on ne connaît aucune coordonnée.

const MORCEAUX_REQUIS := 2
## La pièce d'introduction (jet 16) : un sas fixe et dédié où le joueur se
## réveille toujours. C'est la Chambre, réaffectée à ce rôle — elle sort du
## hasard des objets, le joueur y naît à chaque partie.
const PIECE_INTRO := "Chambre"
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
## Le temps de lire la fin de partie avant que le panneau d'accueil ne revienne.
## Une victoire se savoure un peu plus longtemps qu'une capture.
const DUREE_LECTURE_ATTRAPE := 2.0
const DUREE_LECTURE_GAGNE := 3.0
## La ligne du réveil : le temps de la lire sans y penser, puis elle s'efface
## d'elle-même. En fondu, pas d'un coup — une disparition sèche accroche l'œil
## au moment précis où le joueur commence à regarder autour de lui.
const DUREE_LIGNE_REVEIL := 4.0
const DUREE_FONDU_REVEIL := 1.0

@onready var message_gagne: Label = $Interface/MessageGagne
@onready var message_perdu: Label = $Interface/MessagePerdu
@onready var message_action: Label = $Interface/MessageAction
@onready var message_refus: Label = $Interface/MessageRefus
@onready var compteur: Label = $Interface/Compteur
@onready var fente: Control = $Interface/Fente
@onready var message_audit: Label = $Interface/MessageAudit
@onready var message_reveil: Label = $Interface/MessageReveil
@onready var panneau: ColorRect = $Interface/Panneau
@onready var barre_fouille: ProgressBar = $Interface/BarreFouille
## Sons temporaires (jet 13), le temps que Kinder pose les vrais. Ils s'enchaînent
## sans jamais se chevaucher : « vue » au repérage, puis « poursuite » en boucle
## une fois « vue » finie, « attrapé » à la capture. Voir maj_son_danger.
## À remplacer sans douleur — un « ambiance » viendra combler le silence.
@onready var son_vue: AudioStreamPlayer = $SonVue
@onready var son_poursuite: AudioStreamPlayer = $SonPoursuite
@onready var son_attrape: AudioStreamPlayer = $SonAttrape

## Émis quand le joueur appuie sur une touche devant le panneau d'accueil.
signal entree_demandee_au_panneau

## L'état du son de danger : calme, « vue » qui joue, puis poursuite en boucle.
## Vue et poursuite ne se chevauchent jamais (voir maj_son_danger).
enum EtatSon { CALME, VU, POURSUITE }
var etat_son := EtatSon.CALME

var partie_gagnee := false
var partie_perdue := false
var morceaux := 0
## Le badge, tiré du coffre-fort : le seul objet qui ouvre la porte rouge.
var badge := false
## La clé d'intro, tirée du coffre du sas : le seul objet qui ouvre la porte du
## sas d'introduction (jet 16). Le joueur naît enfermé, elle le libère.
var cle_intro := false
var minuteur_refus: Tween = null
## La pièce du réveil, retenue entre le tirage et la pose du rôdeur.
var piece_reveil: Node3D = null
## Une touche a-t-elle déjà été pressée devant le panneau ? Le drapeau double
## le signal : sans lui, un joueur plus rapide que la carte de navigation
## verrait sa touche tomber dans le vide et resterait bloqué sur le panneau.
var touche_recue := false


func _ready() -> void:
	message_gagne.hide()
	message_perdu.hide()
	message_action.text = ""
	message_refus.text = ""
	message_audit.hide()
	message_reveil.hide()
	fente.hide()
	panneau.hide()
	barre_fouille.hide()
	maj_compteur()

	var avec_panneau := est_la_vraie_partie()
	if avec_panneau:
		ouvre_le_panneau()

	tire_au_sort()

	for coffre in [$CoffreA, $CoffreB]:
		coffre.morceau_pris.connect(_on_morceau_pris)
	$CoffreFort.tentative_ouverture.connect(_on_tentative_coffre_fort)
	$CoffreFort.badge_pris.connect(_on_badge_pris)
	$CoffreIntro.cle_intro_prise.connect(_on_cle_intro_prise)
	for porte in get_tree().get_nodes_in_group("portes_intro"):
		porte.tentative_ouverture.connect(_on_tentative_porte_intro)
	$CarteObjet.carte_prise.connect(_on_carte_prise)
	# Le bouton développeur ouvre la porte-portail vers le quartier de jeux (à part).
	$BoutonDev.active.connect(func() -> void: $PortailDev.ouvre())
	$Joueur.cible_changee.connect(_on_cible_changee)
	$Joueur.cache_change.connect(_on_cache_change)
	$Sortie.tentative_ouverture.connect(_on_tentative_ouverture)
	for cachette in get_tree().get_nodes_in_group("cachettes"):
		cachette.entree_demandee.connect(_on_entree_cachette_demandee)
		cachette.joueur = $Joueur

	for rodeur in rodeurs():
		rodeur.joueur_attrape.connect(_on_joueur_attrape)
		rodeur.repere_le_joueur.connect(_on_rodeur_repere.bind(rodeur))
	son_vue.finished.connect(_on_son_vue_fini)
	son_poursuite.finished.connect(_on_son_poursuite_fini)

	# Les rôdeurs ne peuvent ni vérifier une ligne de vue ni chercher leur
	# chemin avant que la maison ait ses murs et sa carte.
	await $Maison.navigation_prete

	# Le manoir attend derrière le panneau : les rôdeurs ne rondent pas encore.
	# Sans ça, le joueur perdrait son avance pendant qu'il lit — et le garde-fou
	# « les premières secondes lui appartiennent » ne voudrait plus rien dire.
	if avec_panneau:
		if not touche_recue:
			await entree_demandee_au_panneau
		entre_dans_le_manoir()

	# L'audit après le panneau, jamais avant : sous le panneau, le bandeau
	# rouge naîtrait caché et personne ne le verrait.
	affiche_audit()
	lance_les_rodeurs()


## La barre de fouille suit l'ouverture d'un coffre : elle apparaît le temps que
## le joueur s'affaire et se remplit jusqu'à ce que le couvercle bascule. Le
## regard étant fixe, c'est le seul retour à l'écran qui confirme le geste.
func _process(_delta: float) -> void:
	if $Joueur.est_en_fouille():
		barre_fouille.value = $Joueur.fouille_fraction() * 100.0
		barre_fouille.show()
	else:
		barre_fouille.hide()
	maj_son_danger()


## Le son du danger, en trois temps qui ne se chevauchent jamais :
## repéré → « vue » (un coup) ; « vue » finie et le rôdeur toujours sur toi →
## « poursuite » en boucle ; le rôdeur reprend sa ronde normale (il t'a vraiment
## perdu) → silence. La tension tient donc pendant la BATTUE — c'est là surtout
## qu'on te cherche encore. Un seul état pour les deux rôdeurs.
## (À terme, le silence deviendra « ambiance ».)
func maj_son_danger() -> void:
	match etat_son:
		EtatSon.CALME:
			if un_rodeur_alerte():
				son_vue.play()
				etat_son = EtatSon.VU
		EtatSon.POURSUITE:
			if not un_rodeur_alerte():
				son_poursuite.stop()
				etat_son = EtatSon.CALME


## Un rôdeur est-il « sur toi » — en poursuite, en battue, ou en route pour ouvrir
## la cachette où il t'a vu entrer ? Tant qu'il n'est pas revenu à sa ronde
## normale, il te cherche encore : c'est pendant la BATTUE, surtout, que le son
## doit tenir. Il ne retombe qu'à l'abandon, quand la ronde reprend.
func un_rodeur_alerte() -> bool:
	for rodeur in rodeurs():
		if rodeur.actif and (rodeur.en_poursuite or rodeur.en_battue \
				or rodeur.en_alerte or rodeur.cachette_reperee != null):
			return true
	return false


## « Vue » vient de finir : si l'on est toujours chassé, la poursuite prend le
## relais en boucle ; sinon on retombe dans le calme. Les deux ne se
## superposent donc jamais.
func _on_son_vue_fini() -> void:
	if un_rodeur_alerte():
		son_poursuite.play()
		etat_son = EtatSon.POURSUITE
	else:
		etat_son = EtatSon.CALME


## La boucle de poursuite : le fichier temporaire ne boucle pas seul, on le
## relance tant qu'on reste en poursuite.
func _on_son_poursuite_fini() -> void:
	if etat_son == EtatSon.POURSUITE and un_rodeur_alerte():
		son_poursuite.play()


func rodeurs() -> Array:
	return get_tree().get_nodes_in_group("rodeurs")


## L'étau (jet 14) : un rôdeur a vu le joueur, on prévient les autres de sa
## position. Celui qui a vu poursuit déjà — inutile de se prévenir soi-même.
func _on_rodeur_repere(ou: Vector3, emetteur: Node) -> void:
	for rodeur in rodeurs():
		if rodeur != emetteur:
			rodeur.recois_alerte(ou)


## Sommes-nous la vraie partie, ou une sonde nous a-t-elle instanciés à la main ?
## LE PANNEAU ET LA RELANCE en dépendent tous les deux, et pour la même raison :
## une sonde n'a personne pour appuyer sur une touche, et « recharger la scène »
## y rechargerait la SIENNE, pas le manoir. C'est la frontière que PLAN.md
## déclare depuis toujours hors de portée du filet.
## Conséquence assumée : ni le panneau ni la relance ne se testent autrement
## qu'à la main.
func est_la_vraie_partie() -> bool:
	return get_tree().current_scene == self


## Fin de partie, gagnée ou perdue : le message s'affiche le temps d'être lu,
## puis tout revient au panneau d'accueil. C'est de là qu'on relance — le
## joueur reprend la main au lieu d'être renvoyé en jeu sans avoir rien demandé.
func retour_au_panneau(duree_de_lecture: float) -> void:
	if not est_la_vraie_partie():
		return
	await get_tree().create_timer(duree_de_lecture).timeout
	get_tree().reload_current_scene()


## Le panneau s'ouvre avant tout le reste : le joueur ne doit pas apercevoir
## le manoir une fraction de seconde avant d'avoir lu les règles.
## Le joueur est figé comme il l'est à la victoire — souris rendue, pour lire
## sans que le moindre mouvement fasse tourner la tête.
func ouvre_le_panneau() -> void:
	panneau.show()
	fige_joueur()


## Une touche, et on entre. Le joueur retrouve ses commandes et la souris.
func entre_dans_le_manoir() -> void:
	panneau.hide()
	var joueur: CharacterBody3D = $Joueur
	joueur.set_physics_process(true)
	joueur.set_process_unhandled_input(true)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	annonce_le_reveil()


## Le panneau se lit une fois, avant d'entrer. Cette ligne est ce qui reste
## quand le joueur se retrouve seul dans le noir — le but, et rien d'autre.
## Elle ne demande rien : elle s'efface toute seule.
func annonce_le_reveil() -> void:
	message_reveil.modulate.a = 1.0
	message_reveil.show()
	var fondu := create_tween()
	fondu.tween_interval(DUREE_LIGNE_REVEIL)
	fondu.tween_property(message_reveil, "modulate:a", 0.0, DUREE_FONDU_REVEIL)
	fondu.tween_callback(message_reveil.hide)


## Devant le panneau, n'importe quelle touche entre dans le manoir — c'est ce
## que le panneau promet. Le joueur ne lit plus ses propres commandes tant
## qu'il est ouvert : cet événement arrive donc toujours jusqu'ici.
func _unhandled_input(evenement: InputEvent) -> void:
	if not panneau.visible or touche_recue:
		return
	var appui: bool = (evenement is InputEventKey and evenement.pressed \
			and not evenement.echo) \
		or (evenement is InputEventMouseButton and evenement.pressed)
	if appui:
		touche_recue = true
		entree_demandee_au_panneau.emit()


## Un rôdeur par niveau : chacun ronde chez lui, et y rentre après avoir
## renoncé. Le jour où la cave arrivera, il suffira d'ajouter un rôdeur de
## plus dans la scène : le niveau se distribuera tout seul.
func lance_les_rodeurs() -> void:
	var niveaux := niveaux_de_pieces()
	var liste := rodeurs()
	# Le sas d'intro est scellé (jet 16) : les rôdeurs ne le rôdent ni ne le
	# ratissent jamais, sinon ils fonceraient se coincer contre la porte
	# verrouillée. On ne leur donne donc que les pièces DE JEU, ici et par niveau.
	var partout := points_des(pieces_de_jeu())
	for i in liste.size():
		var chez_lui: Array = niveaux[i % niveaux.size()]
		place_rodeur(liste[i], chez_lui)
		liste[i].demarre($Joueur, points_des(chez_lui), partout,
			String(piece_reveil.name), $Maison)


## Les pièces groupées par niveau, du bas vers le haut. Rien n'est déclaré :
## l'altitude des repères suffit — la cave s'y rangera d'elle-même.
func niveaux_de_pieces() -> Array:
	var par_altitude := {}
	# Le sas d'intro exclu (jet 16) : il ne fait partie de la ronde d'aucun étage.
	for piece in pieces_de_jeu():
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
	var jouables := pieces_de_jeu()
	var de_plain_pied := jouables.filter(est_de_plain_pied)
	var a_l_etage := jouables.filter(func(piece: Node3D) -> bool:
		return not est_de_plain_pied(piece))

	var piece_sortie: Node3D = de_plain_pied.pick_random()
	pose($Sortie, piece_sortie.sortie)

	# Les trois objets à chercher, dans trois pièces distinctes de la sortie.
	# L'une d'elles est forcément à l'étage — c'est ce qui donne une raison de
	# monter. Lequel des trois y tombe est ensuite tiré au sort : le coffre-fort
	# n'est pas plus souvent en haut qu'un coffre ordinaire.
	var restantes := jouables.duplicate()
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

	# Le joueur se réveille TOUJOURS dans le sas d'introduction (jet 16), un lieu
	# fixe et dédié — plus dans une pièce au hasard.
	piece_reveil = piece_intro()
	# Le joueur se pose légèrement au-dessus du sol : il tombe dessus à la
	# première image de physique.
	pose($Joueur, piece_reveil.reveil, Vector3.UP * 0.1)
	# Le coffre du sas, posé sur le repère de coffre du sas : il contient la clé
	# d'intro. Fixe, hors du tirage — le sas ne varie pas.
	pose($CoffreIntro, piece_reveil.coffre)


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


## La pièce d'introduction, réaffectée : le joueur s'y réveille toujours.
func piece_intro() -> Node3D:
	for piece in pieces():
		if String(piece.name) == PIECE_INTRO:
			return piece
	return null


## Les pièces du manoir de jeu — toutes sauf le sas d'intro. C'est parmi elles
## que se tirent la sortie et les trois objets à chercher.
func pieces_de_jeu() -> Array:
	return pieces().filter(func(piece: Node3D) -> bool:
		return String(piece.name) != PIECE_INTRO)


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
	son_attrape.play()
	message_perdu.show()
	message_action.text = ""
	message_refus.text = ""
	fige_joueur()
	for rodeur in rodeurs():
		rodeur.actif = false

	# Le temps de lire « Attrapé », puis retour au panneau : coffres refermés,
	# morceaux perdus, nouveau tirage — et c'est le joueur qui décide quand.
	retour_au_panneau(DUREE_LECTURE_ATTRAPE)


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


## Le joueur a pris la clé d'intro dans le coffre du sas. Elle n'ouvre que la
## porte du sas — jamais la porte rouge, qui n'obéit qu'au badge.
func _on_cle_intro_prise() -> void:
	cle_intro = true


## Le joueur a pris la carte sur la table de l'intro : le plan (bouton M) s'active.
## Un mot le lui apprend — M n'est pas sur le panneau d'accueil.
func _on_carte_prise() -> void:
	$Interface/Carte.disponible = true
	annonce_refus("Carte en poche — M pour l'ouvrir")


## La porte du sas, comme la porte rouge, ne décide pas d'elle-même : le Jeu
## l'ouvre si la clé d'intro est en poche, sinon il refuse et nomme la clé.
func _on_tentative_porte_intro() -> void:
	if partie_gagnee or partie_perdue:
		return
	if cle_intro:
		ouvre_le_sas()
	else:
		annonce_refus("Il te faut la clé, dans le coffre")


## La clé ouvre les DEUX portes du sas d'un coup, et rouvre la pièce au manoir :
## avant la clé les rôdeurs en étaient exclus (2a), à partir de là ils peuvent y
## entrer et t'y suivre — la double porte devient alors ton échappatoire.
func ouvre_le_sas() -> void:
	for porte in get_tree().get_nodes_in_group("portes_intro"):
		if not porte.ouverte:
			porte.ouvre()
	reintegre_le_sas()


## Le sas rejoint le monde des rôdeurs : ils le rôdent (ceux de son étage) et le
## ratissent (tous). Le scellement du jet 16 était permanent ; il devient
## conditionnel — levé à l'ouverture des portes.
func reintegre_le_sas() -> void:
	var sas := piece_intro()
	if sas == null:
		return
	var nom := String(sas.name)
	var pos: Vector3 = sas.reveil.global_position
	var plain_pied := est_de_plain_pied(sas)
	for rodeur in rodeurs():
		rodeur.reintegre(nom, pos, plain_pied)


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


## Gagner ramène au panneau, exactement comme se faire attraper. Jusqu'au jet 12
## la victoire ne relançait RIEN : l'écran se figeait sur « Gagné » et il fallait
## fermer la fenêtre. Le défaut vivait dans la zone que le filet ne peut pas
## voir — et PLAN.md le déclarait sans que personne aille regarder derrière.
func gagne() -> void:
	partie_gagnee = true
	$Sortie.ouverte = true
	message_gagne.show()
	message_action.text = ""
	message_refus.text = ""
	fige_joueur()
	for rodeur in rodeurs():
		rodeur.actif = false

	# Une victoire se savoure un peu plus longtemps qu'une capture.
	retour_au_panneau(DUREE_LECTURE_GAGNE)
