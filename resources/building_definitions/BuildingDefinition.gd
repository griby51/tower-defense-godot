extends Resource
class_name BuildingDefinition
## Une "carte" du catalogue de bâtiments. Ce n'est PAS un nœud de scène :
## c'est une fiche de données que tu crées dans l'éditeur (clic droit dans
## le dossier resources/building_definitions/ > New Resource > BuildingDefinition)
## pour chaque type de bâtiment (Mur, Tourelle, Pique...).
##
## Le Shop pioche aléatoirement dans une liste de BuildingDefinition, et
## BuildManager/PlacementGrid utilisent le champ "scene" pour instancier
## le vrai Building une fois acheté.

enum Rarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }

@export var display_name: String = "Bâtiment"
@export_multiline var description: String = ""
@export var scene: PackedScene
@export var cost: int = 20
@export var icon: Texture2D
@export var rarity: Rarity = Rarity.COMMON

## Poids de tirage par rareté : plus le nombre est grand, plus la carte
## sort souvent. Modifie ces valeurs pour ajuster le drop rate global.
static var rarity_weights: Dictionary = {
	Rarity.COMMON: 100,
	Rarity.UNCOMMON: 50,
	Rarity.RARE: 20,
	Rarity.EPIC: 8,
	Rarity.LEGENDARY: 2,
}

## Couleur de fond de carte associée à chaque rareté (ShopOfferCard).
static var rarity_colors: Dictionary = {
	Rarity.COMMON: Color(0.6, 0.6, 0.6),      # gris
	Rarity.UNCOMMON: Color(0.2, 0.75, 0.2),   # vert
	Rarity.RARE: Color(0.2, 0.45, 0.9),       # bleu
	Rarity.EPIC: Color(0.6, 0.2, 0.85),       # violet
	Rarity.LEGENDARY: Color(0.9, 0.65, 0.1),  # orange/or
}

func get_rarity_weight() -> int:
	return rarity_weights.get(rarity, 1)

func get_rarity_color() -> Color:
	return rarity_colors.get(rarity, Color.WHITE)
