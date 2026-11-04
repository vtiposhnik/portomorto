class_name ObjectInteraction
extends Node

@export var reach: float = 115.0
@export var hold_distance: float = 85.0
@export var minimum_mass: float = 0.1
@export var maximum_mass: float = 8.0
@export var spring: float = 100.0
@export var damping: float = 20.0
@export var maximum_acceleration: float = 3500.0
@export var throw_speed: float = 1000.0
@onready var player: CharacterBody2D = get_parent()
var held: RigidBody2D
var released: Array[RigidBody2D] = []
var hold_query := PhysicsShapeQueryParameters2D.new()

func _ready() -> void:
	player.get_node("PortalTraveller").teleported.connect(_transit)
	player.get_node("Health").depleted.connect(release)

# Input-stage priority precedes portal placement's unhandled-input stage.
func _input(event: InputEvent) -> void:
	if player.get_node("Health").current <= 0:
		return
	if event.is_action_pressed("interact"):
		if is_instance_valid(held):
			release()
		else:
			interact_nearest()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("throw_object") and is_instance_valid(held):
		throw_toward(player.get_global_mouse_position())
		get_viewport().set_input_as_handled()

func interact_nearest() -> void:
	var nearest: Node2D
	var distance: float = reach
	for candidate: Node in get_tree().get_nodes_in_group("carryable") + get_tree().get_nodes_in_group("interactables"):
		if not candidate is PhysicsBody2D:
			continue
		var separation: float = player.global_position.distance_to(candidate.global_position)
		if separation < distance and visible_to(candidate):
			if candidate is RigidBody2D and (candidate.mass < minimum_mass or candidate.mass > maximum_mass):
				continue
			nearest = candidate
			distance = separation
	if nearest is RigidBody2D:
		grab(nearest)
	elif is_instance_valid(nearest) and nearest.has_method("interact"):
		nearest.interact()

func visible_to(body: PhysicsBody2D) -> bool:
	var ray := PhysicsRayQueryParameters2D.create(player.global_position,body.global_position,1|16)
	ray.exclude = [player.get_rid(),body.get_rid()]
	return player.get_world_2d().direct_space_state.intersect_ray(ray).is_empty()

func grab(body: RigidBody2D) -> bool:
	if is_instance_valid(held) or body.freeze or not body.is_in_group("carryable") or body.mass < minimum_mass or body.mass > maximum_mass:
		return false
	if body.global_position.distance_to(player.global_position) > reach or not visible_to(body):
		return false
	released.erase(body)
	held = body
	held.sleeping = false
	held.add_collision_exception_with(player)
	var traveller: PortalTraveller = held.get_node_or_null("PortalTraveller")
	if traveller:
		traveller.teleported.connect(_transit)
	return true

func _transit(_entrance: int, _exit: int) -> void:
	# Carrying never applies a spring force across disconnected portal positions.
	release()

func release() -> void:
	if is_instance_valid(held):
		var traveller: PortalTraveller = held.get_node_or_null("PortalTraveller")
		if traveller and traveller.teleported.is_connected(_transit):
			traveller.teleported.disconnect(_transit)
		if held not in released:
			released.append(held)
	held = null

func throw_toward(point: Vector2) -> void:
	if not is_instance_valid(held):
		return
	# Add a bounded impulse; retain existing velocity rather than overwriting it.
	var direction: Vector2 = (point-player.global_position).normalized()
	held.apply_central_impulse(direction*throw_speed*held.mass)
	release()

func _physics_process(_delta: float) -> void:
	for index in range(released.size()-1,-1,-1):
		var body: RigidBody2D = released[index]
		if not is_instance_valid(body):
			released.remove_at(index)
		elif separated_from_player(body):
			body.remove_collision_exception_with(player)
			released.remove_at(index)
	if not is_instance_valid(held):
		return
	if held.global_position.distance_to(player.global_position) > reach*2.5:
		release()
		return
	var direction: Vector2 = (player.get_global_mouse_position()-player.global_position).normalized()
	var target: Vector2 = player.global_position + direction*hold_distance
	var ray := PhysicsRayQueryParameters2D.create(player.global_position,target,1|16)
	ray.exclude = [held.get_rid(),player.get_rid()]
	var hit: Dictionary = player.get_world_2d().direct_space_state.intersect_ray(ray)
	if not hit.is_empty():
		var collision: CollisionShape2D = held.get_node("CollisionShape2D")
		target = hit.position + hit.normal*(collision.shape.get_rect().size.length()*0.5+2.0)
	var held_shape: CollisionShape2D = held.get_node("CollisionShape2D")
	hold_query.shape = held_shape.shape
	hold_query.transform = held_shape.global_transform
	hold_query.collision_mask = held.collision_mask
	hold_query.exclude = [held.get_rid(),player.get_rid()]
	hold_query.motion = target-held.global_position
	hold_query.margin = 1.0
	var sweep: PackedFloat32Array = player.get_world_2d().direct_space_state.cast_motion(hold_query)
	target = held.global_position + hold_query.motion*sweep[0]
	var error: Vector2 = target-held.global_position
	var gravity: Vector2 = Vector2.DOWN * float(ProjectSettings.get_setting("physics/2d/default_gravity")) * held.gravity_scale
	var acceleration: Vector2 = error*spring + (player.velocity-held.linear_velocity)*damping - gravity
	held.apply_central_force(acceleration.limit_length(maximum_acceleration)*held.mass)

func separated_from_player(body: RigidBody2D) -> bool:
	var shape: CollisionShape2D = body.get_node("CollisionShape2D")
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape.shape
	query.transform = shape.global_transform
	query.collision_mask = player.collision_layer
	query.exclude = [body.get_rid()]
	query.margin = 3.0
	return player.get_world_2d().direct_space_state.intersect_shape(query,1).is_empty()

func _exit_tree() -> void:
	if is_instance_valid(held):
		held.remove_collision_exception_with(player)
	for body in released:
		if is_instance_valid(body):
			body.remove_collision_exception_with(player)
