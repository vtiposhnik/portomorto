class_name Destructible
extends Node

var destroyed: bool = false

func _ready() -> void:
	get_parent().get_node("Health").depleted.connect(destroy)

func destroy() -> void:
	if destroyed:
		return
	destroyed = true
	# Flush-safe: disable collision and remove on the next deferred boundary.
	get_parent().get_node("CollisionShape2D").set_deferred("disabled",true)
	get_parent().queue_free()
