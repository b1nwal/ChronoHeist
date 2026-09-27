extends Camera2D

@onready var target = get_parent()
var lerp_speed := 5.0
var lead_distance := 100

func _process(delta: float) -> void:
	if not target:
		return

	var vel = target.velocity  # or whatever your player uses
	var forward = vel.normalized()
	var target_pos = target.global_position + forward * lead_distance

	global_position = global_position.lerp(target_pos, lerp_speed * delta)
