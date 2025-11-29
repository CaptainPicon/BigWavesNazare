extends CharacterBody2D

# --- CONFIGURATION ---
const RISE_FORCE_INCREMENT_STEP: float = 1000.0
const RISE_FORCE_MAX: float = 2000.0
const MAX_FALL_SPEED: float = 500.0
const GRAVITY: float = 2000.0

# --- WAVE MOTION CONFIG ---
@export var forward_offset_max: float = 50.0      # How far forward the wave surges
@export var forward_return_speed: float = 2.0     # How fast it returns when falling
@export var drag_recovery_speed: float = 2.0      # How fast the wave recovers from rock drag

# --- Sound ---
@export var rise_sound: AudioStream
@export var fall_sound: AudioStream
@onready var wave_audio: AudioStreamPlayer2D = $AudioStreamPlayer2D
var was_rising := false


# --- STATE VARIABLES ---
var rise_force: float = 0.0
var rise_activated: bool = false
var base_x_position: float
var surge_progress: float = 0.0   # Current forward offset (0-1)
var drag_offset: float = 0.0      # Tracks backward drag caused by rocks

@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var shapes := {
	"low": $CollisionShape2D_low,
	"medium": $CollisionShape2D_medium,
	"big": $CollisionShape2D_big,
	"tsunami": $CollisionShape2D_tsunami
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
	
		# --- SOUND LOGIC ---
	if rise_activated and not was_rising:
		play_wave_sound(rise_sound)
	elif not rise_activated and was_rising:
		play_wave_sound((fall_sound))

	was_rising = rise_activated


	# --- Horizontal surge control ---
	if rise_activated and not is_on_ceiling():
		# Ease forward while rising
		surge_progress = lerp(surge_progress, 1.0, 3.0 * delta)
	elif velocity.y > 0 or is_on_ceiling():
		# Return surge when falling
		surge_progress = lerp(surge_progress, 0.0, forward_return_speed * delta)

	# --- Drag recovery ---
	drag_offset = lerp(drag_offset, 0.0, drag_recovery_speed * delta)

	# Apply combined offset (surge - drag)
	global_position.x = base_x_position + (forward_offset_max * surge_progress) - drag_offset
	
	# Pitch reacts to force
	if wave_audio.playing:
		var force_ratio := rise_force / RISE_FORCE_MAX
		wave_audio.pitch_scale = lerp(0.9, 1.2, force_ratio)


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
	# Disable all shapes first
	for shape in shapes.values():
		shape.call_deferred("set_disabled", true)

	# Enable shape matching current animation
	if anim_name in shapes:
		shapes[anim_name].call_deferred("set_disabled", false)

# --- NEW: Called when a rock hits the wave ---
func apply_rock_drag(rock_speed: float) -> void:
	# rock_speed should be positive; scale how much the wave is dragged back
	drag_offset += rock_speed * 0.2  # tweak factor as needed
	# apply blink effect when hit
	var tween = get_tree().create_tween( )
	tween.tween_method(setshader_blinkintensity, 1.0, 0.0, 0.5)
	
	
# Bink shader
func setshader_blinkintensity(newValue: float):
	anim_sprite.material.set_shader_parameter("blink_intensity", newValue)

func play_wave_sound(stream: AudioStream) -> void:
	if not stream:
		return

	wave_audio.stop() 
	wave_audio.stream = stream
	wave_audio.bus = "SFX"
	wave_audio.pitch_scale = randf_range(0.95, 1.05)
	wave_audio.play(2)
