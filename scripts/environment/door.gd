class_name MechanismDoor
extends AnimatableBody2D

@export var open_offset: Vector2 = Vector2(0,-150)
@export var opening_speed: float = 180.0
@export var closing_speed: float = 120.0
@export var require_all: bool = false
@export var obstruction_mask: int = 38
var inputs: Dictionary = {}
var closed_position: Vector2
var requested_open: bool = false
var blocked: bool = false

func _ready() -> void:
	sync_to_physics = false
	closed_position = position

func receive_activation(source: Node, active: bool) -> void:
	inputs[source.get_instance_id()] = {"source":weakref(source),"active":active}
	_recompute()

func _recompute() -> void:
	requested_open = require_all and not inputs.is_empty()
	for key in inputs.keys():
		if inputs[key].source.get_ref() == null:
			inputs.erase(key)
			continue
		if require_all:
			requested_open = requested_open and inputs[key].active
		else:
			requested_open = requested_open or inputs[key].active
	if inputs.is_empty():
		requested_open = false

func _physics_process(delta: float) -> void:
	_recompute()
	var target: Vector2 = closed_position + (open_offset if requested_open else Vector2.ZERO)
	var next: Vector2 = position.move_toward(target,(opening_speed if requested_open else closing_speed)*delta)
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = $CollisionShape2D.shape
	query.transform = $CollisionShape2D.global_transform
	query.collision_mask = obstruction_mask
	query.exclude = [get_rid()]
	query.motion = next-position
	query.margin = 0.5
	var space: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	blocked = not space.intersect_shape(query,1).is_empty() or space.cast_motion(query)[0] < 1.0
	query.transform.origin += query.motion
	blocked = blocked or not space.intersect_shape(query,1).is_empty()
	if not blocked:
		position = next
