extends Node2D
class_name PlacementGrid
## Gère la grille de placement 8x8 positionnée en bas de l'écran.
##
## Retrait d'un bâtiment posé, deux façons possibles (au choix du joueur) :
## 1) Clic sur le bâtiment (PREPARATION uniquement) -> bouton flottant "✕".
## 2) Glisser le bâtiment hors de la grille (ex. vers l'InventoryBar), géré
##    par PlacementGridDropZone via pick_up_building/return_building_to_grid/
##    finalize_building_removal ci-dessous.
##
## SETUP SCENE requis : ajoute un nœud CanvasLayer (nom libre, ex.
## "RemovalUI") dans la scène et glisse-le dans le champ "Removal Ui Layer"
## de l'Inspecteur. C'est là que le bouton "✕" est instancié, en espace
## écran, pour rester au-dessus de la caméra/du zoom.

signal building_placed(grid_pos: Vector2i, building: Building)
signal building_removed(grid_pos: Vector2i)

@export var grid_size: Vector2i = Vector2i(8, 8)
@export var cell_size: int = 64
## Conteneur où les bâtiments posés sont ajoutés (glisse "BuildingsContainer"
## depuis l'arborescence dans ce champ, dans l'Inspecteur).
@export var buildings_container: Node2D
## Voir note SETUP SCENE ci-dessus.
@export var removal_ui_layer: CanvasLayer

var _occupied_cells: Dictionary = {} # Vector2i -> Building
var _remove_button: Button = null
var _building_pending_removal: Building = null

func _ready() -> void:
	queue_redraw()
	GameManager.game_state_changed.connect(_on_game_state_changed)

## Debug visuel : dessine les cases de la grille. A remplacer plus tard par
## un vrai visuel de sol (sprite, TileMapLayer...).
func _draw() -> void:
	for x in range(grid_size.x):
		for y in range(grid_size.y):
			var rect := Rect2(Vector2(x, y) * cell_size, Vector2.ONE * cell_size)
			draw_rect(rect, Color(1, 1, 1, 0.15), false, 2.0)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Un clic sur la grille (hors bouton "✕", déjà géré par son propre
		# _gui_input avant d'arriver ici) ferme le popup de retrait ouvert.
		_clear_remove_button()
		var grid_pos := world_to_grid(to_local(get_global_mouse_position()))
		if is_within_grid(grid_pos):
			place_selected_building(grid_pos)

## --- Conversions ---
func world_to_grid(local_pos: Vector2) -> Vector2i:
	return Vector2i(floori(local_pos.x / cell_size), floori(local_pos.y / cell_size))

func grid_to_world(grid_pos: Vector2i) -> Vector2:
	return Vector2(
		grid_pos.x * cell_size + cell_size * 0.5,
		grid_pos.y * cell_size + cell_size * 0.5
	)

## --- Requêtes ---
func is_within_grid(grid_pos: Vector2i) -> bool:
	return grid_pos.x >= 0 and grid_pos.x < grid_size.x \
		and grid_pos.y >= 0 and grid_pos.y < grid_size.y

func is_cell_free(grid_pos: Vector2i) -> bool:
	return is_within_grid(grid_pos) and not _occupied_cells.has(grid_pos)

func get_building_at(grid_pos: Vector2i) -> Building:
	return _occupied_cells.get(grid_pos, null)

## --- Placement ---
## Pose le BuildingDefinition actuellement sélectionné dans BuildManager
## (voir BuildManager.selected_building, choisi en achetant au Shop).
func place_selected_building(grid_pos: Vector2i) -> bool:
	if not is_cell_free(grid_pos):
		return false
	var definition: BuildingDefinition = BuildManager.selected_building
	if definition == null or definition.scene == null:
		return false
	var building: Building = definition.scene.instantiate()
	buildings_container.add_child(building)
	building.global_position = to_global(grid_to_world(grid_pos))
	building.setup(grid_pos)
	building.source_definition = definition
	_occupied_cells[grid_pos] = building
	building.destroyed.connect(_on_building_destroyed.bind(grid_pos))
	building.clicked.connect(_on_building_clicked)
	BuildManager.consume_selected_building()
	building_placed.emit(grid_pos, building)
	return true

func _on_building_destroyed(_building: Building, grid_pos: Vector2i) -> void:
	if _building_pending_removal == _occupied_cells.get(grid_pos, null):
		_clear_remove_button()
	_occupied_cells.erase(grid_pos)
	building_removed.emit(grid_pos)

## --- Retrait vers l'inventaire : option 1, clic + croix ---
func _on_building_clicked(building: Building) -> void:
	if GameManager.state != GameManager.GameState.PREPARATION:
		return
	_show_remove_button(building)

func _show_remove_button(building: Building) -> void:
	_clear_remove_button()
	_building_pending_removal = building
	_remove_button = Button.new()
	_remove_button.text = "✕"
	_remove_button.custom_minimum_size = Vector2(28, 28)
	_remove_button.pressed.connect(_on_remove_confirmed)
	removal_ui_layer.add_child(_remove_button)
	_position_remove_button()

func _position_remove_button() -> void:
	if _remove_button == null or _building_pending_removal == null:
		return
	var screen_pos: Vector2 = get_viewport().get_canvas_transform() * _building_pending_removal.global_position
	_remove_button.position = screen_pos + Vector2(cell_size, -cell_size) * 0.25 - _remove_button.custom_minimum_size * 0.5

func _clear_remove_button() -> void:
	if _remove_button:
		_remove_button.queue_free()
		_remove_button = null
	_building_pending_removal = null

func _on_remove_confirmed() -> void:
	if _building_pending_removal == null:
		return
	var building := _building_pending_removal
	var definition := building.source_definition
	_clear_remove_button()
	finalize_building_removal(building)
	if definition:
		BuildManager.add_to_inventory(definition)

## --- Retrait vers l'inventaire : option 2, glisser-déposer ---
## Décroche le bâtiment de la grille sans le détruire (utilisé par
## PlacementGridDropZone au début d'un drag). A remettre en jeu avec
## return_building_to_grid() si le drop échoue, ou à finaliser avec
## finalize_building_removal() si le drop réussit.
func pick_up_building(grid_pos: Vector2i) -> Building:
	var building: Building = _occupied_cells.get(grid_pos, null)
	if building == null:
		return null
	if _building_pending_removal == building:
		_clear_remove_button()
	_occupied_cells.erase(grid_pos)
	building.visible = false
	building.input_pickable = false
	return building

## Remet un bâtiment décroché à sa place (drop raté).
func return_building_to_grid(building: Building) -> void:
	if building == null:
		return
	building.visible = true
	building.input_pickable = true
	_occupied_cells[building.grid_pos] = building

## Détruit définitivement un bâtiment décroché (drop réussi, ou retrait
## via le bouton "✕").
func finalize_building_removal(building: Building) -> void:
	if building == null:
		return
	var grid_pos := building.grid_pos
	_occupied_cells.erase(grid_pos) # no-op si déjà décroché via pick_up_building
	building.queue_free()
	building_removed.emit(grid_pos)

func _on_game_state_changed(new_state: GameManager.GameState) -> void:
	if new_state != GameManager.GameState.PREPARATION:
		_clear_remove_button()
