class_name TimeControl
extends Node

@export_range(0.05, 1.0) var focus_scale: float = 0.2
var focused: bool = false

func _process(_delta: float) -> void:
	set_focus(Input.is_action_pressed("focus"))

func set_focus(active: bool) -> void:
	focused = active
	Engine.time_scale = focus_scale if active else 1.0

static func real_delta(scaled_delta: float) -> float:
	return scaled_delta / maxf(Engine.time_scale, 0.001)

func _exit_tree() -> void:
	Engine.time_scale = 1.0

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		Input.action_release("focus")
		set_focus(false)
