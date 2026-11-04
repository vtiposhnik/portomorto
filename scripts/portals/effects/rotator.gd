class_name RotatorEffect
extends PortalEffect

@export_range(-180.0, 180.0, 15.0) var angle_degrees: float = 0.0

func modify(result: Dictionary) -> Dictionary:
	var angle: float = deg_to_rad(angle_degrees)
	result.velocity = result.velocity.rotated(angle)
	result.motion = result.motion.rotated(angle)
	return result
