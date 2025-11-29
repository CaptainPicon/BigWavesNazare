extends Node2D

## --- CONFIG ---
# You can assign multiple enemy scenes in the Inspector.
@export var enemy_scenes: Array[PackedScene] = []

# Game Menu
var gameover_path = "res://scenes/gameover.tscn"

# Base spawn rate (seconds between spawns)
@export var base_spawn_time: float = 4.0

# ----Spawn Variables---- Random variation to make spawns feel more organic
@export var min_spawn_time: float = 0.6   # fastest spawn interval
@export var max_spawn_time: float = 1.5   # starting spawn interval
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
@export var level_up_wave_one: AudioStream
@export var level_up_wave_two: AudioStream
@export var tsunami_sound: AudioStream

var power: float = 15.0
enum WaveLevel {
	LOW,
	MEDIUM,
	HIGH
}
var current_wave_level: int = WaveLevel.LOW

# Rocks Collision
var slowdown_timer:= 0.0
var slowdown_strength:= 0.5

# Tsunami Mode
@export var tsunami_duration: float = 5.0  
var tsunami_active := false
var tsunami_timer := 0.0
#  Distance
var distance_travelled: float = 0.0

# Shader
@onready var water_shader: Sprite2D = $World/Water
@onready var wind_particles: GPUParticles2D = $World/WindParticles


# Parallax
@onready var clouds: Parallax2D = $"World/Sky/Low Clouds"


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

## --- GAME OVER ---
func game_over():
	$Spawn/EnemyTimer.stop()
	# Store distance information in temp data
	get_tree().set_meta("distance_travelled", distance_travelled)
	call_deferred("change_to_menu")

func change_to_menu():
	get_tree().change_scene_to_file(gameover_path)	
	
	

## --- POWER BAR ---
func _process(delta: float) -> void:
	# Passive increase
	if not tsunami_active:
		power += passive_power_rate * delta
		power = clamp(power, 0.0, power_max)
		_update_power_meter()
	
	# --- TSUNAMI MODE TIMER ---
	if tsunami_active:
		tsunami_timer -= delta
		if tsunami_timer <= 0:
			_end_tsunami_mode()

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
	
	# Apply slowdown (decays over time)
	if slowdown_timer > 0.0:
		slowdown_timer -= delta
		var slow_multiplier = 1.0 - slowdown_strength
		current_speed *= slow_multiplier
		

func add_power_from_enemy():
	power += destruction_power_gain
	power = clamp(power, 0.0, power_max)
	_update_power_meter()

func remove_power_from_rocks():
	if tsunami_active:
		return
	power -= rocks_power_loss
	power = clamp(power, 0.0, power_max)
	_update_power_meter()
	
func _update_power_meter():
	if not bar:
		return
		
	# Tsunami lock: while tsunami is active we simply show tsunami and skip state changes
	if tsunami_active:
		bar.value = power_max
		return

	# Set value directly (max_value = power_max)
	bar.value = power
	# Get the progress bar texture
	var animated_texture := bar.texture_progress
	# Play wave animation based on power level
	var normalized_power = power / power_max
	if normalized_power <= 0 and not tsunami_active  :
		game_over()
	
	# Tsunami overrides all other wave states
	# Trigger tsunami when power hits max
	if power >= power_max and not tsunami_active:
		_start_tsunami_mode()
		return   # <--- IMPORTANT: prevent the rest of the function from running this frame


	# LOW	
	if normalized_power <= wave_small_threshold:
		if current_wave_level != WaveLevel.LOW:
			current_wave_level = WaveLevel.LOW
			
		animated_texture.speed_scale = 1 # animation plays faster
		water_shader.material.set_shader_parameter("wave_frequency", 15)
		water_shader.material.set_shader_parameter("wave_speed", 3)
		water_shader.material.set_shader_parameter("wave_amplitude", 0.035)
		clouds.autoscroll.x = -10 #change parallax speed for the clouds
		wind_particles.speed_scale = 1 # set wind speed	
		_play_wave_animation("low")
		
	# MEDIUM
	elif normalized_power <= wave_medium_threshold:
		if current_wave_level != WaveLevel.MEDIUM:
			current_wave_level = WaveLevel.MEDIUM
			SoundManager.play_sfx(level_up_wave_one)
			
		water_shader.material.set_shader_parameter("wave_frequency", 30)
		water_shader.material.set_shader_parameter("wave_speed", 10)
		water_shader.material.set_shader_parameter("wave_amplitude", 0.038)
		animated_texture.speed_scale = 3
		clouds.autoscroll.x = -20
		wind_particles.speed_scale = 2
		_play_wave_animation("medium")
	
	# HIGH
	else:
		if current_wave_level != WaveLevel.HIGH:
			current_wave_level = WaveLevel.HIGH
			SoundManager.play_sfx(level_up_wave_two)
		animated_texture.speed_scale = 5
		water_shader.material.set_shader_parameter("wave_frequency", 40)
		water_shader.material.set_shader_parameter("wave_speed", 15)
		water_shader.material.set_shader_parameter("wave_amplitude", 0.045)
		clouds.autoscroll.x = -30
		wind_particles.speed_scale = 3
		_play_wave_animation("big")
	
	
	
func _play_wave_animation(anim_name: String) -> void:
	if not wave_animation.is_playing() or wave_animation.animation != anim_name:
		wave_animation.play(anim_name)

## --- ENEMY SPAWN ---
func _on_start_timer_timeout() -> void:
	$Spawn/EnemyTimer.start()
 	
func _on_enemy_timer_timeout() -> void:
	var enemies_to_spawn = 1 + int(distance_travelled / 50)
	enemies_to_spawn = min(enemies_to_spawn, 2)

	var spawn_path = $Spawn/EnemyPath/SpawnLocation

	for i in range(enemies_to_spawn):

		if enemy_scenes.is_empty():
			push_warning("No enemy scenes assigned!")
			return

		var enemy_scene: PackedScene = enemy_scenes.pick_random()
		var enemy = enemy_scene.instantiate()

		# --- SCALE MOB SPEED ---
		var global_speed_scale = 1.0 + distance_travelled / 1000.0
		var random_variance = randf_range(0.85, 1.15)
		var total_speed_scale = global_speed_scale * random_variance

		if "mob_speed" in enemy:
			enemy.mob_speed = min(
				total_speed_scale * enemy.mob_speed,
				200 * random_variance
			)

		# --- SIMPLE RANDOM SPAWN ---
		spawn_path.progress_ratio = randf()
		enemy.global_position = spawn_path.global_position

		add_child(enemy)

# Tsunami Mode
func _start_tsunami_mode() -> void:
	tsunami_active = true

	tsunami_timer = tsunami_duration
	power = power_max   # lock power
	print("Current Wave Animation: ", wave_animation.animation)
	print("available animations:", wave_animation.sprite_frames.get_animation_names())
	wave_animation.stop()
	SoundManager.play_sfx(tsunami_sound)
	_play_wave_animation("tsunami")

	# Optional effects
	water_shader.material.set_shader_parameter("wave_amplitude", 0.07)
	water_shader.material.set_shader_parameter("wave_speed", 25)
	clouds.autoscroll.x = -50


func _end_tsunami_mode() -> void:
	tsunami_active = false
	power = power_max * 0.4   # exit with partial power
	_update_power_meter()
