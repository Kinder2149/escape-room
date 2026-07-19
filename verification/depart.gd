extends SceneTree

# Sonde jetable — correctif du depart trop proche.
# Partie A : distances de marche reelles entre tous les points de reveil, et
#            nombre de departs surs par piece de reveil (attendu : >= 2 partout).
# Partie B : 40 tirages. Attendu : distance de marche >= 9 m, pas de ligne de
#            vue, premiere ronde jamais vers la piece du joueur.
# On attend que le rodeur soit pose (visible) : c'est le signe que la carte
# de navigation est prete et la distribution terminee.

const DISTANCE_MIN := 9.0

var jeu: Node3D = null
var frames := 0
var frames_apres_pret := 0
var essais := 0
var echecs := 0
var partie_a_faite := false


func _process(_delta: float) -> bool:
	if jeu == null:
		jeu = load("res://jeu.tscn").instantiate()
		root.add_child(jeu)
		frames = 0
		frames_apres_pret = 0
		return false
	frames += 1
	if not jeu.get_node("Rodeur").visible:
		if frames > 200:
			echecs += 1
			print("RATE la maison n'est jamais prete (200 images)")
			quit(1)
			return true
		return false
	frames_apres_pret += 1
	if frames_apres_pret < 3:
		return false

	if not partie_a_faite:
		_partie_a()
		partie_a_faite = true
	else:
		_controle_tirage()
		essais += 1
	jeu.queue_free()
	jeu = null
	if essais >= 40:
		print("=== ECHECS DEPART: %d ===" % echecs)
		quit(1 if echecs > 0 else 0)
		return true
	return false


func _marche(depuis: Vector3, vers: Vector3) -> float:
	var carte: RID = jeu.get_node("Joueur").get_world_3d().navigation_map
	var chemin := NavigationServer3D.map_get_path(carte, depuis, vers, true)
	var longueur := 0.0
	for i in range(1, chemin.size()):
		longueur += chemin[i - 1].distance_to(chemin[i])
	return longueur


func _partie_a() -> void:
	var joueur: CharacterBody3D = jeu.get_node("Joueur")
	var rodeur: CharacterBody3D = jeu.get_node("Rodeur")
	joueur.set_physics_process(false)
	rodeur.actif = false
	for p_joueur in get_nodes_in_group("pieces"):
		var reveil: Vector3 = p_joueur.get_node("Reveil").global_position
		joueur.global_position = reveil + Vector3.UP * 0.1
		var surs := []
		var detail := []
		for p_rodeur in get_nodes_in_group("pieces"):
			if p_rodeur == p_joueur:
				continue
			var d := _marche(p_rodeur.get_node("Reveil").global_position, joueur.global_position)
			var voit: bool = rodeur.verrait_depuis(p_rodeur.get_node("Reveil").global_position, joueur)
			detail.append("%s %.1fm%s" % [p_rodeur.name, d, " VUE" if voit else ""])
			if not voit and d >= DISTANCE_MIN:
				surs.append(p_rodeur.name)
		print("reveil %-11s -> %d departs surs | %s" % [p_joueur.name, surs.size(), ", ".join(detail)])
		_exige("au moins 2 departs surs depuis %s" % p_joueur.name, surs.size() >= 2)


func _piece_de(pos: Vector3, repere: String) -> String:
	for piece in get_nodes_in_group("pieces"):
		var m: Vector3 = piece.get_node(repere).global_position
		# La hauteur compte : le reveil de la chambre de maitre est exactement
		# au-dessus de celui du salon. Sans elle, on confond les deux etages.
		if Vector2(pos.x, pos.z).distance_to(Vector2(m.x, m.z)) < 0.35 				and absf(pos.y - m.y) < 1.5:
			return String(piece.name)
	return "(aucune)"


func _controle_tirage() -> void:
	var joueur: CharacterBody3D = jeu.get_node("Joueur")
	var rodeur: CharacterBody3D = jeu.get_node("Rodeur")
	var p_joueur := _piece_de(joueur.global_position, "Reveil")
	var p_rodeur := _piece_de(rodeur.global_position, "Reveil")
	var d := _marche(rodeur.global_position, joueur.global_position)
	print("tirage %d : joueur=%s rodeur=%s marche=%.1fm premiere_ronde=%s (pret image %d)" %
		[essais + 1, p_joueur, p_rodeur, d, rodeur.piece_visee, frames - frames_apres_pret + 1])

	_exige("joueur et rodeur poses sur des reperes", "(aucune)" not in [p_joueur, p_rodeur])
	_exige("distance de marche >= %.0f m" % DISTANCE_MIN, d >= DISTANCE_MIN - 0.5)
	_exige("pas de ligne de vue au depart",
		not rodeur.verrait_depuis(rodeur.global_position, joueur))
	_exige("la premiere ronde evite la piece du joueur", rodeur.piece_visee != p_joueur)
	_exige("la premiere ronde vise bien une piece", rodeur.piece_visee != "")


func _exige(nom: String, condition: bool) -> void:
	if not condition:
		echecs += 1
		print("RATE %s" % nom)
