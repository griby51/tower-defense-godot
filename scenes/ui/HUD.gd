extends CanvasLayer
class_name HUD
## Affiche l'état du jeu en continu. Le bouton "Lancer la vague" ne sert
## qu'à démarrer la toute première vague : à partir de la vague 2, c'est
## le bouton "Vague suivante" du ShopPanel qui prend le relais.

@onready var _money_label: Label = $Root/MoneyLabel
@onready var _wave_label: Label = $Root/WaveLabel
@onready var _selected_label: Label = $Root/SelectedBuildingLabel
@onready var _start_wave_button: Button = $Root/StartWaveButton


func _ready() -> void:
	GameManager.money_changed.connect(_on_money_changed)
	GameManager.wave_changed.connect(_on_wave_changed)
	GameManager.game_state_changed.connect(_on_state_changed)
	BuildManager.selected_building_changed.connect(_on_selected_building_changed)
	_start_wave_button.pressed.connect(_on_start_wave_pressed)

	_on_money_changed(GameManager.money)
	_on_wave_changed(GameManager.current_wave)
	_on_state_changed(GameManager.state)
	_on_selected_building_changed(BuildManager.selected_building)


func _on_money_changed(amount: int) -> void:
	_money_label.text = "💰 %d" % amount


func _on_wave_changed(wave: int) -> void:
	_wave_label.text = "Vague %d" % wave


func _on_selected_building_changed(definition: BuildingDefinition) -> void:
	_selected_label.text = "Sélection : %s" % (definition.display_name if definition else "aucune")


func _on_state_changed(state: GameManager.GameState) -> void:
	# Le bouton s'affiche dès que le jeu est en phase de préparation
	_start_wave_button.visible = (state == GameManager.GameState.PREPARATION)


func _on_start_wave_pressed() -> void:
	GameManager.start_next_wave()
