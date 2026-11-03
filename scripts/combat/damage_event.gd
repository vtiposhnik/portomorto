class_name DamageEvent
extends RefCounted

var amount: float
var impulse: Vector2
var source: Node

func _init(value: float = 10.0, force: Vector2 = Vector2.ZERO, origin: Node = null) -> void:
	amount = value
	impulse = force
	source = origin
