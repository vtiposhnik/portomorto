class_name PressurePlate
extends Area2D

signal activation_changed(source: Node, active: bool)
@export var minimum_mass: float = 1.0
@export var character_mass: float = 1.0
@export var allow_characters: bool = true
@export var required_group: StringName = &""
var active: bool = false

func _physics_process(_delta: float) -> void:
	var total: float = 0.0
	for body in get_overlapping_bodies():
		if required_group != &"" and not body.is_in_group(required_group):
			continue
		if body is RigidBody2D:
			total += body.mass
		elif allow_characters and body is CharacterBody2D:
			total += character_mass
	var next: bool = total > 0.0 and total >= minimum_mass
	if active != next:
		active = next
		activation_changed.emit(self,active)
