class_name HealthComponent
extends Node

signal damaged(event: DamageEvent)
signal depleted
@export var maximum: float = 100.0
var current: float

func _ready() -> void:
	current = maximum

func receive(event: DamageEvent) -> void:
	if current <= 0.0:
		return
	current = maxf(0.0, current - event.amount)
	var body: Node = get_parent()
	if body is RigidBody2D:
		body.apply_central_impulse(event.impulse)
	elif body.has_method("apply_impulse"):
		body.apply_impulse(event.impulse)
	damaged.emit(event)
	if current <= 0.0:
		depleted.emit()
