class_name Explosive
extends Node

signal detonated
@export var radius: float = 170.0
@export var damage: float = 100.0
@export var impulse: float = 750.0
@export var target_mask: int = 55
var triggered: bool = false
var finished: bool = false

func _ready() -> void:
	get_parent().get_node("Health").depleted.connect(trigger)

func trigger() -> void:
	if triggered:
		return
	triggered = true
	# Chain reactions enter the deferred queue, never recurse through damage signals.
	call_deferred("_detonate")

func _detonate() -> void:
	if finished or not is_inside_tree():
		return
	finished = true
	var body: RigidBody2D = get_parent()
	var circle := CircleShape2D.new()
	circle.radius = radius
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = circle
	query.transform = Transform2D(0,body.global_position)
	query.collision_mask = target_mask
	query.exclude = [body.get_rid()]
	var seen: Dictionary = {}
	for hit: Dictionary in body.get_world_2d().direct_space_state.intersect_shape(query,128):
		var target: PhysicsBody2D = hit.collider
		if seen.has(target.get_instance_id()):
			continue
		seen[target.get_instance_id()] = true
		var offset: Vector2 = target.global_position-body.global_position
		var strength: float = clampf(1.0-offset.length()/radius,0.0,1.0)
		var force: Vector2 = (offset.normalized() if not offset.is_zero_approx() else Vector2.UP)*impulse*strength
		# Force is independent of health/invulnerability; DamageEvent adds no duplicate impulse.
		if target is RigidBody2D:
			target.apply_central_impulse(force)
		elif target.has_method("apply_impulse"):
			target.apply_impulse(force)
		Damage.deliver(target,DamageEvent.new(damage*strength,Vector2.ZERO,body))
	detonated.emit()
	body.queue_free()
