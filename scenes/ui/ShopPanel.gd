extends CanvasLayer
class_name ShopPanel
## S'ouvre automatiquement quand GameManager émet "wave_cleared" : met le
## jeu en pause, tire "offers_count" BuildingDefinition au hasard (avec
## doublons possibles, pondérés par rareté) et instancie une carte par
## offre dans un GridContainer à 5 colonnes (2 lignes de 5). Le joueur
## peut en acheter, puis clique sur "Vague suivante" pour reprendre.
##
## IMPORTANT (setup scène, à faire une seule fois dans l'éditeur) :
## 1) Le nœud racine (PanelRoot, ou ce CanvasLayer) doit avoir son
##    "Process Mode" réglé sur "Always", sinon ses boutons restent
##    gelés pendant la pause.
## 2) Le conteneur "Offers" doit être un GridContainer (pas un simple
##    BoxContainer) : clic droit sur le nœud > "Change Type..." >
##    GridContainer. Le nombre de colonnes est fixé à 5 dans _ready().
## 3) Assigner "Offer Card Scene" dans l'Inspecteur avec ton
##    ShopOfferCard.tscn (les cartes ne sont plus fixes dans la scène,
##    elles sont instanciées à chaque ouverture du shop).

@export var building_catalog: Array[BuildingDefinition] = []
@export var offers_count: int = 10
@export var offer_card_scene: PackedScene

@onready var _panel: Control = $PanelRoot
@onready var _title_label: Label = $PanelRoot/VBox/TitleLabel
@onready var _continue_button: Button = $PanelRoot/VBox/ContinueButton
@onready var _offers_container: GridContainer = $PanelRoot/VBox/Offers

func _ready() -> void:
	_panel.visible = false
	_offers_container.columns = 5
	_continue_button.pressed.connect(_on_continue_pressed)
	GameManager.wave_cleared.connect(_on_wave_cleared)

func _on_wave_cleared(wave_number: int) -> void:
	_title_label.text = "Vague %d terminée ! Choisis ton renfort :" % wave_number
	_open_shop()

func _open_shop() -> void:
	for child in _offers_container.get_children():
		child.queue_free()

	var offers := _pick_random_offers(offers_count)
	for definition in offers:
		var card: ShopOfferCard = offer_card_scene.instantiate()
		_offers_container.add_child(card)
		card.purchase_requested.connect(_on_offer_purchased)
		card.setup(definition)

	_panel.visible = true
	get_tree().paused = true

## Tirage pondéré par rareté (BuildingDefinition.rarity_weights).
## Chaque slot est tiré indépendamment avec remise -> doublons possibles.
func _pick_random_offers(count: int) -> Array[BuildingDefinition]:
	var result: Array[BuildingDefinition] = []
	if building_catalog.is_empty():
		return result

	var total_weight := 0
	for def in building_catalog:
		total_weight += def.get_rarity_weight()

	for i in count:
		var roll := randi() % total_weight
		var cumulative := 0
		for def in building_catalog:
			cumulative += def.get_rarity_weight()
			if roll < cumulative:
				result.append(def)
				break

	return result

func _on_offer_purchased(definition: BuildingDefinition) -> void:
	BuildManager.add_to_inventory(definition)

func _on_continue_pressed() -> void:
	_panel.visible = false
	get_tree().paused = false
	# Passe l'état en PREPARATION : cela va déclencher le signal
	# game_state_changed reçu par le HUD
	GameManager.state = GameManager.GameState.PREPARATION
