class_name PortalTraveller
extends Node

signal teleported(entrance: int, exit: int)
@export var enabled: bool = true
@onready var body: PhysicsBody2D = get_parent() as PhysicsBody2D
@onready var shape: CollisionShape2D = body.get_node("CollisionShape2D")
var previous_position: Vector2
var initialized: bool = false
var exceptions: Array[PhysicsBody2D] = []
var teleport_count: int = 0
var pending_recovery: Dictionary = {}

func _ready() -> void:
	add_to_group("portal_travellers")

func get_velocity() -> Vector2:
	if body is CharacterBody2D:
		return body.velocity
	if body is RigidBody2D:
		return body.linear_velocity
	return Vector2.ZERO

# Extents come from physics shapes, never from the visual representation.
func support(direction: Vector2) -> float:
	if shape.shape is CircleShape2D:
		return shape.shape.radius
	var rectangle: RectangleShape2D = shape.shape as RectangleShape2D
	var local: Vector2 = direction.rotated(-body.global_rotation - shape.rotation)
	return absf(local.x) * rectangle.size.x * 0.5 + absf(local.y) * rectangle.size.y * 0.5

func clear_exceptions() -> void:
	for wall in exceptions:
		if is_instance_valid(wall):
			body.remove_collision_exception_with(wall)
	exceptions.clear()

func allow_surface(wall: PhysicsBody2D) -> void:
	if wall not in exceptions:
		body.add_collision_exception_with(wall)
		exceptions.append(wall)

func resolve_motion(before: Vector2, after: Vector2, velocity: Vector2) -> Dictionary:
	var manager: Node = get_tree().get_first_node_in_group("portal_system")
	if manager and enabled:
		return manager.resolve(self, before, after, velocity)
	return {}

# Called inside a rigid body's direct-state callback, never via deferred position writes.
func integrate(state: PhysicsDirectBodyState2D) -> void:
	if not pending_recovery.is_empty():
		var recovered: Transform2D = state.transform
		recovered.origin = pending_recovery.position
		state.transform = recovered
		state.linear_velocity = pending_recovery.velocity
		previous_position = recovered.origin
		pending_recovery.clear()
		initialized = true
		return
	var current: Vector2 = state.transform.origin
	if initialized:
		var result: Dictionary = resolve_motion(previous_position, current, state.linear_velocity)
		if not result.is_empty():
			var pose: Transform2D = state.transform
			pose.origin = result.position
			state.transform = pose
			state.linear_velocity = result.velocity
			state.sleeping = false
	previous_position = state.transform.origin
	initialized = true
