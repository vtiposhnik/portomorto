class_name PortalEffectControls
extends Node

var system: PortalSystem
var selected: int = 0
@export var angle_step: float = 15.0

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("configure_a"):
		selected = 0
	elif event.is_action_pressed("configure_b"):
		selected = 1
	elif event.is_action_pressed("effect_standard"):
		system.endpoints[selected].effect = null
	elif event.is_action_pressed("effect_accelerator"):
		var effect := AcceleratorEffect.new()
		effect.maximum_speed *= float(system.get_meta("world_scale",1.0))
		system.endpoints[selected].effect = effect
	elif event.is_action_pressed("effect_rotator"):
		system.endpoints[selected].effect = RotatorEffect.new()
	elif system.endpoints[selected].effect is RotatorEffect:
		var direction: float = 0.0
		if event.is_action_pressed("rotate_clockwise"):
			direction = 1.0
		elif event.is_action_pressed("rotate_counterclockwise"):
			direction = -1.0
		var rotator: RotatorEffect = system.endpoints[selected].effect
		rotator.angle_degrees = wrapf(rotator.angle_degrees + direction * angle_step, -180.0, 180.0)

func description() -> String:
	var effect: PortalEffect = system.endpoints[selected].effect
	var label: String = "Standard"
	if effect is AcceleratorEffect:
		label = "Accelerator %.1fx (cap %.0f)" % [effect.multiplier,effect.maximum_speed]
	elif effect is RotatorEffect:
		label = "Rotator %+.0f°" % effect.angle_degrees
	return "Configure %s exit: %s   |   Q/T select   1/2/3 effect   Wheel rotate" % ["A" if selected == 0 else "B",label]
