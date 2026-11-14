extends CanvasLayer
## Interface: barras de vida (RF05) e painel de fim de partida (RF08, RF09, RF10).

@onready var player_bar: ProgressBar = $PlayerBar
@onready var enemy_bar: ProgressBar = $EnemyBar
@onready var result_panel: Control = $ResultPanel
@onready var result_label: Label = $ResultPanel/Box/ResultLabel
@onready var restart_button: Button = $ResultPanel/Box/RestartButton
@onready var menu_button: Button = $ResultPanel/Box/MenuButton


func _ready() -> void:
	result_panel.hide()
	restart_button.pressed.connect(func(): get_tree().reload_current_scene())
	menu_button.pressed.connect(func(): get_tree().change_scene_to_file("res://ui/menu.tscn"))


func set_player_health(current: int, max_value: int) -> void:
	player_bar.max_value = max_value
	player_bar.value = current


func set_enemy_health(current: int, max_value: int) -> void:
	enemy_bar.max_value = max_value
	enemy_bar.value = current


func show_result(text: String) -> void:
	result_label.text = text
	result_panel.show()
	restart_button.grab_focus()
