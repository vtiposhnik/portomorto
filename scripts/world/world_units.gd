class_name WorldUnits
extends RefCounted

# Resize physics dimensions explicitly; avoid scaling PhysicsBody2D transforms.
# Visual dimensions are adjusted separately, and can later be replaced with sprites.
static func resize_body(body: PhysicsBody2D, factor: float) -> void:
	var collision: CollisionShape2D = body.get_node("CollisionShape2D")
	collision.shape = collision.shape.duplicate()
	if collision.shape is RectangleShape2D:
		collision.shape.size *= factor
	elif collision.shape is CircleShape2D:
		collision.shape.radius *= factor
	var visual: BodyVisual = body.get_node_or_null("Visual")
	if visual:
		visual.size *= factor
	if body is RigidBody2D:
		body.gravity_scale *= factor
