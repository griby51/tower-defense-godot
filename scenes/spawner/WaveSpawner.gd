extends Node2D
class_name WaveSpawner
## Instancie les ennemis d'une vague. Se déclenche tout seul dès que
## GameManager.current_wave change (donc dès qu'on appelle
## GameManager.start_next_wave() depuis le bouton HUD ou le Shop) :
## aucun appel manuel n'est nécessaire depuis Main.

signal wave_spawning_started(wave_number: int)
signal wave_spawning_finished(wave_number: int)

## Les scènes d'ennemis pouvant apparaître (Enemy.tscn, EnemyFast.tscn...).
## Une est choisie au hasard à chaque spawn.
@export var enemy_scenes: Array[PackedScene] = []
@export var base_enemy_count: int = 5
@export var enemy_count_increment: int = 2
@export var spawn_interval: float = 0.6
## Conteneur où les ennemis instanciés sont ajoutés (glisse "EnemiesContainer"
## depuis l'arborescence de Main dans ce champ, dans l'Inspecteur).
@export var enemies_container: Node2D

@onready var _spawn_timer: Timer = $SpawnTimer
@onready var _spawn_points: Node2D = $SpawnPoints

var _enemies_to_spawn: int = 0


func _ready() -> void:
	_spawn_timer.wait_time = spawn_interval
	_spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	GameManager.wave_changed.connect(_on_wave_changed)


func _on_wave_changed(new_wave: int) -> void:
	# wave 0 = état initial au reset_game(), pas une vraie vague à spawn.
	if new_wave <= 0:
		return
	start_wave(new_wave)


func start_wave(wave_number: int) -> void:
	_enemies_to_spawn = base_enemy_count + (wave_number - 1) * enemy_count_increment
	GameManager.set_spawning(true)
	wave_spawning_started.emit(wave_number)
	_spawn_timer.start()


func _on_spawn_timer_timeout() -> void:
	_spawn_one_enemy()
	_enemies_to_spawn -= 1
	if _enemies_to_spawn <= 0:
		_spawn_timer.stop()
		GameManager.set_spawning(false)
		wave_spawning_finished.emit(GameManager.current_wave)


func _spawn_one_enemy() -> void:
	if enemy_scenes.is_empty() or enemies_container == null:
		push_warning("WaveSpawner: enemy_scenes ou enemies_container non configuré.")
		return

	var points := _spawn_points.get_children()
	if points.is_empty():
		push_warning("WaveSpawner: aucun point de spawn (ajoute des Marker2D sous SpawnPoints).")
		return

	var scene: PackedScene = enemy_scenes[randi() % enemy_scenes.size()]
	var enemy: Node2D = scene.instantiate()
	var spawn_point: Node2D = points[randi() % points.size()]
	enemy.global_position = spawn_point.global_position
	enemies_container.add_child(enemy)
