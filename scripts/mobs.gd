extends Area2D

@export var mob_speed:float = 140

# Called when the node enters the scene tree for the first time.
func _ready():
	var mob_types = Array($AnimatedSprite2D.sprite_frames.get_animation_names())
	$AnimatedSprite2D.animation = mob_types.pick_random()
	print("Hello World")
	$AnimatedSprite2D.play()


func _physics_process(delta) -> void:
	position.x +=  -mob_speed * delta  # move left
	


func _on_body_entered(_body):
	if _body.name == "wave":
	# 1️⃣ Give the player power
		get_tree().current_scene.add_power_from_enemy()
		print("add 10 points")
		
		# 2️⃣ (Optional) Spawn splash or particles before dying
		# _spawn_splash_effect()
		
		# 3️⃣ Destroy the enemy
		# Start a 1-second timer before removing the enemy
		var death_timer = Timer.new()
		death_timer.wait_time = 0.1
		death_timer.one_shot = true
		add_child(death_timer)
		death_timer.start()
		
		death_timer.timeout.connect(func():
			print("I Died, i am too old")
			queue_free())


func _on_visible_on_screen_notifier_2d_screen_exited():
	print("I Left")
	queue_free()
