extends Building
class_name TurretBase
## Base commune à toutes les tourelles hitscan : détection de portée,
## acquisition de la cible la plus proche, rotation du canon vers elle,
## et déclenchement du tir au bon rythme (uniquement quand le canon est
## effectivement aligné).
##
## Les sous-classes (TurretBuilding = un canon, DualCannonTurretBuilding =
## deux canons...) définissent seulement l'effet visuel du tir (flamme,
## recul...) en surchargeant _fire_at() — en appelant toujours
## `super._fire_at(target)` en premier pour infliger les dégâts.

@export var attack_range: float = 150.0
@export var fire_rate: float = 1.0 # tirs par seconde
@export var damage: int = 10
@export var rotation_speed_degrees: float = 360.0 # vitesse de rotation du canon, °/s
@export var max_aim_error_degrees: float = 5.0 # tolérance d'alignement avant de pouvoir tirer

@onready var _range_area: Area2D = $RangeArea
@onready var _fire_timer: Timer = $FireTimer
@onready var _cannon: Node2D = $Cannon

var _enemies_in_range: Array[Node2D] = []
var _current_target: Node2D = null
## Mettre à true dans une sous-classe pour bloquer temporairement la
## rotation du canon (ex. le temps d'une animation de recul partagée).
var _is_recoiling: bool = false

func _ready() -> void:
	super._ready()
	_fire_timer.wait_time = 1.0 / fire_rate
	_fire_timer.timeout.connect(_on_fire_timer_timeout)
	_fire_timer.start()
	_range_area.body_entered.connect(_on_body_entered)
	_range_area.body_exited.connect(_on_body_exited)

func _process(delta: float) -> void:
	_current_target = _get_closest_enemy()
	if _is_recoiling:
		return
	if _current_target and is_instance_valid(_current_target):
		_aim_at(_current_target.global_position, delta)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies"):
		_enemies_in_range.append(body)

func _on_body_exited(body: Node2D) -> void:
	_enemies_in_range.erase(body)

func _get_closest_enemy() -> Node2D:
	var closest: Node2D = null
	var closest_dist := INF
	for enemy in _enemies_in_range:
		if not is_instance_valid(enemy):
			continue
		var dist := global_position.distance_to(enemy.global_position)
		if dist < closest_dist:
			closest_dist = dist
			closest = enemy
	return closest

## Tourne le canon progressivement vers la cible (limité par
## rotation_speed_degrees, en degrés/seconde).
func _aim_at(target_global_pos: Vector2, delta: float) -> void:
	var target_angle := (target_global_pos - _cannon.global_position).angle()
	var max_step := deg_to_rad(rotation_speed_degrees) * delta
	_cannon.global_rotation = rotate_toward(_cannon.global_rotation, target_angle, max_step)

## Vrai si le canon pointe déjà (à max_aim_error_degrees près) vers la
## cible. Évite de tirer "dans le vide" pendant que le canon tourne
## encore.
func _is_aimed_at(target: Node2D) -> bool:
	var target_angle := (target.global_position - _cannon.global_position).angle()
	var diff := absf(wrapf(target_angle - _cannon.global_rotation, -PI, PI))
	return diff <= deg_to_rad(max_aim_error_degrees)

func _on_fire_timer_timeout() -> void:
	if _current_target and is_instance_valid(_current_target) and _is_aimed_at(_current_target):
		_fire_at(_current_target)

## Dégâts instantanés (hitscan). À surcharger dans les sous-classes pour
## ajouter l'effet visuel (toujours appeler super._fire_at() en premier).
func _fire_at(target: Node2D) -> void:
	if not is_instance_valid(target):
		return
	if target.has_method("take_damage"):
		target.take_damage(damage)
