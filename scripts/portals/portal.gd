class_name PortalEndpoint
extends RefCounted

var placed: bool = false
var center: Vector2 = Vector2.ZERO
var normal: Vector2 = Vector2.UP
var surface: StaticBody2D
var half_length: float = 56.0
var effect: PortalEffect

func configure(point: Vector2, facing: Vector2, wall: StaticBody2D) -> void:
	center = point
	normal = facing.normalized()
	surface = wall
	placed = true
