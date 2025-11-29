extends Area2D

@export var impact_sounds: Array[AudioStream] = []

@export var mob_speed:float = 100
var wave: Node = null  # reference to the wave instance
var removed_power: bool = false # track if the rock has already collided with the wave

# Called when the node enters the scene tree for the first time.
func _ready():
	var mob_types = Array($AnimatedSprite2D.sprite_frames.get_animation_names())
	$AnimatedSprite2D.animation = mob_types.pick_random()
	$AnimatedSprite2D.play()
	
	# Get wave instance safely
	var main_scene = get_tree().current_scene
	if main_scene.has_node("wave"):
		wave = main_scene.get_node("wave")
		
	else:
		push_warning("Wave node not found in current scene!")
	

func _physics_process(delta) -> void:
	position.x +=  -mob_speed * delta  # move left
	


func _on_body_entered(_body):
	if _body.name == "wave" and wave and not removed_power:
		removed_power = true
		
		var main = get_tree().current_scene
		if main.tsunami_active:
			# During Tsunami: rocks disappear without affecting wave/power
			queue_free()
			return
		
		# Normal behavior outside Tsunami:
		# remove the player power
		main.remove_power_from_rocks()
		
		# Drag the wave to the left after collision	
		wave.apply_rock_drag(mob_speed)
		
		# Get power level
		var current_power = main.power
		var max_power = main.power_max
		var power_ratio = current_power / max_power

		# Scale the shake intensity
		var camera = main.get_node("Camera2D")
		if camera:
			# Example formula: base shake + scaled intensity
			var intensity = 2.0 + (power_ratio * 3.0) # between 2 and 8
			var decay = 5 + (power_ratio * 2.0)    # longer shake for big waves
			camera.start_shake(intensity, decay)
		
		# Sound
		SoundManager.play_sfx(impact_sounds.pick_random())
		
		# Remove rock after collision
		queue_free()


func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()
