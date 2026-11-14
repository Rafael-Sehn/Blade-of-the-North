extends Node2D
## Controlador da partida: liga jogador, inimigo e interface e decide vitória/derrota.

var _finished := false

@onready var player = $Player
@onready var enemy = $Enemy
@onready var hud = $HUD


func _ready() -> void:
	player.health_changed.connect(hud.set_player_health)
	player.died.connect(func(): _finish("DERROTA"))
	enemy.health_changed.connect(hud.set_enemy_health)
	enemy.died.connect(func(): _finish("VITÓRIA"))
	hud.set_player_health(player.health, player.max_health)
	hud.set_enemy_health(enemy.health, enemy.max_health)


func _finish(text: String) -> void:
	if _finished:
		return
	_finished = true
	hud.show_result(text)


func _unhandled_input(event: InputEvent) -> void:
	if _finished and event.is_action_pressed("restart"):
		get_tree().reload_current_scene()
