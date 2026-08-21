extends Node2D
class_name Main
## Script de la scène principale. Ne fait presque rien lui-même : tout le
## reste (grille, spawner, shop, HUD) s'auto-connecte via GameManager /
## BuildManager. Son seul rôle : réinitialiser la partie et donner au
## joueur de quoi construire avant même la vague 1.

## Glisse ici, depuis l'Inspecteur, les BuildingDefinition que le joueur
## possède gratuitement au tout début (ex: 2x Mur).
@export var starting_buildings: Array[BuildingDefinition] = []


func _ready() -> void:
	GameManager.reset_game()
	for definition in starting_buildings:
		BuildManager.add_to_inventory(definition)
