class_name RoomManager
extends Node

const ROOMS: Array[PackedScene] = [preload("res://scenes/rooms/traversal.tscn"),preload("res://scenes/rooms/puzzle.tscn"),preload("res://scenes/rooms/arena.tscn")]
var current_room: PrototypeRoom
var room_index: int = 0
var transitioning: bool = true
var completed: bool = false
var completion_ui: CanvasLayer

func _ready() -> void:
	_load_room.call_deferred(0)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("reset"):
		restart()

func restart() -> void:
	if transitioning:
		return
	transitioning = true
	_load_room.call_deferred(0 if completed else room_index)

func _advance() -> void:
	if transitioning or not is_instance_valid(current_room) or not current_room.exit_unlocked:
		return
	transitioning = true
	_load_room.call_deferred(room_index+1)

func _load_room(index: int) -> void:
	if is_instance_valid(current_room):
		current_room.process_mode = Node.PROCESS_MODE_DISABLED
		current_room.player.get_node("Interaction").release()
		current_room.queue_free()
		current_room = null
	if is_instance_valid(completion_ui):
		completion_ui.queue_free()
	# Drain destruction before adding another player's groups, camera or portal system.
	await get_tree().process_frame
	Engine.time_scale = 1.0
	Input.action_release("focus")
	completed = index >= ROOMS.size()
	if completed:
		_show_completion()
	else:
		room_index = index
		current_room = ROOMS[index].instantiate()
		current_room.exit_reached.connect(_advance)
		current_room.restart_requested.connect(restart)
		add_child(current_room)
	transitioning = false

func _show_completion() -> void:
	completion_ui = CanvasLayer.new()
	var text := Label.new()
	text.position = Vector2(120,220)
	text.add_theme_font_size_override("font_size",28)
	text.text = "PROTOTYPE COMPLETE\n\nTraversal · Physics puzzle · Combat\n\nPress R to start again from Room 1."
	completion_ui.add_child(text)
	add_child(completion_ui)
