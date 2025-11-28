extends Camera2D

# --- Shake settings ---
var shake_strength: float = 0.0
var shake_decay: float = 5.0  # How quickly shake fades
var shake_frequency: float = 5.0 # Max shakes per second
var original_offset: Vector2 = Vector2.ZERO

# Internal
var _shake_timer: float = 0.0

func _ready() -> void:
	original_offset = offset

func _process(delta: float) -> void:
	if shake_strength > 0.0:
		# Update timer
		_shake_timer += delta
		
		# Only shake when enough time has passed
		var interval = 1.0 / shake_frequency
		if _shake_timer >= interval:
			_shake_timer = 0.0  # reset timer
			offset = original_offset + Vector2(
				randf_range(-1, 1),
				randf_range(-1, 1)
			) * shake_strength
		
		# Decay shake strength over time
		shake_strength = max(shake_strength - shake_decay * delta, 0)
	else:
		offset = original_offset

# Call this to start shake
func start_shake(intensity: float = 2.0, decay: float = 5.0):
	shake_strength = intensity
	shake_decay = decay
