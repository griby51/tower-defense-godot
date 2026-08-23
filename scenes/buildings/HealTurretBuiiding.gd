extends Building
class_name HealTurretBuilding
## Tourelle de soin : cible en continu le bâtiment le plus endommagé (le
## plus faible % de vie restante) parmi TOUS les bâtiments de la partie —
## aucune limite de portée, aucun canon/visée : le HealProjectile part
## par magie du centre de la tourelle directement vers sa cible.
##
## SETUP SCENE ("Base" reste la base fixe déjà en place) :
## 1) "FireTimer" (Timer).
## 2) Assigner "Heal Projectile Scene" dans l'Inspecteur : une scène dont
##    le script est HealProjectile.gd (root Node2D, comme Projectile).

@export var fire_rate: float = 0.5 # tirs par seconde
@export var heal_amount: int = 10
@export var projectile_lifetime: float = 2.0
@export var projectile_fade_duration: float = 0.5
@export var heal_projectile_scene: PackedScene

@onready var _fire_timer: Timer = $FireTimer

func _ready() -> void:
	super._ready()
	_fire_timer.wait_time = 1.0 / fire_rate
	_fire_timer.timeout.connect(_on_fire_timer_timeout)
	_fire_timer.start()

## Le bâtiment avec le plus faible % de vie restante, hors lui-même et
## hors bâtiments déjà à pleine vie (rien à soigner sinon).
func _get_most_damaged_building() -> Building:
	var best: Building = null
	var best_ratio := 1.0
	for building in get_tree().get_nodes_in_group("buildings"):
		if building == self or not is_instance_valid(building) or not (building is Building):
			continue
		if building.max_health <= 0 or building.current_health >= building.max_health:
			continue
		var ratio: float = float(building.current_health) / float(building.max_health)
		if ratio < best_ratio:
			best_ratio = ratio
			best = building
	return best

func _on_fire_timer_timeout() -> void:
	var target := _get_most_damaged_building()
	if target:
		_fire_at(target)

func _fire_at(target: Building) -> void:
	if heal_projectile_scene == null:
		return
	var projectile := heal_projectile_scene.instantiate() as HealProjectile
	if not projectile:
		return
	get_tree().current_scene.add_child(projectile)
	projectile.global_position = global_position
	projectile.setup_heal(target, heal_amount, projectile_lifetime, projectile_fade_duration)
