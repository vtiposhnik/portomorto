class_name FollowCamera
extends Camera2D

@export var follow_rate: float = 12.0
@export var view_zoom: float = 0.8
var target: Node2D

func _ready() -> void:
	zoom = Vector2.ONE * view_zoom
	global_position = target.global_position

func _process(delta: float) -> void:
	zoom = Vector2.ONE * view_zoom
	global_position = global_position.lerp(target.global_position, 1.0 - exp(-follow_rate * TimeControl.real_delta(delta)))
