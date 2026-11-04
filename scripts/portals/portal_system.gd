class_name PortalSystem
extends Node2D

signal transit(traveller: PortalTraveller, entrance: int, exit: int)
@export var exit_margin: float = 3.0
var endpoints: Array[PortalEndpoint] = [PortalEndpoint.new(), PortalEndpoint.new()]

func _ready() -> void:
	add_to_group("portal_system")
	process_physics_priority = -100

func linked() -> bool:
	return endpoints[0].placed and endpoints[1].placed

func _physics_process(delta: float) -> void:
	for node: Node in get_tree().get_nodes_in_group("portal_travellers"):
		var traveller := node as PortalTraveller
		var previous: Array[PhysicsBody2D] = traveller.exceptions.duplicate()
		traveller.clear_exceptions()
		if not linked() or not traveller.enabled:
			continue
		var pos: Vector2 = traveller.body.global_position
		var velocity: Vector2 = traveller.get_velocity()
		for index in 2:
			var entry: PortalEndpoint = endpoints[index]
			var distance: float = (pos - entry.center).dot(entry.normal)
			var reach: float = traveller.support(entry.normal) + velocity.length() * delta * 2.0 + 4.0
			if distance < -reach or distance > reach:
				continue
			# A hole is only opened from its facing side or for an existing entrant.
			if distance < 0.0 and entry.surface not in previous:
				continue
			var future: Vector2 = pos + velocity * delta * 2.0
			var candidate: Dictionary = destination(traveller, index, pos, velocity)
			var allowed: bool = fits(traveller, entry, pos) and fits(traveller, entry, future)
			allowed = allowed and not candidate.is_empty() and clear_at(traveller, candidate.position)
			if allowed:
				traveller.allow_surface(entry.surface)
			elif entry.surface in previous and absf(distance) < traveller.support(entry.normal):
				# Recover a partially inserted body before making its wall solid again.
				var recovery: Dictionary = {
					"position": pos + entry.normal * (traveller.support(entry.normal) + exit_margin - distance),
					"velocity": velocity.slide(entry.normal)}
				if traveller.body is CharacterBody2D:
					traveller.body.global_position = recovery.position
					traveller.body.velocity = recovery.velocity
				else:
					traveller.pending_recovery = recovery

func fits(traveller: PortalTraveller, portal: PortalEndpoint, point: Vector2) -> bool:
	var tangent: Vector2 = PortalMath.tangent(portal.normal)
	return absf((point - portal.center).dot(tangent)) + traveller.support(tangent) <= portal.half_length - 1.0

func destination(traveller: PortalTraveller, index: int, crossing: Vector2, velocity: Vector2, remaining_motion: Vector2 = Vector2.ZERO) -> Dictionary:
	var entry: PortalEndpoint = endpoints[index]
	var out: PortalEndpoint = endpoints[1 - index]
	var offset: float = (crossing - entry.center).dot(PortalMath.tangent(entry.normal))
	var position: Vector2 = out.center - PortalMath.tangent(out.normal) * offset
	position += out.normal * (traveller.support(out.normal) + exit_margin)
	if not fits(traveller, out, position):
		return {}
	var result: Dictionary = {"position": position, "velocity": PortalMath.transform_vector(velocity, entry.normal, out.normal), "motion": PortalMath.transform_vector(remaining_motion, entry.normal, out.normal)}
	if out.effect:
		result = out.effect.modify(result)
	# Reject non-finite results and trajectories into/tangent to the exit wall.
	# Keep the entrance solid rather than silently changing the requested angle.
	if not result.velocity.is_finite() or not result.motion.is_finite() or not result.position.is_finite():
		return {}
	if out.effect:
		var direction: Vector2 = result.velocity
		if direction.length_squared() <= 0.01:
			# Resting entrants still need a valid prospective direction before
			# their floor can open; zero velocity alone has no direction.
			var probe: Dictionary = out.effect.modify({"position":position,"velocity":out.normal,"motion":Vector2.ZERO})
			direction = probe.velocity
		if not direction.is_finite() or direction.dot(out.normal) <= 0.001:
			return {}
	return result

func clear_at(traveller: PortalTraveller, point: Vector2) -> bool:
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = traveller.shape.shape
	query.transform = traveller.shape.global_transform
	query.transform.origin = point + (traveller.shape.global_position - traveller.body.global_position)
	query.collision_mask = traveller.body.collision_mask
	query.exclude = [traveller.body.get_rid()]
	query.margin = 0.5
	return get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty()

func resolve(traveller: PortalTraveller, before: Vector2, after: Vector2, velocity: Vector2) -> Dictionary:
	if not linked():
		return {}
	for index in 2:
		var entry: PortalEndpoint = endpoints[index]
		var fraction: float = PortalMath.crossing_fraction(before, after, entry.center, entry.normal)
		if fraction < 0.0:
			continue
		var crossing: Vector2 = before.lerp(after, fraction)
		if not fits(traveller, entry, crossing):
			continue
		var result: Dictionary = destination(traveller, index, crossing, velocity, after - crossing)
		if result.is_empty() or not clear_at(traveller, result.position):
			# A moving object can occupy an exit after approach was authorized.
			# Return the entrant to the safe side instead of leaving it inside the wall.
			return {"position": crossing + entry.normal * (traveller.support(entry.normal) + exit_margin), "velocity": velocity.slide(entry.normal)}
		# Carry the unspent displacement through the exit with a collision sweep.
		var remainder: Vector2 = result.motion
		var sweep := PhysicsShapeQueryParameters2D.new()
		sweep.shape = traveller.shape.shape
		sweep.transform = traveller.shape.global_transform
		sweep.transform.origin = result.position
		sweep.collision_mask = traveller.body.collision_mask
		sweep.exclude = [traveller.body.get_rid()]
		sweep.motion = remainder
		var safe: PackedFloat32Array = get_world_2d().direct_space_state.cast_motion(sweep)
		result.position += remainder * safe[0]
		traveller.teleport_count += 1
		traveller.teleported.emit(index, 1-index)
		transit.emit(traveller, index, 1-index)
		return result
	return {}
