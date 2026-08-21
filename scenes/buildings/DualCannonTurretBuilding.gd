extends TurretBase
class_name DualCannonTurretBuilding
## Même tourelle que TurretBuilding (un seul sprite de canon qui tourne),
## mais avec deux points de flamme (le canon a deux sorties visuelles) et
## un recul plus léger qui NE bloque PAS la rotation — le canon continue
## de viser normalement pendant le recul.
##
## SETUP SCENE ("Base" reste la base fixe déjà en place) :
## 1) "Cannon" (Node2D, pivot de rotation, contient le sprite du canon).
## 2) "Cannon/MuzzlePoint1" et "Cannon/MuzzlePoint2" (Marker2D, chacun à
##    une sortie du canon).
##    - Chacun contient un enfant "MuzzleFlash" (AnimatedSprite2D, anim
##      "fire", invisible par défaut).

@export var muzzle_flash_spread_degrees: float = 0.0 # variation cosmétique de l'angle du flash (optionnel)
@export var recoil_distance: float = 3.0 # recul du canon en pixels (réduit)
@export var recoil_out_duration: float = 0.04
@export var recoil_return_duration: float = 0.12

@onready var _muzzle_flashes: Array[AnimatedSprite2D] = [
	$Cannon/MuzzlePoint1/MuzzleFlash,
	$Cannon/MuzzlePoint2/MuzzleFlash,
]

var _flash_base_rotations: Array[float] = []
var _cannon_rest_position: Vector2 = Vector2.ZERO
var _recoil_tween: Tween = null

func _ready() -> void:
	super._ready()
	_cannon_rest_position = _cannon.position
	for flash in _muzzle_flashes:
		if flash:
			_flash_base_rotations.append(flash.rotation)
			flash.visible = false
			flash.animation_finished.connect(_on_muzzle_flash_finished.bind(flash))
		else:
			_flash_base_rotations.append(0.0)

func _on_muzzle_flash_finished(flash: AnimatedSprite2D) -> void:
	flash.visible = false

func _fire_at(target: Node2D) -> void:
	super._fire_at(target)
	for i in _muzzle_flashes.size():
		_play_muzzle_flash(i)
	_play_recoil()

func _play_muzzle_flash(index: int) -> void:
	var flash := _muzzle_flashes[index]
	if flash == null:
		return
	var jitter := 0.0
	if muzzle_flash_spread_degrees > 0.0:
		jitter = deg_to_rad(randf_range(-muzzle_flash_spread_degrees, muzzle_flash_spread_degrees) / 2.0)
	flash.rotation = _flash_base_rotations[index] + jitter
	flash.visible = true
	flash.play("fire")

## Recul léger du canon. NE touche PAS _is_recoiling : la rotation
## (héritée de TurretBase) continue normalement pendant l'animation.
func _play_recoil() -> void:
	if _recoil_tween and _recoil_tween.is_valid():
		_recoil_tween.kill()
	_cannon.position = _cannon_rest_position
	var recoil_offset := _cannon_rest_position + Vector2(-recoil_distance, 0).rotated(_cannon.rotation)
	_recoil_tween = create_tween()
	_recoil_tween.tween_property(_cannon, "position", recoil_offset, recoil_out_duration) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_recoil_tween.tween_property(_cannon, "position", _cannon_rest_position, recoil_return_duration) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
