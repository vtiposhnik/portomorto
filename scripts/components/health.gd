class_name HealthComponent
extends Node

signal damaged(event: DamageEvent)
signal depleted
@export var maximum: float = 100.0
@export var invulnerability_duration: float = 0.0
var invulnerability_left: float = 0.0
var current: float

func _ready() -> void:
	current = maximum

func _physics_process(delta: float) -> void:
	invulnerability_left = maxf(0.0, invulnerability_left - delta)

func receive(event: DamageEvent) -> bool:
	if current <= 0.0 or invulnerability_left > 0.0 or event.amount <= 0:
		return false
	invulnerability_left = invulnerability_duration
	current = maxf(0.0, current - event.amount)
	var body: Node = get_parent()
	if body is RigidBody2D:
		body.apply_central_impulse(event.impulse)
	elif body.has_method("apply_impulse"):
		body.apply_impulse(event.impulse)
	damaged.emit(event)
	if current <= 0.0:
		depleted.emit()
	return true
