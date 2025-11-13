extends Node2D

## --- CONFIG ---
# You can assign multiple enemy scenes in the Inspector.
@export var enemy_scenes: Array[PackedScene] = []

# Base spawn rate (seconds between spawns)
@export var base_spawn_time: float = 2.0

# ----Spawn Variables---- Random variation to make spawns feel more organic
@export var min_spawn_time: float = 0.8   # fastest spawn interval
@export var max_spawn_time: float = 2.0   # starting spawn interval
@export var spawn_scale_distance: float = 1000.0  # distance at which spawn is fastest


# PowerBar
@onready var bar: TextureProgressBar = $UI/PowerMeter
@onready var wave_scene = $wave
@onready var wave_animation: AnimatedSprite2D = wave_scene.get_node("AnimatedSprite2D")
@export var power_max: float = 100.0
@export var passive_power_rate: float = -1.0 # power per second
@export var destruction_power_gain: float = 10 # power per kill
@export var rocks_power_loss: float = 20
@export var wave_small_threshold:float =  0.33   # 0 - 33% power
@export var wave_medium_threshold:float = 0.66  # 34% - 66%


#  Distance
var distance_travelled: float = 0.0

# PowerBar
var power: float = 10.0

## --- READY ---
func _ready() -> void:
	randomize()
	new_game()

	if bar:
		bar.max_value = power_max
		bar.value = power
		

## --- GAME FLOW ---
func new_game():
	distance_travelled = 0
	$Spawn/StartTimer.start()

func game_over():
	
	$Spawn/EnemyTimer.stop()

## --- POWER BAR ---
func _process(delta: float) -> void:
	# Passive increase
	power += passive_power_rate * delta
	power = clamp(power, 0.0, power_max)
	_update_power_meter()
	
	# --- Distance / Score ---
	var max_wave_speed: float = 200
	var new_power = power / power_max
	var current_speed = pow(new_power, 1.5) * max_wave_speed
	distance_travelled += current_speed * delta
	if $UI/Score:
		$UI/Score.text = str(int(distance_travelled)) + " m"
	
	# Spawn
	# Calculate scaled spawn time based on distance
	var t = clamp(distance_travelled / spawn_scale_distance, 0, 1)  # 0..1
	var new_spawn_time = lerp(max_spawn_time, min_spawn_time, t)

	# Update EnemyTimer wait_time
	$Spawn/EnemyTimer.wait_time = new_spawn_time
	
	
func add_power_from_enemy():
	power += destruction_power_gain
	power = clamp(power, 0.0, power_max)
	_update_power_meter()

func remove_power_from_rocks():
	power -= rocks_power_loss
	power = clamp(power, 0.0, 0)
	
func _update_power_meter():
	if not bar:
		return

	# Set value directly (max_value = power_max)
	bar.value = power
	# Get the progress bar texture
	var animated_texture := bar.texture_progress
	# Play wave animation based on power level
	var normalized_power = power / power_max
	if normalized_power <= wave_small_threshold:
		animated_texture.speed_scale = 1 # animation plays faster
		_play_wave_animation("low")
	elif normalized_power <= wave_medium_threshold:
		animated_texture.speed_scale = 3
		_play_wave_animation("medium")
	elif normalized_power <= 0:
		_play_wave_animation("dead")
	else:
		animated_texture.speed_scale = 5
		_play_wave_animation("big")
	
	
	
func _play_wave_animation(anim_name: String) -> void:
	if not wave_animation.is_playing() or wave_animation.animation != anim_name:
		wave_animation.play(anim_name)

## --- ENEMY SPAWN ---
func _on_start_timer_timeout() -> void:
	$Spawn/EnemyTimer.start()
 	

func _on_enemy_timer_timeout() -> void:
	var enemies_to_spawn = 1 + int(distance_travelled / 50)
	enemies_to_spawn = min(enemies_to_spawn, 5)

	# store previous spawn positions for spacing check
	var spawn_positions: Array[Vector2] = []
	var min_distance_x: float = 100.0  # minimum horizontal spacing
	var min_distance_y: float = 100.0  # minimum vertical spacing

	for i in range(enemies_to_spawn):
		if enemy_scenes.is_empty():
			push_warning("No enemy scenes assigned!")
			return

		var enemy_scene: PackedScene = enemy_scenes.pick_random()
		var enemy = enemy_scene.instantiate()

		# --- SCALE MOB SPEED ---
		var global_speed_scale = 1.0 + distance_travelled / 1000.0  # e.g., +100% after 1000m
		var random_variance = randf_range(0.85, 1.15)
		var total_speed_scale = global_speed_scale * random_variance
		if "mob_speed" in enemy:
			enemy.mob_speed = min((total_speed_scale * enemy.mob_speed), (400 * random_variance))

		# --- DETERMINE UNIQUE SPAWN POSITION ---
		var spawn_path = $Spawn/EnemyPath/SpawnLocation
		var new_pos: Vector2
		var max_attempts := 10
		var attempts := 0
		var valid_position := false

		while not valid_position and attempts < max_attempts:
			spawn_path.progress_ratio = randf()
			new_pos = spawn_path.position
			valid_position = true

			for prev_pos in spawn_positions:
				if abs(new_pos.x - prev_pos.x) < min_distance_x and abs(new_pos.y - prev_pos.y) < min_distance_y:
					valid_position = false
					break
			attempts += 1

		spawn_positions.append(new_pos)
		enemy.position = new_pos

		add_child(enemy)
