extends StaticBody3D

## Le « bouton développeur » du sas d'intro. On le vise et on le presse (E) ;
## il ouvre la porte-portail vers le quartier de jeux (la zone cube, à part).
## Accès de développement pour préparer la suite — pas un élément de jeu final.

signal active

var presse := false


func texte_action() -> String:
	return "" if presse else "Bouton développeur"


func agir() -> void:
	if presse:
		return
	presse = true
	active.emit()
	# Repère visuel : le bouton vire au vert une fois pressé.
	var mat := $Voyant.get_surface_override_material(0) as StandardMaterial3D
	if mat != null:
		mat.albedo_color = Color(0.3, 0.9, 0.4)
		mat.emission = Color(0.3, 0.9, 0.4)
