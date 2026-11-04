class_name MovingPlatform
extends AnimatableBody2D

@export var waypoints: PackedVector2Array = PackedVector2Array([Vector2.ZERO,Vector2(200,0)])
@export var speed: float = 90.0
@export var ping_pong: bool = true
var origin: Vector2
var destination: int = 1
var step: int = 1
var current_velocity: Vector2 = Vector2.ZERO

func _ready() -> void:
	sync_to_physics = false
	origin = position
	if not waypoints.is_empty():
		position = origin+waypoints[0]

func _physics_process(delta: float) -> void:
	if waypoints.size() < 2:
		return
	var target: Vector2 = origin+waypoints[destination]
	var before: Vector2 = position
	position = position.move_toward(target,speed*delta)
	current_velocity = (position-before)/delta
	if position.is_equal_approx(target):
		if ping_pong and (destination == waypoints.size()-1 or destination == 0):
			step *= -1
		destination = posmod(destination+step,waypoints.size())

func reverse_motion() -> void:
	if waypoints.size() < 2:
		return
	destination = posmod(destination-step,waypoints.size())
	step *= -1
	current_velocity = Vector2.ZERO
