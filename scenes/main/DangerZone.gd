extends Area2D
class_name DangerZone
## Bande fine placée tout en bas de l'écran, sous la grille. Si un ennemi
## la touche, c'est qu'il a traversé toute la défense : game over immédiat.
## Compte aussi comme "l'ennemi a quitté la vague" pour que le décompte
## de GameManager (enemies_alive) ne reste jamais bloqué.

func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body is Enemy:
		body.reached_goal.emit(body)
		GameManager.register_enemy_defeated()
		GameManager.trigger_game_over()
		body.queue_free()
