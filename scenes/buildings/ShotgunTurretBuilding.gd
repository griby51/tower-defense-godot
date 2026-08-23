extends TurretBase
class_name ShotgunTurretBuilding
## Tourelle shotgun : comme TurretBuilding (un canon qui tourne, recul
## qui bloque la rotation), mais tire plusieurs vrais Projectile en
## éventail à chaque coup au lieu d'un hitscan unique. Pas de sprite de
## tir animé au bout du canon.
##
## SETUP SCENE ("Base" reste la base fixe déjà en place) :
## 1) "Cannon" (Node2D, pivot de rotation, contient le sprite du canon).
## 2) "Cannon/MuzzlePoint" (Marker2D, au bout du canon — pas de
##    MuzzleFlash dessus, juste le point de sortie des projectiles).
## 3) Assigner "Projectile Scene" dans l'Inspecteur (scène avec le script
##    Projectile.gd déjà utilisé par tes autres tourelles).

@export var pellet_count: int = 6
@export var spread_degrees: float = 30.0 # angle total de l'éventail, en degrés
@export var pellet_damage: int = 4
@export var projectile_scene: PackedScene
@export var projectile_lifetime: float = 1.0
@export var projectile_fade_duration: float = 0.3
@export var recoil_distance: float = 8.0
@export var recoil_out_duration: float = 0.05
@export var recoil_return_duration: float = 0.15

@onready var _muzzle_point: Marker2D = $Cannon/MuzzlePoint

## Position locale de repos de Cannon (avant recul), mémorisée au démarrage.
var _cannon_rest_position: Vector2 = Vector2.ZERO
var _recoil_tween: Tween = null

func _ready() -> void:
	super._ready()
	_cannon_rest_position = _cannon.position

func _fire_at(target: Node2D) -> void:
	if not is_instance_valid(target):
		return
	_fire_pellets(target)
	_play_recoil()

## Tire pellet_count projectiles répartis sur un cône de spread_degrees
## centré sur la direction de la cible (avec un peu d'aléatoire pour
## éviter un éventail parfaitement régulier).
func _fire_pellets(target: Node2D) -> void:
	if projectile_scene == null:
		return
	var origin := _muzzle_point.global_position
	var base_angle := (target.global_position - origin).angle()
	var half_spread := deg_to_rad(spread_degrees / 2.0)
	for i in pellet_count:
		var t := 0.5 if pellet_count <= 1 else float(i) / float(pellet_count - 1)
		var angle := lerpf(-half_spread, half_spread, t)
		angle += randf_range(-half_spread, half_spread) * 0.15
		var pellet_dir := Vector2.RIGHT.rotated(base_angle + angle)
		# Point lointain dans la bonne direction : Projectile n'a besoin
		# que de la direction, pas d'un point d'impact précis.
		var aim_point := origin + pellet_dir * 1000.0

		var projectile := projectile_scene.instantiate() as Projectile
		if not projectile:
			continue
		get_tree().current_scene.add_child(projectile)
		projectile.global_position = origin
		projectile.setup(aim_point, pellet_damage, projectile_lifetime, projectile_fade_duration)

## Recul du canon (identique à TurretBuilding) : bloque la rotation le
## temps de l'animation, via _is_recoiling hérité de TurretBase.
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
