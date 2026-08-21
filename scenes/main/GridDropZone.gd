extends Control
class_name PlacementGridDropZone
## Godot ne sait faire du glisser-déposer natif qu'entre nœuds Control.
## Comme PlacementGrid est un Node2D (un objet du monde de jeu, pas de
## l'UI), ce Control invisible sert de "traducteur" : on le superpose
## exactement à la zone écran de la grille, il reçoit le drop, et
## transforme ça en position de grille pour PlacementGrid.
## Glisse le nœud PlacementGrid ici, depuis l'Inspecteur.
##
## MISE A JOUR (brique 3bis) : gère aussi le sens inverse — glisser un
## bâtiment déjà posé HORS de la grille (ex. vers l'InventoryBar) pour le
## retirer. Coexiste avec le retrait "clic + croix" de PlacementGrid.

@export var placement_grid: PlacementGrid

var _dragged_building: Building = null

## --- Dépôt SUR la grille (achat/pose depuis l'inventaire) ---
func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is BuildingDefinition

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if not (data is BuildingDefinition):
		return
	BuildManager.select_building(data)
	var local_pos: Vector2 = placement_grid.to_local(get_global_mouse_position())
	var grid_pos: Vector2i = placement_grid.world_to_grid(local_pos)
	if placement_grid.is_within_grid(grid_pos):
		placement_grid.place_selected_building(grid_pos)

## --- Glisser un bâtiment posé HORS de la grille (retrait) ---
## Ne démarre un drag que si la case sous le curseur contient un bâtiment
## et qu'on est en PREPARATION. Le bâtiment est "décroché" tout de suite
## (caché + retiré des cases occupées) ; NOTIFICATION_DRAG_END décide s'il
## faut le remettre en jeu (drop raté) ou l'ajouter à l'inventaire (drop
## réussi sur l'InventoryBar).
func _get_drag_data(_at_position: Vector2) -> Variant:
	if GameManager.state != GameManager.GameState.PREPARATION:
		return null
	var local_pos: Vector2 = placement_grid.to_local(get_global_mouse_position())
	var grid_pos: Vector2i = placement_grid.world_to_grid(local_pos)
	var building: Building = placement_grid.get_building_at(grid_pos)
	if building == null or building.source_definition == null:
		return null

	_dragged_building = placement_grid.pick_up_building(grid_pos)

	var preview := TextureRect.new()
	preview.texture = building.source_definition.icon
	preview.custom_minimum_size = Vector2(48, 48)
	set_drag_preview(preview)

	return building.source_definition

func _notification(what: int) -> void:
	if what != NOTIFICATION_DRAG_END:
		return
	if _dragged_building == null:
		return
	if get_viewport().gui_is_drag_successful():
		BuildManager.add_to_inventory(_dragged_building.source_definition)
		placement_grid.finalize_building_removal(_dragged_building)
	else:
		placement_grid.return_building_to_grid(_dragged_building)
	_dragged_building = null
