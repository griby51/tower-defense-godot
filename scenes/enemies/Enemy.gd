extends CharacterBody2D
class_name Enemy
## Classe de base de tous les ennemis. Une variante (rapide, tank, volant...)
## crée un nouveau script "extends Enemy" et ne redéfinit que ce qui change
## (vitesse, vie, _ready pour une anim différente, etc.).
##
## Mouvement : avance vers le bas de l'écran et s'arrête pour attaquer
## le premier Building rencontré sur sa route.
##
## Séparation douce : PAS de collision physique entre ennemis (ils ne sont
## PAS sur le même layer physique entre eux, uniquement vs "buildings" et
## les murs de niveau). À la place, une petite Area2D ("SeparationArea")
## maintient une liste de voisins proches par simples signaux
## body_entered/body_exited. Chaque frame, on calcule juste une moyenne de
## vecteurs de répulsion sur CETTE liste (quelques éléments), jamais un
## scan de tous les ennemis de la horde : le coût reste O(voisins proches),
## pas O(n²), même avec des centaines de zombies à l'écran.

signal died(enemy: Enemy)
signal reached_goal(enemy: Enemy)

@export var max_health: int = 20
@export var speed: float = 60.0
@export var damage: int = 5
@export var attack_interval: float = 1.0
@export var money_reward: int = 5
@export var hit_radius: float = 22

@export_group("Séparation douce")
## Rayon (px) dans lequel un voisin repousse cet ennemi. Doit correspondre
## au rayon du CollisionShape2D de SeparationArea.
@export var separation_radius: float = 28.0
## Force de répulsion relative à la vitesse de marche. 0 = désactivé.
@export var separation_strength: float = 40.0

var current_health: int

var _neighbours: Array[Node2D] = []
var _current_target_building: Building = null
var _attack_timer: float = 0.0
var _is_attacking: bool = false

@onready var _separation_area: Area2D = $SeparationArea


func _ready() -> void:
	current_health = max_health
	add_to_group("enemies")
	_separation_area.body_entered.connect(_on_separation_area_body_entered)
	_separation_area.body_exited.connect(_on_separation_area_body_exited)
	GameManager.register_enemy_spawned()


func _physics_process(delta: float) -> void:
	if _is_attacking:
		_process_attack(delta)
		return

	velocity = _compute_movement_direction() * speed
	move_and_slide()
	_check_building_collision()


## --- Mouvement ---

func _compute_movement_direction() -> Vector2:
	var forward := Vector2.DOWN
	var separation := _compute_separation_vector()
	var result := (forward + separation).normalized()
	return result if result != Vector2.ZERO else forward


func _compute_separation_vector() -> Vector2:
	if _neighbours.is_empty():
		return Vector2.ZERO

	var push := Vector2.ZERO
	var count := 0
	for neighbour in _neighbours:
		if not is_instance_valid(neighbour):
			continue
		var offset: Vector2 = global_position - neighbour.global_position
		var dist: float = offset.length()
		if dist > 0.001 and dist < separation_radius:
			# Plus le voisin est proche, plus la répulsion est forte.
			push += offset.normalized() * (1.0 - dist / separation_radius)
			count += 1

	if count == 0:
		return Vector2.ZERO
	return (push / count) * (separation_strength / speed)


func _on_separation_area_body_entered(body: Node2D) -> void:
	if body != self and body.is_in_group("enemies"):
		_neighbours.append(body)


func _on_separation_area_body_exited(body: Node2D) -> void:
	_neighbours.erase(body)


## --- Combat contre les bâtiments ---

func _check_building_collision() -> void:
	for i in get_slide_collision_count():
		var collider := get_slide_collision(i).get_collider()
		if collider is Building:
			_start_attacking(collider)
			return


func _start_attacking(building: Building) -> void:
	_is_attacking = true
	_current_target_building = building
	_attack_timer = 0.0
	building.destroyed.connect(_on_target_destroyed, CONNECT_ONE_SHOT)


func _process_attack(delta: float) -> void:
	if not is_instance_valid(_current_target_building):
		_stop_attacking()
		return
	_attack_timer += delta
	if _attack_timer >= attack_interval:
		_attack_timer = 0.0
		_current_target_building.take_damage(damage)


func _on_target_destroyed(_building: Building) -> void:
	_stop_attacking()


func _stop_attacking() -> void:
	_is_attacking = false
	_current_target_building = null


## --- Vie ---

func take_damage(amount: int) -> void:
	if current_health <= 0:
		return
	current_health = max(0, current_health - amount)
	if current_health == 0:
		die()


func die() -> void:
	GameManager.add_money(money_reward)
	GameManager.register_enemy_defeated()
	died.emit(self)
	queue_free()
