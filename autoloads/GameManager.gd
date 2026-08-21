extends Node
## Autoload (Singleton) — à enregistrer dans Project > Project Settings > Autoload
## sous le nom "GameManager".
##
## Centralise l'état global de la partie : argent, vague en cours, état
## (préparation / vague en cours / game over / victoire). Toute la UI et
## toute la logique de gameplay communiquent via ses signaux plutôt que
## de se référencer directement les unes les autres.

signal money_changed(new_amount: int)
signal game_state_changed(new_state: GameState)
signal wave_changed(new_wave: int)
## Émis uniquement quand une vague vient d'être nettoyée (tous les ennemis
## morts) ET qu'il en reste d'autres à venir. C'est ce signal que le Shop
## écoute pour s'ouvrir automatiquement.
signal wave_cleared(wave_number: int)
signal game_over
signal victory

enum GameState { PREPARATION, WAVE_IN_PROGRESS, GAME_OVER, VICTORY }

@export var starting_money: int = 150
@export var total_waves: int = 10

var money: int = 0
var current_wave: int = 0
var state: GameState = GameState.PREPARATION
var enemies_alive: int = 0
## True tant que le WaveSpawner est en train d'instancier des ennemis pour
## la vague en cours. Évite de considérer la vague "terminée" juste parce
## que le premier zombie spawné est mort avant que le second ne soit créé.
var is_spawning: bool = false


func _ready() -> void:
	reset_game()


func reset_game() -> void:
	money = starting_money
	current_wave = 0
	state = GameState.PREPARATION
	enemies_alive = 0
	money_changed.emit(money)
	wave_changed.emit(current_wave)
	game_state_changed.emit(state)


## --- Économie ---

func can_afford(cost: int) -> bool:
	return money >= cost


func spend_money(amount: int) -> bool:
	if not can_afford(amount):
		return false
	money -= amount
	money_changed.emit(money)
	return true


func add_money(amount: int) -> void:
	money += amount
	money_changed.emit(money)


## --- Vagues ---

func start_next_wave() -> void:
	if state == GameState.GAME_OVER or state == GameState.VICTORY:
		return
	current_wave += 1
	state = GameState.WAVE_IN_PROGRESS
	wave_changed.emit(current_wave)
	game_state_changed.emit(state)


## À appeler par le futur spawner à chaque ennemi instancié.
func register_enemy_spawned() -> void:
	enemies_alive += 1


## À appeler par un ennemi quand il meurt OU quand il atteint la base
## (dans les deux cas il quitte la vague ; register_enemy_defeated ne
## donne pas d'argent, c'est Enemy.die() qui s'en charge séparément).
func register_enemy_defeated() -> void:
	enemies_alive = max(0, enemies_alive - 1)
	if enemies_alive == 0 and not is_spawning and state == GameState.WAVE_IN_PROGRESS:
		_on_wave_cleared()


## À appeler par le WaveSpawner : true dès qu'il commence à instancier la
## vague, false dès qu'il a posé le dernier ennemi.
func set_spawning(active: bool) -> void:
	is_spawning = active
	if not is_spawning and enemies_alive <= 0 and state == GameState.WAVE_IN_PROGRESS:
		_on_wave_cleared()


func _on_wave_cleared() -> void:
	if current_wave >= total_waves:
		state = GameState.VICTORY
		game_state_changed.emit(state)
		victory.emit()
	else:
		state = GameState.PREPARATION
		game_state_changed.emit(state)
		wave_cleared.emit(current_wave)


## --- Fin de partie ---

func trigger_game_over() -> void:
	if state == GameState.GAME_OVER:
		return
	state = GameState.GAME_OVER
	game_state_changed.emit(state)
	game_over.emit()
