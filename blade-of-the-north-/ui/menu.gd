extends Control
## Tela inicial (RF01).

@onready var start_button: Button = $Box/StartButton
@onready var quit_button: Button = $Box/QuitButton


func _ready() -> void:
	start_button.pressed.connect(func(): get_tree().change_scene_to_file("res://game.tscn"))
	quit_button.pressed.connect(func(): get_tree().quit())
	start_button.grab_focus()
