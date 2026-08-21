extends Node
## Autoload (Singleton) — à enregistrer sous le nom "BuildManager".
##
## Fait le lien entre le Shop (qui VEND des BuildingDefinition contre de
## l'argent) et la PlacementGrid (qui POSE des instances sur la grille).
## L'argent est dépensé une seule fois, au moment de l'achat au shop.
## Poser le bâtiment ensuite sur la grille est gratuit : c'est juste
## "jouer la carte" déjà payée, comme dans un deckbuilder.

signal inventory_changed(inventory: Array[BuildingDefinition])
signal selected_building_changed(definition: BuildingDefinition)

var inventory: Array[BuildingDefinition] = []
var selected_building: BuildingDefinition = null


## Ajoute une définition à l'inventaire (appelé par le Shop après paiement).
## Si rien n'est sélectionné, elle devient automatiquement la sélection
## courante pour que le joueur puisse la poser tout de suite.
func add_to_inventory(definition: BuildingDefinition) -> void:
	inventory.append(definition)
	inventory_changed.emit(inventory)
	if selected_building == null:
		select_building(definition)


func select_building(definition: BuildingDefinition) -> void:
	if definition in inventory:
		selected_building = definition
		selected_building_changed.emit(selected_building)


## Retire un exemplaire de la sélection courante de l'inventaire (appelé
## par PlacementGrid juste après avoir posé le bâtiment). Sélectionne
## automatiquement l'élément suivant s'il en reste.
func consume_selected_building() -> BuildingDefinition:
	if selected_building == null:
		return null
	var definition := selected_building
	inventory.erase(definition)
	selected_building = null
	inventory_changed.emit(inventory)
	if not inventory.is_empty():
		select_building(inventory[0])
	else:
		selected_building_changed.emit(null)
	return definition
