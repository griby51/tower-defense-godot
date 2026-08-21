extends PanelContainer
class_name ShopOfferCard
## Une "carte" du shop : affiche un BuildingDefinition et permet de
## l'acheter. Se désactive automatiquement une fois achetée, se grise
## automatiquement si le joueur n'a plus assez d'argent, et affiche un
## fond coloré selon la rareté du bâtiment.

signal purchase_requested(definition: BuildingDefinition)

@onready var _name_label: Label = $Margin/VBox/NameLabel
@onready var _cost_label: Label = $Margin/VBox/CostLabel
@onready var _icon_rect: TextureRect = $Margin/VBox/Icon
@onready var _buy_button: Button = $Margin/VBox/BuyButton

var _definition: BuildingDefinition
var _purchased: bool = false

func _ready() -> void:
	_buy_button.pressed.connect(_on_buy_pressed)
	GameManager.money_changed.connect(_on_money_changed)

## Appelée par ShopPanel pour afficher une nouvelle offre sur cette carte.
func setup(definition: BuildingDefinition) -> void:
	_definition = definition
	_purchased = false
	_name_label.text = definition.display_name
	_cost_label.text = "%d 💰" % definition.cost
	_icon_rect.texture = definition.icon
	_buy_button.text = "Acheter"
	_buy_button.disabled = not GameManager.can_afford(definition.cost)
	_apply_rarity_style(definition.get_rarity_color())

func _apply_rarity_style(color: Color) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(6)
	style.set_content_margin_all(6)
	add_theme_stylebox_override("panel", style)

func _on_money_changed(_new_amount: int) -> void:
	if _definition != null and not _purchased:
		_buy_button.disabled = not GameManager.can_afford(_definition.cost)

func _on_buy_pressed() -> void:
	if _purchased or _definition == null:
		return
	if not GameManager.spend_money(_definition.cost):
		return
	_purchased = true
	_buy_button.text = "Acheté"
	_buy_button.disabled = true
	purchase_requested.emit(_definition)
