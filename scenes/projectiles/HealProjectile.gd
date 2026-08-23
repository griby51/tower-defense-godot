extends Projectile
class_name HealProjectile
## Variante de Projectile qui ne peut toucher QUE sa cible verrouillée à
## l'instant du tir (pas de scan du groupe "enemies" comme le Projectile
## de base) : soigne uniquement cette cible au contact, jamais un autre
## bâtiment croisé en chemin.

var _target: Node2D = null
var _heal_amount: int = 0

## À appeler à la place de setup() : verrouille la cible, puis délègue
## au setup() de base pour la trajectoire/durée de vie (damage = 0, non
## utilisé ici).
func setup_heal(target: Node2D, heal_amount: int, lifetime: float = 2.0, fade_duration: float = 0.5) -> void:
	_target = target
	_heal_amount = heal_amount
	setup(target.global_position, 0, lifetime, fade_duration)

## Surcharge : ignore le groupe "enemies", ne teste que la cible verrouillée.
func _check_enemy_hits() -> void:
	if _target == null or not is_instance_valid(_target):
		queue_free()
		return
	var target_radius: float = _target.get("hit_radius") if _target.get("hit_radius") != null else 16.0
	var min_dist := projectile_radius + target_radius
	if global_position.distance_squared_to(_target.global_position) < (min_dist * min_dist):
		if _target.has_method("heal"):
			_target.heal(_heal_amount)
		queue_free()
