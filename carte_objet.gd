extends StaticBody3D

## La carte posée sur la table de l'intro (jet 17). On la vise et on la prend
## avec E, comme un morceau — c'est instantané (pas une fouille). Une fois prise,
## le bouton M affiche le plan du manoir.
##
## Elle ne décide pas elle-même : elle signale qu'on l'a prise, et le Jeu active
## le plan. Même partage des rôles que les coffres et les portes.

signal carte_prise

var prise := false


func texte_action() -> String:
	return "" if prise else "Prendre la carte"


func agir() -> void:
	if prise:
		return
	prise = true
	carte_prise.emit()
	hide()
	# Sinon la collision resterait sur la table, obstacle invisible.
	$CollisionShape3D.set_deferred("disabled", true)
