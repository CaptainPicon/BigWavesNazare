extends Control

@export var game_scene: PackedScene

func _ready():
	$VBoxContainer/Start.pressed.connect(_on_start_pressed)
	$VBoxContainer/Exit.pressed.connect(_on_exit_pressed)

func _on_start_pressed():
	get_tree().change_scene_to_packed(game_scene)

func _on_exit_pressed():
	get_tree().quit()
