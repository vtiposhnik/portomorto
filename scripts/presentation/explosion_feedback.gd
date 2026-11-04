extends Node

func _ready() -> void:
	get_parent().get_node("Explosive").detonated.connect(_show)

func _show() -> void:
	var circle := BodyVisual.new()
	circle.circular = true
	circle.size = Vector2.ONE * get_parent().get_node("Explosive").radius * 2.0
	circle.color = Color(1,0.4,0.1,0.2)
	circle.position = get_parent().position
	get_parent().get_parent().add_child(circle)
	get_tree().create_timer(0.15).timeout.connect(circle.queue_free)
