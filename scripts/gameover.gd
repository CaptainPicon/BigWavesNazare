extends Control

@export var game_scene: PackedScene
@onready var distance_label = $Distance

func _ready():
	# Check if distance info exists
	if get_tree().has_meta("distance_travelled"):
		var distance = get_tree().get_meta("distance_travelled")
		distance_label.text = "Distance Travelled: " + str(int(distance)) + " m"
		get_tree().remove_meta("distance_travelled") # clean up
		
	$VBoxContainer/Start.pressed.connect(_on_start_pressed)
	$VBoxContainer/Exit.pressed.connect(_on_exit_pressed)

func _on_start_pressed():
	get_tree().change_scene_to_packed(game_scene)

func _on_exit_pressed():
	get_tree().quit()
