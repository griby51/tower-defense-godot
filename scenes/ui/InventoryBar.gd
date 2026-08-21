extends HBoxContainer
class_name InventoryBar
## Affiche tous les bâtiments actuellement possédés par le joueur, groupés
## par type ("Mur x3" plutôt que 3 cases séparées). Se reconstruit
## automatiquement à chaque achat ou pose (BuildManager.inventory_changed).
## Se cache automatiquement pendant WAVE_IN_PROGRESS (GameManager.state).
## Glisse InventorySlot.tscn dans ce champ, depuis l'Inspecteur.

@export var slot_scene: PackedScene

func _ready() -> void:
	BuildManager.inventory_changed.connect(_on_inventory_changed)
	GameManager.game_state_changed.connect(_on_game_state_changed)
	_on_inventory_changed(BuildManager.inventory)
	_on_game_state_changed(GameManager.state)

func _on_inventory_changed(inventory: Array[BuildingDefinition]) -> void:
	for child in get_children():
		child.queue_free()
	# Regroupe les doublons (même Resource) pour afficher un compteur.
	var counts: Dictionary = {}
	var order: Array[BuildingDefinition] = []
	for definition in inventory:
		if not counts.has(definition):
			counts[definition] = 0
			order.append(definition)
		counts[definition] += 1
	for definition in order:
		var slot: InventorySlot = slot_scene.instantiate()
		add_child(slot)
		slot.setup(definition, counts[definition])

## Cache (et désactive) la barre pendant les vagues, pour éviter d'acheter
## un placement pendant que les ennemis avancent.
func _on_game_state_changed(new_state: GameManager.GameState) -> void:
	visible = (new_state == GameManager.GameState.PREPARATION)

## --- Cible de drop pour le retrait par glisser-déposer depuis la grille ---
## L'ajout réel à BuildManager.inventory est fait par PlacementGridDropZone
## (NOTIFICATION_DRAG_END) ; ces deux méthodes servent uniquement à ce que
## Godot considère le drop comme "réussi" au-dessus de cette barre.
func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is BuildingDefinition

func _drop_data(_at_position: Vector2, _data: Variant) -> void:
	pass
