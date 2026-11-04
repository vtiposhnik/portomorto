extends Node2D

@export var world_scale: float = 1.0

func item(scene_name: String, point: Vector2) -> Node2D:
	var node: Node2D = load("res://scenes/environment/"+scene_name+".tscn").instantiate()
	node.position = point*world_scale
	if node is PhysicsBody2D:
		WorldUnits.resize_body(node,world_scale)
	else:
		node.get_node("CollisionShape2D").shape = node.get_node("CollisionShape2D").shape.duplicate()
		node.get_node("CollisionShape2D").shape.size *= world_scale
		node.get_node("Visual").size *= world_scale
	if node is MechanismDoor:
		node.open_offset *= world_scale
		node.opening_speed *= world_scale
		node.closing_speed *= world_scale
	if node is MovingPlatform:
		for index in node.waypoints.size():
			node.waypoints[index] *= world_scale
		node.speed *= world_scale
		if node.has_node("CrushSensor"):
			var sensor: Area2D = node.get_node("CrushSensor")
			sensor.position *= world_scale
			sensor.get_node("CollisionShape2D").shape = sensor.get_node("CollisionShape2D").shape.duplicate()
			sensor.get_node("CollisionShape2D").shape.size *= world_scale
			sensor.get_node("Visual").size *= world_scale
	if node.has_node("Explosive"):
		node.get_node("Explosive").radius *= world_scale
		node.get_node("Explosive").impulse *= world_scale
	add_child(node)
	return node

func _ready() -> void:
	# Sections share the existing runway; no level-specific logic lives in devices.
	item("barrel",Vector2(1860,560))
	item("barrel",Vector2(1960,560))
	item("barrier",Vector2(2070,540))
	var plate: PressurePlate = item("plate",Vector2(2210,591))
	var button: ActivationSwitch = item("switch",Vector2(2300,565))
	var door: MechanismDoor = item("door",Vector2(2490,530))
	var second: MechanismDoor = item("door",Vector2(2600,530))
	plate.activation_changed.connect(door.receive_activation)
	button.activation_changed.connect(door.receive_activation)
	button.activation_changed.connect(second.receive_activation)
	door.receive_activation(plate,false)
	door.receive_activation(button,false)
	var platform: MovingPlatform = item("platform",Vector2(2720,510))
	platform.waypoints = PackedVector2Array([Vector2.ZERO,Vector2(200,-110)*world_scale])
	item("crusher",Vector2(3040,400))
	item("spikes",Vector2(2860,590))
	item("lethal_area",Vector2(3260,590))
