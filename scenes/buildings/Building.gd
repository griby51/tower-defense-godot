extends StaticBody2D
class_name Building
## Classe de base pour tout ce qui peut être posé sur la grille (mur, tourelle...).
## Placé sur le layer physique "buildings" pour que les ennemis le
## détectent naturellement via move_and_slide (voir Enemy.gd).

signal destroyed(building: Building)
signal health_changed(current: int, max: int)
## Émis quand le joueur clique sur le bâtiment (utilisé par PlacementGrid
## pour proposer le retrait vers l'inventaire pendant la préparation).
signal clicked(building: Building)

@export var max_health: int = 50
var current_health: int

## Position grille occupée (renseignée par PlacementGrid.setup()).
var grid_pos: Vector2i
## BuildingDefinition d'origine, renseignée par PlacementGrid juste après
## l'instanciation, pour pouvoir la remettre dans BuildManager.inventory
## si le joueur retire ce bâtiment.
var source_definition: BuildingDefinition

## Optionnelle : si ta scène a un enfant "HealthBar" (ProgressBar), il est
## mis à jour automatiquement. Sinon ce champ reste null, pas d'erreur.
@onready var _health_bar: ProgressBar = get_node_or_null("HealthBar")

func _ready() -> void:
	current_health = max_health
	add_to_group("buildings")
	input_pickable = true
	input_event.connect(_on_input_event)
	if _health_bar:
		_health_bar.max_value = max_health
		_health_bar.value = current_health

## Appelée par PlacementGrid juste après l'instanciation, avec la
## coordonnée grille occupée.
func setup(grid_pos: Vector2i) -> void:
	self.grid_pos = grid_pos

func take_damage(amount: int) -> void:
	if current_health <= 0:
		return
	current_health = max(0, current_health - amount)
	health_changed.emit(current_health, max_health)
	if _health_bar:
		_health_bar.value = current_health
	if current_health == 0:
		die()

func die() -> void:
	destroyed.emit(self)
	queue_free()

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		clicked.emit(self)
