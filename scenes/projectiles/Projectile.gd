extends Node2D
class_name Projectile

@export var speed: float = 400.0
@export var projectile_radius: float = 4.0 # Rayon du projectile lui-même

var _direction: Vector2 = Vector2.ZERO
var _damage: int = 0
var _lifetime: float = 2.0
var _fade_duration: float = 0.5
var _is_fading: bool = false


func setup(target_position: Vector2, damage: int, lifetime: float = 2.0, fade_duration: float = 0.5) -> void:
	_damage = damage
	_lifetime = lifetime
	_fade_duration = fade_duration
	_direction = (target_position - global_position).normalized()
	rotation = _direction.angle()
	
	_start_lifetime_timer()


func _physics_process(delta: float) -> void:
	global_position += _direction * speed * delta
	
	if _is_fading:
		return
		
	_check_enemy_hits()


func _check_enemy_hits() -> void:
	var enemies := get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if not is_instance_valid(enemy) or not (enemy is Node2D):
			continue
			
		# Récupère le rayon propre de l'ennemi (fallback à 16.0 s'il n'est pas défini)
		var enemy_radius: float = enemy.get("hit_radius") if enemy.get("hit_radius") != null else 16.0
		var min_dist := projectile_radius + enemy_radius
		
		# Test de collision circulaire basé sur la taille de l'ennemi touché
		if global_position.distance_squared_to(enemy.global_position) < (min_dist * min_dist):
			if enemy.has_method("take_damage"):
				enemy.take_damage(_damage)
			queue_free()
			return


func _start_lifetime_timer() -> void:
	var wait_time := maxf(0.05, _lifetime - _fade_duration)
	await get_tree().create_timer(wait_time).timeout
	
	if is_instance_valid(self) and not _is_fading:
		_fade_and_destroy()


func _fade_and_destroy() -> void:
	_is_fading = true
	
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, _fade_duration)
	tween.finished.connect(queue_free)
