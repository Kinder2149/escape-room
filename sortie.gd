extends StaticBody3D

## La porte rouge « SORTIE ». Elle se vise et s'ouvre comme un coffre (E),
## mais c'est le Jeu qui sait si le joueur a les deux morceaux : la porte
## se contente de signaler qu'on a essayé.

signal tentative_ouverture

var ouverte := false


func texte_action() -> String:
	return "" if ouverte else "Ouvrir la porte"


func agir() -> void:
	if ouverte:
		return
	tentative_ouverture.emit()
