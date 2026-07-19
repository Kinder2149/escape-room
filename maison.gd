extends Node3D

## La maison calcule sa propre carte de navigation au démarrage.
## Elle ne peut pas être préparée à l'avance : les murs sont sculptés en CSG,
## et cette géométrie n'existe qu'une fois la scène chargée et calculée.

signal navigation_prete


func _ready() -> void:
	# Laisser au CSG le temps de produire sa géométrie avant de la lire.
	await get_tree().process_frame
	# La géométrie sculptée n'arrive pas toujours en une image : trop tôt, la
	# carte ne contient que le mobilier (vécu), et le rôdeur marcherait sur les
	# meubles. On recalcule jusqu'à ce que le sol y soit vraiment — témoin : le
	# milieu du couloir, du sol nu garanti sans meuble.
	for essai in 60:
		$Navigation.bake_navigation_mesh(false)
		# Le serveur de navigation n'intègre la carte qu'à sa synchronisation
		# suivante : sans cette attente, on lirait la carte précédente.
		await get_tree().physics_frame
		NavigationServer3D.map_force_update($Navigation.get_navigation_map())
		if sol_sur_la_carte():
			navigation_prete.emit()
			return
		await get_tree().process_frame
	push_error("La carte de navigation n'a jamais reçu le sol de la maison.")
	navigation_prete.emit()


## La distance en marchant, portes et couloirs compris. À vol d'oiseau, un mur
## ferait paraître tout près ce qui demande une longue marche — et l'inverse.
## Elle vit ici, chez le propriétaire de la carte : le tirage et le rôdeur
## l'interrogent tous les deux, plutôt que d'en garder chacun une copie.
func distance_de_marche(depuis: Vector3, vers: Vector3) -> float:
	var chemin := NavigationServer3D.map_get_path(
		$Navigation.get_navigation_map(), depuis, vers, true)
	var longueur := 0.0
	for i in range(1, chemin.size()):
		longueur += chemin[i - 1].distance_to(chemin[i])
	return longueur


## Contrôle des emplacements, à appeler une fois la carte prête. Chaque pièce
## doit offrir : un coffre et un réveil posés sur le sol praticable et
## joignables en marchant, une porte rouge abordable et plaquée contre un mur
## extérieur. Retourne les problèmes en clair, en français — vide si tout va.
## C'est le filet du projet : un repère déplacé dans un mur se voit au premier
## lancement, pas une partie sur quinze.
func audit_emplacements() -> Array[String]:
	var problemes: Array[String] = []
	var carte: RID = $Navigation.get_navigation_map()
	for piece in get_tree().get_nodes_in_group("pieces"):
		for quoi in ["Coffre", "Reveil"]:
			var point: Vector3 = piece.get_node(quoi).global_position
			if not point_praticable(carte, point):
				problemes.append("%s / %s : hors du sol praticable (mur ou meuble ?)"
					% [piece.name, quoi.to_lower()])
			elif not point_joignable(carte, point):
				problemes.append("%s / %s : injoignable depuis le couloir"
					% [piece.name, quoi.to_lower()])

		var sortie: Marker3D = piece.get_node("Sortie")
		var devant: Vector3 = sortie.global_position \
			- sortie.global_transform.basis.z * 0.8
		if not point_praticable(carte, devant):
			problemes.append("%s / porte rouge : on ne peut pas se tenir devant"
				% piece.name)
		elif not point_joignable(carte, devant):
			problemes.append("%s / porte rouge : injoignable depuis le couloir"
				% piece.name)
		if not porte_contre_mur_exterieur(sortie):
			problemes.append("%s / porte rouge : pas plaquée contre un mur extérieur"
				% piece.name)
	return problemes


## Le point est-il sur le sol praticable, là où on croit qu'il est ?
func point_praticable(carte: RID, point: Vector3) -> bool:
	var proche := NavigationServer3D.map_get_closest_point(carte, point + Vector3.UP * 0.1)
	if Vector2(proche.x, proche.z).distance_to(Vector2(point.x, point.z)) > 0.3:
		return false
	return absf(proche.y - point.y) < 0.5


## Peut-on marcher du couloir jusqu'au point ? Un chemin qui s'arrête en route
## trahit un emplacement isolé (pièce murée, meuble qui bloque une porte).
func point_joignable(carte: RID, point: Vector3) -> bool:
	var chemin := NavigationServer3D.map_get_path(
		carte, Vector3(7.0, 0.1, 0.0), point + Vector3.UP * 0.1, true)
	if chemin.is_empty():
		return false
	var bout := chemin[chemin.size() - 1]
	return Vector2(bout.x, bout.z).distance_to(Vector2(point.x, point.z)) < 0.5


## À un mètre derrière la porte (elle regarde vers l'intérieur), on doit être
## sorti de l'emprise de la maison — sinon le mur n'est pas extérieur, ou il
## n'y a pas de mur du tout. L'emprise est lue sur le bloc sculpté lui-même,
## centre compris : depuis l'aile Est, le bloc n'est plus centré sur l'origine.
func porte_contre_mur_exterieur(sortie: Marker3D) -> bool:
	var derriere: Vector3 = sortie.global_position + sortie.global_transform.basis.z * 1.0
	var masse: CSGBox3D = $Navigation/Batiment/Masse
	var centre: Vector3 = masse.global_position
	var demi: Vector3 = masse.size / 2.0
	return absf(derriere.x - centre.x) > demi.x or absf(derriere.z - centre.z) > demi.z


## Les deux bouts du couloir sont-ils marchables, et fournis par NOTRE carte ?
## Sinon, la carte n'a pas reçu le sol sculpté — elle est inutilisable.
## Deux pièges vécus :
##  - une carte vide répond « (0,0,0) » comme point le plus proche, d'où des
##    témoins volontairement loin de l'origine ;
##  - à la relance d'une partie, la carte de la maison précédente survit une
##    image : son sol répondrait à notre place, d'où le contrôle du
##    propriétaire.
func sol_sur_la_carte() -> bool:
	var carte: RID = $Navigation.get_navigation_map()
	var notre_region: RID = $Navigation.get_region_rid()
	for temoin in [Vector3(7.0, 0.1, 0.0), Vector3(-7.0, 0.1, 0.0)]:
		var proche := NavigationServer3D.map_get_closest_point(carte, temoin)
		if proche.distance_to(temoin) > 0.5:
			return false
		if NavigationServer3D.map_get_closest_point_owner(carte, temoin) != notre_region:
			return false
	return true
