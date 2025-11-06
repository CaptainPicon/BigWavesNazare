extends Node2D

## --- CONFIG ---
# You can assign multiple enemy scenes in the Inspector.
@export var enemy_scenes: Array[PackedScene] = []

# Base spawn rate (seconds between spawns)
@export var base_spawn_time: float = 2.0

# Random variation to make spawns feel more organic
@export var spawn_variation: float = 0.8

# Score
var score: int = 0


## --- READY ---
func _ready() -> void:
	randomize()
	new_game()


## --- GAME FLOW ---
func new_game():
	score = 0
	$Spawn/StartTimer.start()

func game_over():
	$Spawn/ScoreTimer.stop()
	$Spawn/EnemyTimer.stop()


## --- TIMER CALLBACKS ---
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


	

	# assign random velocity or call a setup method if the enemy has one
	var direction_degrees: float = 180.0
	var direction_radians = deg_to_rad(direction_degrees)
	var velocity = Vector2(randf_range(150.0, 250.0), 0.0).rotated(direction_radians)
	enemy.linear_velocity = velocity

	add_child(enemy)

	# set new randomized wait time for next spawn
	var new_wait_time = base_spawn_time + randf_range(-spawn_variation, spawn_variation)
	$Spawn/EnemyTimer.wait_time = clamp(new_wait_time, 0.3, 5.0)
