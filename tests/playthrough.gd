extends "res://tests/run.gd"

var game: RoomManager

func loaded(index: int) -> bool:
	return not game.transitioning and is_instance_valid(game.current_room) and game.room_index == index

func await_room(index: int) -> void:
	for frame in 240:
		if loaded(index):
			return
		await ticks(1)
	check(false,"room %d loaded before timeout" % index)

func move_to(x: float, limit: int = 600) -> void:
	for frame in limit:
		if not is_instance_valid(game.current_room):
			break
		var offset: float = x-game.current_room.player.position.x
		Input.action_release("move_left")
		Input.action_release("move_right")
		if absf(offset) < 5:
			break
		Input.action_press("move_right" if offset > 0 else "move_left")
		await ticks(1)
	Input.action_release("move_left")
	Input.action_release("move_right")
	await ticks(15)

func aim(point: Vector2) -> void:
	var mouse := InputEventMouseMotion.new()
	mouse.position = game.current_room.get_global_transform_with_canvas()*point
	mouse.global_position = mouse.position
	Input.parse_input_event(mouse)

func place(index: int, point: Vector2) -> bool:
	var room: PrototypeRoom = game.current_room
	var candidate: Dictionary = room.placement.candidate(room.player.global_position,point,index)
	if not candidate.get("valid",false):
		return false
	room.portals.endpoints[index].configure(candidate.position,candidate.normal,candidate.surface)
	return true

func focus_check() -> void:
	Input.action_press("focus")
	await ticks(3)
	check(is_equal_approx(Engine.time_scale,0.2),"Focus works in room %d" % (game.room_index+1))
	Input.action_release("focus")
	await ticks(3)
	check(Engine.time_scale == 1.0 and game.current_room.camera.is_current() and game.current_room.camera.target == game.current_room.player,"normal time and camera active in room %d" % (game.room_index+1))

func run() -> void:
	root.size = Vector2i(1280,720)
	game = load("res://scenes/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await await_room(0)
	await ticks(12)
	check(game.room_index == 0 and game.current_room.player.position.distance_to(Vector2(120,576)) < 2,"main scene begins at Room 1 start")
	await focus_check()
	# Execute a normal-jump attempt across the gap; falling must reset this room.
	await move_to(398)
	var old_room: int = game.current_room.get_instance_id()
	Input.action_press("jump")
	Input.action_press("move_right")
	for frame in 300:
		await ticks(1)
		if not is_instance_valid(game.current_room) or game.current_room.get_instance_id() != old_room:
			break
	Input.action_release("jump")
	Input.action_release("move_right")
	await await_room(0)
	check(game.current_room.get_instance_id() != old_room,"gap cannot be crossed by normal jump; death restarts same room")
	await move_to(340)
	check(place(1,Vector2(1300,520)) and place(0,Vector2(340,600)),"legitimate near-floor and far-wall placement")
	var transits: Array[int] = [0]
	game.current_room.portals.transit.connect(func(_body: PortalTraveller,_a:int,_b:int): transits[0]+=1)
	await await_room(1)
	check(game.room_index == 1 and transits[0] > 0,"Room 1 completed through actual portal traversal and exit overlap")
	check(not game.current_room.portals.linked() and game.current_room.effects.selected == 0,"transition clears portals and selected endpoint")
	await focus_check()
	# Rebinding persists across room loads; no InputMap reconstruction occurs.
	var binding := InputEventKey.new()
	binding.physical_keycode = KEY_K
	InputMap.action_add_event("fire",binding)
	await move_to(240)
	var room: PrototypeRoom = game.current_room
	var carry: ObjectInteraction = room.player.get_node("Interaction")
	check(carry.grab(room.crate),"Room 2 crate reachable by normal movement and grab")
	# Aim the spring upward/right while walking; no rigid-body pose is assigned.
	for frame in 300:
		aim(room.player.position+Vector2(85,-30))
		if room.player.position.x >= 565:
			break
		Input.action_press("move_right")
		await ticks(1)
	Input.action_release("move_right")
	for frame in 60:
		aim(Vector2(650,550))
		await ticks(1)
	carry.release()
	await ticks(75)
	print("PUZZLE player ",room.player.position," crate ",room.crate.position," plate ",room.plate.active)
	check(room.plate.active and room.door.requested_open and room.exit_unlocked,"carried crate settles on plate and opens exit")
	# Manual restart restores every puzzle state and portal effect while preserving controls.
	room.portals.endpoints[0].effect = AcceleratorEffect.new()
	room.portals.endpoints[1].effect = RotatorEffect.new()
	room.effects.selected = 1
	old_room = room.get_instance_id()
	var restart_event := InputEventAction.new()
	restart_event.action = "reset"
	restart_event.pressed = true
	game._unhandled_input(restart_event)
	await ticks(5)
	await await_room(1)
	check(game.current_room.get_instance_id() != old_room and not game.current_room.plate.active and not game.current_room.door.requested_open,"manual restart resets crate, plate, door and room instance")
	check(game.current_room.portals.endpoints[0].effect == null and game.current_room.portals.endpoints[1].effect == null and game.current_room.effects.selected == 0 and InputMap.action_has_event("fire",binding),"restart resets effects but preserves control bindings")
	# Repeat the puzzle with the same physical carrying route.
	await move_to(240)
	room = game.current_room
	carry = room.player.get_node("Interaction")
	carry.grab(room.crate)
	for frame in 300:
		aim(room.player.position+Vector2(85,-30))
		if room.player.position.x >= 565: break
		Input.action_press("move_right")
		await ticks(1)
	Input.action_release("move_right")
	for frame in 60:
		aim(Vector2(650,550))
		await ticks(1)
	carry.release()
	await ticks(75)
	check(room.plate.active,"puzzle is repeatably solvable after restart")
	Input.action_press("jump")
	Input.action_press("move_right")
	await ticks(80)
	Input.action_release("jump")
	Input.action_release("move_right")
	await move_to(1200)
	await await_room(2)
	check(game.room_index == 2 and not game.current_room.exit_unlocked,"Room 2 exit transitions to locked combat arena")
	await focus_check()
	room = game.current_room
	# Perturb arena state through its real components, then verify room-local reset.
	await move_to(240)
	carry = room.player.get_node("Interaction")
	carry.grab(room.crate)
	Damage.deliver(room.get_node("Barrel"),DamageEvent.new(25))
	Damage.deliver(get_nodes_in_group("enemies")[0],DamageEvent.new(5))
	place(0,Vector2(240,600))
	place(1,Vector2(1100,600))
	room.portals.endpoints[1].effect = AcceleratorEffect.new()
	Input.action_press("focus")
	await ticks(3)
	old_room = room.get_instance_id()
	game._unhandled_input(restart_event)
	await ticks(5)
	await await_room(2)
	room = game.current_room
	check(room.get_instance_id() != old_room and room.enemies_left == 2 and room.has_node("Barrel") and room.has_node("Spikes"),"arena restart restores enemies, explosive and hazard")
	check(not room.portals.linked() and room.portals.endpoints[1].effect == null and not is_instance_valid(room.player.get_node("Interaction").held) and Engine.time_scale == 1.0,"restart clears held object, portal effects and Focus")
	check(get_nodes_in_group("player").size() == 1 and get_nodes_in_group("portal_system").size() == 1,"unloading leaves no duplicate actor or portal system")
	old_room = room.get_instance_id()
	Damage.deliver(room.player,DamageEvent.new(1000))
	await ticks(110)
	await await_room(2)
	room = game.current_room
	check(room.get_instance_id() != old_room and room.player.get_node("Health").current == 100 and room.enemies_left == 2,"arena death restarts current room with full health and restored enemies")
	# Clear the firing lane by grabbing and throwing the crate back toward spawn.
	await move_to(240)
	carry = room.player.get_node("Interaction")
	check(carry.grab(room.crate),"arena crate can be manipulated before combat")
	carry.throw_toward(room.player.position+Vector2(-500,-100))
	# Fight using real player projectiles, with normal jump inputs and Focus.
	Input.action_press("focus")
	for frame in 1800:
		if game.current_room != room or room.player.dead:
			break
		if room.enemies_left == 0:
			break
		if room.player.is_on_floor():
			Input.action_release("jump")
			await ticks(1)
			Input.action_press("jump")
		if frame % 12 == 0:
			var enemies: Array[Node] = get_nodes_in_group("enemies")
			if not enemies.is_empty():
				room.fire_toward(enemies[0].global_position)
		await ticks(1)
	Input.action_release("jump")
	Input.action_release("focus")
	check(is_instance_valid(room) and not room.player.dead and room.enemies_left == 0 and room.exit_unlocked,"both arena enemies defeated by actual projectiles; exit unlocks")
	if is_instance_valid(room) and not room.player.dead and room.enemies_left == 0:
		# Move along the upper side of the spike strip with ordinary jumps.
		await move_to(820)
		Input.action_press("jump")
		Input.action_press("move_right")
		await ticks(80)
		Input.action_release("jump")
		Input.action_release("move_right")
		await move_to(1200)
	for frame in 100:
		await ticks(1)
		if game.completed: break
	check(game.completed and is_instance_valid(game.completion_ui),"Room 3 exit displays completion screen")
	check(get_nodes_in_group("player").is_empty() and get_nodes_in_group("portal_system").is_empty() and Engine.time_scale == 1.0,"completion unloads actors, portals and slow time")
	game.restart()
	await ticks(5)
	await await_room(0)
	check(not game.completed and game.room_index == 0,"completion restart begins a fresh Room 1")
	check(InputMap.action_has_event("fire",binding),"controls persist through completion and fresh run")
	await move_to(340)
	check(place(1,Vector2(1200,600)) and place(0,Vector2(340,600)),"optional floor-to-exit shortcut uses valid placement")
	await await_room(1)
	check(game.room_index == 1,"optional portal shortcut completes Room 1")
	InputMap.action_erase_event("fire",binding)
	game.queue_free()
	await process_frame
	print("PLAYTHROUGH RESULT: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
