extends SceneTree

# Retour de Kinder : colle au mur, il ne m'attrape pas.
# On teste QUATRE planques : couloir contre le mur, deux angles de piece,
# et derriere un meuble. Il doit attraper dans les quatre cas.

const PLANQUES := [
	["contre le mur du couloir",        Vector3(0.0, 0.1, -1.0),   Vector3(4.0, 0.0, 0.0)],
	["angle nord-ouest de l'entree",    Vector3(-10.4, 0.1, -8.4), Vector3(-7.5, 0.0, -5.0)],
	["angle sud-est du salon",          Vector3(10.4, 0.1, -2.0),  Vector3(6.8, 0.0, -5.0)],
	["coince derriere le canape",       Vector3(3.4, 0.1, -4.6),   Vector3(6.8, 0.0, -5.0)],
]

var jeu: Node3D = null
var frames := 0
## Installe-t-on le scenario ? Un drapeau, jamais un numero d'image :
## l'attente du manoir consomme des images, et sous charge on ratait
## l'instant precis — la sonde mesurait alors une scene vide.
var installe := false
var essai := 0
var echecs := 0
var attrape := false
var dist_min := 99.0
## Echeance en temps REEL : un budget en images depend du debit de la machine,
## et la sonde ratait au hasard quand plusieurs tournaient a la suite.
var echeance := 0

func _process(_d: float) -> bool:
	if jeu == null:
		jeu = load("res://jeu.tscn").instantiate()
		root.add_child(jeu)
		frames = 0
		return false
	var liste := get_nodes_in_group("rodeurs")
	if liste.is_empty() or not liste[0].visible:
		frames += 1
		return frames > 400
	var r: CharacterBody3D = liste[0]
	var j: CharacterBody3D = jeu.get_node("Joueur")
	frames += 1

	if not installe:
		installe = true
		liste[1].actif = false
		liste[1].global_position = Vector3(0, 40, 0)
		for x in liste: x.joueur_attrape.disconnect(jeu._on_joueur_attrape)
		r.joueur_attrape.connect(func() -> void: attrape = true)
		j.set_physics_process(false)
		j.global_position = PLANQUES[essai][1]
		r.global_position = PLANQUES[essai][2]
		r.look_at(j.global_position, Vector3.UP)
		r.rotation = Vector3(0.0, r.rotation.y, 0.0)
		r.commence_poursuite()
		attrape = false
		dist_min = 99.0
		echeance = Time.get_ticks_msec() + 20000
		return false

	if frames > 3:
		dist_min = minf(dist_min, r.global_position.distance_to(j.global_position))
	# On n'evalue rien avant que la planque soit en place : sinon
	# l'echeance (nulle au depart) declenche des la premiere image.
	if frames > 3 and (attrape or Time.get_ticks_msec() > echeance):
		_exige("%s : il l'attrape (approche a %.2f m)" % [PLANQUES[essai][0], dist_min], attrape)
		jeu.queue_free(); jeu = null
		essai += 1
		if essai >= PLANQUES.size():
			print("=== ECHECS MUR: %d ===" % echecs)
			quit(1 if echecs > 0 else 0)
			return true
	return false

func _exige(nom: String, ok: bool) -> void:
	print("%s   %s" % ["OK  " if ok else "RATE", nom])
	if not ok: echecs += 1
