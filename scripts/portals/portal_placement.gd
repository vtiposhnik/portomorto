class_name PortalPlacement
extends Node2D

@export var range_limit: float = 1800.0
@export var edge_margin: float = 5.0
var system: PortalSystem
var aim_origin: Node2D
var preview: Dictionary = {}
var selected: int = 0

func _process(_delta: float) -> void:
	preview = candidate(aim_origin.global_position, get_global_mouse_position(), selected)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
			selected = 0 if event.button_index == MOUSE_BUTTON_LEFT else 1
			preview = candidate(aim_origin.global_position, get_global_mouse_position(), selected)
			if preview.get("valid", false):
				system.endpoints[selected].configure(preview.position, preview.normal, preview.surface)

func candidate(origin: Vector2, aim: Vector2, index: int) -> Dictionary:
	var ray := PhysicsRayQueryParameters2D.create(origin, origin + (aim-origin).normalized() * range_limit, 1)
	var hit: Dictionary = get_world_2d().direct_space_state.intersect_ray(ray)
	if hit.is_empty():
		return {}
	var result: Dictionary = {"position": hit.position, "normal": hit.normal, "surface": hit.collider, "valid": false}
	if not hit.collider.is_in_group("portal_surfaces"):
		return result
	var wall := hit.collider as StaticBody2D
	var collision: CollisionShape2D = wall.get_node_or_null("CollisionShape2D")
	if collision == null or not collision.shape is RectangleShape2D:
		return result
	var normal: Vector2 = hit.normal
	var tangent: Vector2 = PortalMath.tangent(normal)
	var half: float = system.endpoints[index].half_length
	# Exact bounds for supported convex rectangle faces, plus probes to reject occlusion.
	var local: Vector2 = collision.to_local(hit.position)
	var local_tangent: Vector2 = tangent.rotated(-collision.global_rotation)
	var extent: Vector2 = collision.shape.size * 0.5
	for sign_value: float in [-1.0, 1.0]:
		var edge: Vector2 = local + local_tangent * (half + edge_margin) * sign_value
		if absf(edge.x) > extent.x + 0.1 or absf(edge.y) > extent.y + 0.1:
			return result
	for offset in [-half, 0.0, half]:
		var point: Vector2 = hit.position + tangent * offset
		var probe := PhysicsRayQueryParameters2D.create(point + normal * 8.0, point - normal * 2.0, 1)
		var sample: Dictionary = get_world_2d().direct_space_state.intersect_ray(probe)
		if sample.is_empty() or sample.collider != wall or sample.normal.dot(normal) < 0.99:
			return result
	# Reserve an outward strip for an aperture; entity-specific clearance is checked at transit.
	var strip := RectangleShape2D.new()
	strip.size = Vector2(half * 2.0, 6.0)
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = strip
	query.transform = Transform2D(tangent.angle(), hit.position + normal * 4.0)
	query.collision_mask = 1
	query.exclude = [wall.get_rid()]
	if not get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty():
		return result
	var other: PortalEndpoint = system.endpoints[1-index]
	if other.placed and hit.position.distance_to(other.center) < half + other.half_length + edge_margin:
		return result
	# Moving a portal out from under an intersecting body would restore solid wall inside it.
	var old: PortalEndpoint = system.endpoints[index]
	if old.placed:
		for node: Node in get_tree().get_nodes_in_group("portal_travellers"):
			var traveller := node as PortalTraveller
			var relative: Vector2 = traveller.body.global_position - old.center
			if absf(relative.dot(old.normal)) < traveller.support(old.normal) + 1.0 and system.fits(traveller, old, traveller.body.global_position):
				return result
	result.valid = true
	return result
