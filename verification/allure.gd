extends SceneTree

# Sonde jetable — retour de Kinder : « super dur de le semer ».
# On mesure l'avance reelle du joueur : distance parcourue par le rodeur
# pendant qu'il poursuit a vue, puis pendant qu'il traque sans voir.
# Attendu : a vue il est plus lent que le joueur ; des qu'il perd la vue il
# ralentit nettement (temps d'arret puis traque).

var jeu: Node3D = null
var frames := 0
var echecs := 0
var phase := "attente"

var vitesse_a_vue := 0.0
var vitesse_hesitation := 999.0
var vitesse_traque := 0.0
var mesures_traque := 0


func _process(_delta: float) -> bool:
	if jeu == null:
		jeu = load("res://jeu.tscn").instantiate()
		root.add_child(jeu)
		return false
	var rodeur: CharacterBody3D = jeu.get_node("Rodeur")
	if not rodeur.visible:
		frames += 1
		if frames > 200:
			_exige("la maison devient prete", false)
			return _fin()
		return false

	var joueur: CharacterBody3D = jeu.get_node("Joueur")
	frames += 1
	var vitesse := Vector2(rodeur.velocity.x, rodeur.velocity.z).length()

	if phase == "attente":
		joueur.set_physics_process(false)
		joueur.global_position = Vector3(-7.0, 0.1, 0.0)
		joueur.velocity = Vector3(0.0, 0.0, -4.5)
		rodeur.global_position = Vector3(-2.0, 0.0, 0.0)
		rodeur.rotation = Vector3(0.0, deg_to_rad(90.0), 0.0)
		rodeur.commence_poursuite()
		phase = "a_vue"
		frames = 0
		return false

	if phase == "a_vue":
		joueur.velocity = Vector3(0.0, 0.0, -4.5)
		vitesse_a_vue = maxf(vitesse_a_vue, vitesse)
		if frames < 20:
			return false
		_exige("il poursuit a vue", rodeur.en_poursuite and is_zero_approx(rodeur.temps_sans_voir))
		_exige("a vue il court a %.1f m/s, moins vite que le joueur (4.5)"
			% vitesse_a_vue, vitesse_a_vue > 3.0 and vitesse_a_vue < 4.5)
		# Il le perd : joueur teleporte hors de vue.
		joueur.global_position = Vector3(8.5, 0.1, 3.5)
		joueur.velocity = Vector3.ZERO
		phase = "perdu"
		frames = 0
		return false

	if phase == "perdu":
		if rodeur.en_poursuite:
			if rodeur.temps_sans_voir < rodeur.DUREE_HESITATION:
				vitesse_hesitation = minf(vitesse_hesitation, vitesse)
			else:
				vitesse_traque = maxf(vitesse_traque, vitesse)
				mesures_traque += 1
		elif mesures_traque > 0 or frames > 20000:
			_exige("il marque un temps d'arret en perdant sa trace (%.1f m/s)"
				% vitesse_hesitation, vitesse_hesitation < 0.5)
			_exige("puis il traque sans sprinter (%.1f m/s, sous les %.1f de la poursuite)"
				% [vitesse_traque, rodeur.VITESSE_POURSUITE],
				vitesse_traque > 0.5 and vitesse_traque <= rodeur.VITESSE_TRAQUE + 0.3)
			_exige("l'ecart de vitesse laisse une vraie chance de fuir (%.1f m/s gagnes)"
				% (4.5 - vitesse_traque), 4.5 - vitesse_traque >= 1.0)
			return _fin()
		return false

	return false


func _fin() -> bool:
	print("=== ECHECS ALLURE: %d ===" % echecs)
	quit(1 if echecs > 0 else 0)
	return true


func _exige(nom: String, condition: bool) -> void:
	if condition:
		print("OK   %s" % nom)
	else:
		echecs += 1
		print("RATE %s" % nom)
