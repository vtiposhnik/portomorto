class_name AcceleratorEffect
extends PortalEffect

@export_range(1.0, 5.0) var multiplier: float = 1.5
@export_range(100.0, 10000.0) var maximum_speed: float = 2400.0

func modify(result: Dictionary) -> Dictionary:
	var speed: float = result.velocity.length()
	if speed > 0.0:
		var factor: float = minf(speed * maxf(1.0, multiplier), maxf(0.0, maximum_speed)) / speed
		result.velocity *= factor
		result.motion *= factor
	return result
