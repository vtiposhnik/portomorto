class_name Carryable
extends Node

func _ready() -> void:
	get_parent().add_to_group("carryable")
