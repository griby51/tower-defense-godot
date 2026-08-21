extends Building
class_name TurretBuilding
## Tourelle avec canon rotatif : vise la cible la plus proche dans sa
## portée, inflige des dégâts instantanés (hitscan, plus de projectile)
## et joue une animation de tir (flamme au bout du canon).
##
## SETUP SCENE requis ("Base" reste la base fixe déjà en place) :
## 1) Ajoute un Node2D enfant de Turret, nommé "Cannon" (centré sur le
##    pivot de rotation du canon). Mets-y le sprite du canon.
## 2) Ajoute un Marker2D enfant de "Cannon", nommé "MuzzlePoint", placé
##    au bout du canon (là où sort le tir).
## 3) Ajoute un AnimatedSprite2D enfant de "MuzzlePoint", nommé
##    "MuzzleFlash". Crée une ressource SpriteFrames avec une animation
##    "fire" contenant tes 4 sprites (PNG individuels), Loop = Off,
##    vitesse ~24 fps. Laisse-le invisible par défaut.

@export var attack_range: float = 150.0
@export var fire_rate: float = 1.0 # tirs par seconde
@export var damage: int = 10
@export var rotation_speed_degrees: float = 360.0 # vitesse de rotation du canon, °/s
@export var muzzle_flash_spread_degrees: float = 0.0 # variation cosmétique de l'angle du flash (optionnel)
@export var recoil_distance: float = 6.0 # recul du canon en pixels
@export var recoil_out_duration: float = 0.05 # temps pour reculer
@export var recoil_return_duration: float = 0.15 # temps pour revenir en place
@export var max_aim_error_degrees: float = 5.0 # tolérance d'alignement avant de pouvoir tirer

@onready var _range_area: Area2D = $RangeArea
@onready var _fire_timer: Timer = $FireTimer
@onready var _cannon: Node2D = $Cannon
@onready var _muzzle_flash: AnimatedSprite2D = $Cannon/MuzzlePoint/MuzzleFlash

var _enemies_in_range: Array[Node2D] = []
var _current_target: Node2D = null
## Rotation locale de MuzzleFlash telle que réglée dans l'éditeur (sert à
## compenser l'orientation propre du sprite de flamme, ex. dessiné vers
## le haut plutôt que vers la droite). Le tir n'ajoute que le jitter
## cosmétique par-dessus, sans jamais l'écraser.
var _muzzle_flash_base_rotation: float = 0.0
## Position locale de repos de Cannon (avant recul), mémorisée au démarrage.
var _cannon_rest_position: Vector2 = Vector2.ZERO
## Vrai pendant l'animation de recul : le canon ne peut pas tourner.
var _is_recoiling: bool = false
var _recoil_tween: Tween = null

func _ready() -> void:
	super._ready()
	_fire_timer.wait_time = 1.0 / fire_rate
	_fire_timer.timeout.connect(_on_fire_timer_timeout)
	_fire_timer.start()
	_range_area.body_entered.connect(_on_body_entered)
	_range_area.body_exited.connect(_on_body_exited)
	_cannon_rest_position = _cannon.position
	if _muzzle_flash:
		_muzzle_flash_base_rotation = _muzzle_flash.rotation
		_muzzle_flash.visible = false
		_muzzle_flash.animation_finished.connect(_on_muzzle_flash_finished)

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

func _on_fire_timer_timeout() -> void:
	if _current_target and is_instance_valid(_current_target) and _is_aimed_at(_current_target):
		_fire_at(_current_target)

## Vrai si le canon pointe déjà (à max_aim_error_degrees près) vers la
## cible. Évite de tirer "dans le vide" pendant que le canon tourne
## encore (ex. juste après le recul, qui bloque la rotation).
func _is_aimed_at(target: Node2D) -> bool:
	var target_angle := (target.global_position - _cannon.global_position).angle()
	var diff := absf(wrapf(target_angle - _cannon.global_rotation, -PI, PI))
	return diff <= deg_to_rad(max_aim_error_degrees)

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

## Dégâts instantanés (hitscan) : pas de trajectoire, pas de délai de vol.
func _fire_at(target: Node2D) -> void:
	if not is_instance_valid(target):
		return
	if target.has_method("take_damage"):
		target.take_damage(damage)
	_play_muzzle_flash()
	_play_recoil()

## Recul du canon : part en arrière (le long de son axe de visée actuel)
## puis revient à sa position de repos. Bloque la rotation pendant ce
## temps via _is_recoiling (voir _process).
func _play_recoil() -> void:
	if _recoil_tween and _recoil_tween.is_valid():
		_recoil_tween.kill()
	_is_recoiling = true
	_cannon.position = _cannon_rest_position
	var recoil_offset := _cannon_rest_position + Vector2(-recoil_distance, 0).rotated(_cannon.rotation)
	_recoil_tween = create_tween()
	_recoil_tween.tween_property(_cannon, "position", recoil_offset, recoil_out_duration) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_recoil_tween.tween_property(_cannon, "position", _cannon_rest_position, recoil_return_duration) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_recoil_tween.finished.connect(_on_recoil_finished)

func _on_recoil_finished() -> void:
	_is_recoiling = false

func _play_muzzle_flash() -> void:
	if _muzzle_flash == null:
		return
	var jitter := 0.0
	if muzzle_flash_spread_degrees > 0.0:
		jitter = deg_to_rad(randf_range(-muzzle_flash_spread_degrees, muzzle_flash_spread_degrees) / 2.0)
	_muzzle_flash.rotation = _muzzle_flash_base_rotation + jitter
	_muzzle_flash.visible = true
	_muzzle_flash.play("fire")

func _on_muzzle_flash_finished() -> void:
	_muzzle_flash.visible = false
