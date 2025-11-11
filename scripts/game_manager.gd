extends Node2D

## --- CONFIG ---
# You can assign multiple enemy scenes in the Inspector.
@export var enemy_scenes: Array[PackedScene] = []

# Base spawn rate (seconds between spawns)
@export var base_spawn_time: float = 2.0

# Random variation to make spawns feel more organic
@export var spawn_variation: float = 0.8

# PowerBar
@onready var bar: TextureProgressBar = $PowerMeter
@export var power_max: float = 100.0
@export var passive_power_rate: float = 1.0 # power per second
@export var destruction_power_gain: float = 10 # power per kill

# Score
var score: int = 0

# PowerBar
var power: float = 0.0

## --- READY ---
func _ready() -> void:
	randomize()
	new_game()

	if bar:
		bar.max_value = power_max
		bar.value = power
		bar.tint_progress = Color(0.2, 0.6, 1.0)  # start color

## --- GAME FLOW ---
func new_game():
	score = 0
	$Spawn/StartTimer.start()

func game_over():
	$Spawn/ScoreTimer.stop()
	$Spawn/EnemyTimer.stop()

## --- POWER BAR ---
func _process(delta: float) -> void:
	# Passive increase
	power += passive_power_rate * delta
	power = clamp(power, 0.0, power_max)
	_update_power_meter()
	
func add_power_from_enemy():
	power += destruction_power_gain
	power = clamp(power, 0.0, power_max)
	_update_power_meter()

func _update_power_meter():
	if not bar:
		return

	# Set value directly (max_value = power_max)
	bar.value = power

	# Dynamic color feedback
	if power > power_max * 0.8:
		bar.tint_progress = Color(1, 0.2, 0.2)  # red = almost full
	elif power > power_max * 0.5:
		bar.tint_progress = Color(1, 0.8, 0.2)  # yellow = mid
	else:
		bar.tint_progress = Color(0.2, 0.6, 1.0) # blue = low

## --- ENEMY SPAWN ---
func _on_start_timer_timeout() -> void:
	$Spawn/EnemyTimer.start()
	$Spawn/ScoreTimer.start()

func _on_score_timer_timeout() -> void:
	score += 1

func _on_enemy_timer_timeout() -> void:
	if enemy_scenes.is_empty():
		push_warning("No enemy scenes assigned to the spawner!")
		return

	# pick a random enemy type
	var enemy_scene: PackedScene = enemy_scenes.pick_random()
	var enemy = enemy_scene.instantiate()

	# spawn position
	var spawn_path = $Spawn/EnemyPath/SpawnLocation
	spawn_path.progress_ratio = randf()
	enemy.position = spawn_path.position

	add_child(enemy)
	print("Spawning Mob")

	# set new randomized wait time for next spawn
	var new_wait_time = base_spawn_time + randf_range(-spawn_variation, spawn_variation)
	$Spawn/EnemyTimer.wait_time = clamp(new_wait_time, 0.3, 5.0)
