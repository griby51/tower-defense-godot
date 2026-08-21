extends PanelContainer
class_name InventorySlot
## Une case d'inventaire = un type de bâtiment possédé, avec son compteur
## ("Mur x3"). Peut être glissée (drag) vers la grille pour poser un
## exemplaire, ou simplement cliquée pour le sélectionner (plus fiable
## sur tactile/mobile, où le drag est parfois capricieux).

@onready var _icon: TextureRect = $VBox/Icon
@onready var _name_label: Label = $VBox/NameLabel
@onready var _count_label: Label = $VBox/CountLabel

var definition: BuildingDefinition


func setup(def: BuildingDefinition, count: int) -> void:
	definition = def
	_icon.texture = def.icon
	_name_label.text = def.display_name
	set_count(count)


func set_count(count: int) -> void:
	_count_label.text = "x%d" % count


## --- Glisser-déposer natif de Godot ---
## Appelée automatiquement par le moteur quand le joueur commence à
## faire glisser cette case. Ce qu'on retourne ici (le BuildingDefinition)
## est ce que la cible (PlacementGridDropZone) recevra dans _drop_data.
func _get_drag_data(_at_position: Vector2) -> Variant:
	if definition == null:
		return null

	var preview := TextureRect.new()
	preview.texture = definition.icon
	preview.custom_minimum_size = Vector2(48, 48)
	set_drag_preview(preview) # la vignette qui suit la souris pendant le glisser

	BuildManager.select_building(definition)
	return definition


## Simple clic = sélectionne aussi, sans avoir besoin de glisser jusqu'à la grille.
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if definition:
			BuildManager.select_building(definition)
