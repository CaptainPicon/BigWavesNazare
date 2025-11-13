extends CharacterBody2D


# --- CONFIGURATION ---
const RISE_FORCE_INCREMENT_STEP: float = 3000.0
const RISE_FORCE_MAX: float = 4000.0
const MAX_FALL_SPEED: float = 500.0
const GRAVITY: float = 3000.0

# --- WAVE MOTION CONFIG ---
@export var forward_offset_max: float = 50.0  # How far forward the wave surges
@export var forward_return_speed: float = 2.0  # How fast it returns when falling

# --- STATE VARIABLES ---
var rise_force: float = 0.0
var rise_activated: bool = false
var base_x_position: float
var surge_progress: float = 0.0  # Keeps track of current forward offset

@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var shapes := {
	"low": $CollisionShape2D_low,
	"medium": $CollisionShape2D_medium,
	"big": $CollisionShape2D_big,
	#"tsunami": $CollisionShape2D_Tsunami
}

func _ready() -> void:
	base_x_position = global_position.x
	_update_collision_shape(anim_sprite.animation)
	anim_sprite.connect("animation_changed", Callable(self, "_on_animation_changed"))

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action("move"):
		rise_activated = Input.is_action_pressed("move")
		


func _process(delta: float) -> void:
	# --- Rise force build-up ---
	if rise_activated:
		rise_force = min(rise_force + RISE_FORCE_INCREMENT_STEP * delta, RISE_FORCE_MAX)
	else:
		rise_force = 0.0

	# --- Horizontal surge control ---
	if rise_activated and not is_on_ceiling():
		# Ease forward while rising
		surge_progress = lerp(surge_progress, 1.0, 3.0 * delta)
	elif velocity.y > 0 or is_on_ceiling():
		# Only return once the wave is falling
		surge_progress = lerp(surge_progress, 0.0, forward_return_speed * delta)

	# Apply horizontal offset based on surge progress
	global_position.x = base_x_position + (forward_offset_max * surge_progress)

func _physics_process(delta: float) -> void:
	if rise_activated and not is_on_ceiling():
		velocity.y = -rise_force
	else:
		velocity.y += GRAVITY * delta

	velocity.y = clamp(velocity.y, -RISE_FORCE_MAX, MAX_FALL_SPEED)
	move_and_slide()


func _on_animation_changed():
	_update_collision_shape(anim_sprite.animation)

func _update_collision_shape(anim_name: String):
	# Disable all first
	for shape in shapes.values():
		shape.call_deferred("set_disabled", true)

	# Enable the one matching the current animation
	if anim_name in shapes:
		shapes[anim_name].call_deferred("set_disabled", false)
	
