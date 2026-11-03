class_name PortalMath
extends RefCounted

static func tangent(normal: Vector2) -> Vector2:
	return Vector2(-normal.y, normal.x)

# A proper rotation: inward entrance normal maps to outward exit normal.
# Tangent flips as well, preserving handedness, angles, and speed.
static func transform_vector(value: Vector2, entrance_normal: Vector2, exit_normal: Vector2) -> Vector2:
	return -tangent(exit_normal) * value.dot(tangent(entrance_normal)) - exit_normal * value.dot(entrance_normal)

static func crossing_fraction(before: Vector2, after: Vector2, center: Vector2, normal: Vector2) -> float:
	var a: float = (before - center).dot(normal)
	var b: float = (after - center).dot(normal)
	if a > 0.0 and b <= 0.0:
		return a / (a - b)
	return -1.0
