extends SceneTree

var checks: int = 0
var failures: int = 0
var world: Node2D
var system: PortalSystem

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("FAIL: " + description)
	else:
		print("PASS: " + description)

func ticks(count: int) -> void:
	for index in count:
		await physics_frame
		await process_frame

func wall(point: Vector2, size: Vector2, angle: float = 0.0) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.position = point
	body.rotation = angle
	body.add_to_group("portal_surfaces")
	var shape := RectangleShape2D.new()
	shape.size = size
	var collision := CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	collision.shape = shape
	body.add_child(collision)
	world.add_child(body)
	return body

func fresh() -> void:
	if world:
		world.queue_free()
		await process_frame
	world = Node2D.new()
	root.add_child(world)
	system = PortalSystem.new()
	world.add_child(system)
	await ticks(2)

func spawn(path: String, point: Vector2) -> PhysicsBody2D:
	var body: PhysicsBody2D = load(path).instantiate()
	body.position = point
	world.add_child(body)
	return body

func run() -> void:
	for a in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT, Vector2(0.6, -0.8)]:
		for b in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT, Vector2(-0.8, 0.6)]:
			var velocity := Vector2(321, -567)
			var transformed: Vector2 = PortalMath.transform_vector(velocity, a, b)
			check(is_equal_approx(velocity.length(), transformed.length()) and PortalMath.transform_vector(transformed, b, a).is_equal_approx(velocity), "speed and inverse transform %s -> %s" % [a,b])
	check(PortalMath.crossing_fraction(Vector2(0,-1), Vector2(0,1), Vector2.ZERO, Vector2.UP) == 0.5, "inward plane crossing")
	check(PortalMath.crossing_fraction(Vector2(0,1), Vector2(0,-1), Vector2.ZERO, Vector2.UP) < 0, "outward movement cannot enter")
	await fresh()
	var ground: StaticBody2D = wall(Vector2(0,300), Vector2(2000,40))
	var player := spawn("res://scenes/entities/player.tscn", Vector2(0,100)) as PlayerController
	player.set_physics_process(false)
	await ticks(2)
	for index in 90:
		player.step(1.0/120.0, 0, false, false)
		await ticks(1)
	check(player.is_on_floor() and absf(player.position.y - 256.0) < 1, "player lands on solid floor")
	player.step(1.0/120.0, 0, true, true)
	check(player.velocity.y < -500, "responsive grounded jump")
	player.step(1.0/120.0, 0, false, false)
	check(player.velocity.y > -300, "jump release cuts ascent")
	player.position = Vector2(0,0)
	player.velocity = Vector2(900,0)
	player.step(1.0/120.0, 1, false, false)
	check(player.velocity.x > 899, "air input preserves launch momentum above run speed")
	player.coyote_left = 0.08
	player.step(1.0/120.0, 0, true, true)
	check(player.velocity.y < -500, "coyote jump after leaving ground")
	player.coyote_left = 0
	player.position = Vector2(0,251)
	player.velocity = Vector2(0,300)
	player.step(1.0/120.0,0,true,true)
	for index in 8:
		player.step(1.0/120.0,0,false,true)
		await ticks(1)
	check(player.velocity.y < -400, "buffered jump executes on landing")
	await fresh()
	ground = wall(Vector2(0,300),Vector2(500,40))
	var side: StaticBody2D = wall(Vector2(500,100),Vector2(40,400))
	system.endpoints[0].configure(Vector2(0,280),Vector2.UP,ground)
	system.endpoints[1].configure(Vector2(480,100),Vector2.LEFT,side)
	player = spawn("res://scenes/entities/player.tscn",Vector2(0,120)) as PlayerController
	for frame in 100:
		await ticks(1)
		if player.traveller.teleport_count > 0:
			break
	check(player.traveller.teleport_count == 1, "player crosses physical floor portal and exits wall once")
	check(player.position.x < 465 and player.velocity.x < -100, "player exit has transformed momentum and clearance")
	await fresh()
	ground = wall(Vector2(0,300),Vector2(500,40))
	side = wall(Vector2(500,100),Vector2(40,400))
	system.endpoints[0].configure(Vector2(0,280),Vector2.UP,ground)
	system.endpoints[1].configure(Vector2(480,100),Vector2.LEFT,side)
	var crate := spawn("res://scenes/entities/crate.tscn",Vector2(0,120)) as RigidBody2D
	for frame in 100:
		await ticks(1)
		if crate.get_node("PortalTraveller").teleport_count > 0:
			break
	check(crate.get_node("PortalTraveller").teleport_count == 1, "rigid crate crosses real portal")
	check(crate.position.x < 465 and crate.linear_velocity.x < -100, "crate keeps transformed velocity")
	await fresh()
	var left: StaticBody2D = wall(Vector2(200,0),Vector2(40,300))
	var right: StaticBody2D = wall(Vector2(500,0),Vector2(40,300))
	system.endpoints[0].configure(Vector2(180,0),Vector2.LEFT,left)
	system.endpoints[1].configure(Vector2(520,0),Vector2.RIGHT,right)
	var target := spawn("res://scenes/entities/target.tscn",Vector2(750,0)) as StaticBody2D
	var projectile := spawn("res://scenes/entities/projectile.tscn",Vector2(0,0)) as RigidBody2D
	projectile.linear_velocity = Vector2(850,0)
	var impulses: Array[Vector2] = []
	target.get_node("Health").damaged.connect(func(event: DamageEvent): impulses.append(event.impulse))
	var transits: Array[int] = [0]
	system.transit.connect(func(_who: PortalTraveller,_a:int,_b:int): transits[0] += 1)
	await ticks(110)
	check(transits[0] == 1, "projectile crosses wall portal")
	check(target.get_node("Health").current == 75, "projectile damages target after teleportation")
	check(impulses.size() == 1 and impulses[0].is_equal_approx(Vector2(180,0)), "projectile damage carries exit-direction knockback")
	await fresh()
	ground = wall(Vector2(0,300),Vector2(500,40))
	side = wall(Vector2(500,100),Vector2(40,400))
	system.endpoints[0].configure(Vector2(0,280),Vector2.UP,ground)
	system.endpoints[1].configure(Vector2(480,100),Vector2.LEFT,side)
	wall(Vector2(450,100),Vector2(40,120))
	player = spawn("res://scenes/entities/player.tscn",Vector2(0,120)) as PlayerController
	await ticks(100)
	check(player.traveller.teleport_count == 0 and player.is_on_floor(), "blocked exit preserves entrance collision")
	player.position = Vector2(-150,200)
	var placement := PortalPlacement.new()
	placement.system = system
	placement.aim_origin = player
	world.add_child(placement)
	await ticks(2)
	check(placement.candidate(Vector2(100,0),Vector2(100,300),0).get("valid", false), "valid floor placement")
	check(not placement.candidate(Vector2(240,0),Vector2(240,300),0).get("valid",true), "edge placement rejected")
	check(not placement.candidate(Vector2(500,-300),Vector2(500,0),0).get("valid",true), "portal too wide for narrow face rejected")
	var time := TimeControl.new()
	world.add_child(time)
	time.set_process(false)
	time.set_focus(true)
	check(is_equal_approx(Engine.time_scale,0.2) and is_equal_approx(TimeControl.real_delta(0.002),0.01), "focus scales simulation and unscales presentation")
	time.set_focus(false)
	check(Engine.time_scale == 1.0, "focus restores normal speed")
	var health: HealthComponent = player.get_node("Health")
	health.current = health.maximum
	health.invulnerability_left = 0.0
	var before: Vector2 = player.velocity
	Damage.deliver(player,DamageEvent.new(12,Vector2(100,-200)))
	check(health.current == 88 and player.velocity.is_equal_approx(before+Vector2(100,-200)), "central damage applies health and knockback")
	# Actual repeated ceiling -> floor chaining has no arbitrary cooldown.
	await fresh()
	ground = wall(Vector2(0,300),Vector2(500,40))
	var ceiling: StaticBody2D = wall(Vector2(0,-100),Vector2(500,40))
	system.endpoints[0].configure(Vector2(0,280),Vector2.UP,ground)
	system.endpoints[1].configure(Vector2(0,-80),Vector2.DOWN,ceiling)
	crate = spawn("res://scenes/entities/crate.tscn",Vector2(0,120)) as RigidBody2D
	await ticks(240)
	check(crate.get_node("PortalTraveller").teleport_count >= 3, "ceiling-floor rapid chaining without cooldown")
	check(crate.position.y > -80 and crate.position.y < 300, "chaining remains within safe corridor")
	await fresh()
	var rotated_normal := Vector2.UP.rotated(0.4)
	ground = wall(Vector2(0,300),Vector2(500,40),0.4)
	var entrance_center: Vector2 = Vector2(0,300) + rotated_normal*20
	side = wall(Vector2(500,0),Vector2(40,400))
	system.endpoints[0].configure(entrance_center,rotated_normal,ground)
	system.endpoints[1].configure(Vector2(480,0),Vector2.LEFT,side)
	projectile = spawn("res://scenes/entities/projectile.tscn",entrance_center+rotated_normal*100) as RigidBody2D
	projectile.linear_velocity = -rotated_normal*700
	await ticks(22)
	check(is_instance_valid(projectile) and projectile.get_node("PortalTraveller").teleport_count == 1, "projectile traverses rotated surface")
	if is_instance_valid(projectile):
		check(projectile.linear_velocity.distance_to(Vector2(-700,0)) < 1.0, "rotated physical transit preserves direction and speed")
	placement = PortalPlacement.new()
	placement.system = system
	placement.aim_origin = side
	world.add_child(placement)
	await ticks(2)
	check(placement.candidate(entrance_center+rotated_normal*100,entrance_center,0).get("valid",false), "rotated rectangle placement accepted")
	await fresh()
	left = wall(Vector2(200,0),Vector2(40,300))
	right = wall(Vector2(500,0),Vector2(40,300))
	system.endpoints[0].configure(Vector2(180,0),Vector2.LEFT,left)
	system.endpoints[1].configure(Vector2(520,0),Vector2.RIGHT,right)
	projectile = spawn("res://scenes/entities/projectile.tscn",Vector2(150,0)) as RigidBody2D
	await ticks(20)
	check(projectile.get_node("PortalTraveller").teleport_count == 0, "proximity alone never teleports")
	projectile.linear_velocity = Vector2(-300,0)
	await ticks(20)
	check(projectile.get_node("PortalTraveller").teleport_count == 0, "moving away never teleports")
	projectile.queue_free()
	await ticks(2)
	placement = PortalPlacement.new()
	placement.system = system
	placement.aim_origin = left
	world.add_child(placement)
	await ticks(2)
	check(not placement.candidate(Vector2(700,0),Vector2(500,0),0).get("valid",true), "overlapping placement rejected")
	time = TimeControl.new()
	world.add_child(time)
	time.set_process(false)
	time.set_focus(true)
	projectile = spawn("res://scenes/entities/projectile.tscn",Vector2(0,0)) as RigidBody2D
	projectile.linear_velocity = Vector2(850,0)
	await ticks(200)
	check(projectile.get_node("PortalTraveller").teleport_count == 1, "projectile crosses during Focus")
	check(absf(projectile.linear_velocity.length()-850) < 1.0, "Focus does not multiply velocity")
	time.set_focus(false)
	await fresh()
	ground = wall(Vector2(0,300),Vector2(500,40))
	side = wall(Vector2(500,100),Vector2(40,400))
	system.endpoints[0].configure(Vector2(0,280),Vector2.UP,ground)
	system.endpoints[1].configure(Vector2(480,100),Vector2.LEFT,side)
	player = spawn("res://scenes/entities/player.tscn",Vector2(0,270)) as PlayerController
	player.set_physics_process(false)
	await ticks(2)
	player.traveller.allow_surface(ground)
	player.velocity = Vector2(4000,50)
	system._physics_process(1.0/120.0)
	check(player.position.y <= 253 and player.traveller.exceptions.is_empty(), "lateral aperture escape recovers before restoring wall")
	player.position = Vector2(0,330)
	player.velocity = Vector2(0,-500)
	system._physics_process(1.0/120.0)
	check(player.traveller.exceptions.is_empty(), "back-face approach retains wall collision")
	await fresh()
	ground = wall(Vector2(0,300),Vector2(2000,40))
	player = spawn("res://scenes/entities/player.tscn",Vector2(-100,256)) as PlayerController
	crate = spawn("res://scenes/entities/crate.tscn",Vector2(0,262)) as RigidBody2D
	await ticks(10)
	Input.action_press("move_right")
	await ticks(65)
	Input.action_release("move_right")
	check(crate.position.x > 20, "player physically pushes rigid crate")
	await fresh()
	ground = wall(Vector2(0,300),Vector2(2000,40))
	ceiling = wall(Vector2(0,150),Vector2(2000,20))
	player = spawn("res://scenes/entities/player.tscn",Vector2(0,256)) as PlayerController
	await ticks(10)
	Input.action_press("jump")
	var min_y: float = player.position.y
	for frame in 35:
		await ticks(1)
		min_y = minf(min_y, player.position.y)
	Input.action_release("jump")
	check(min_y >= 183.0 and min_y < 220.0, "jump collides with ordinary ceiling without clipping")
	# The complete main scene exercises composition, HUD, camera, input, and reset.
	world.queue_free()
	await process_frame
	var sandbox: Node = load("res://scenes/sandbox.tscn").instantiate()
	root.add_child(sandbox)
	current_scene = sandbox
	await ticks(20)
	Input.action_press("focus")
	await process_frame
	await process_frame
	check(is_equal_approx(Engine.time_scale,0.2), "held Focus action reaches central time controller")
	Input.action_release("focus")
	await process_frame
	await process_frame
	check(Engine.time_scale == 1.0, "released Focus action restores time")
	var old_id: int = sandbox.get_instance_id()
	var reset_event := InputEventAction.new()
	reset_event.action = "reset"
	reset_event.pressed = true
	sandbox._unhandled_input(reset_event)
	await ticks(8)
	check(is_instance_valid(current_scene) and current_scene.get_instance_id() != old_id, "reset reloads main scene")
	check(Engine.time_scale == 1.0 and get_nodes_in_group("portal_system").size() == 1, "reset cleans up simulation and portal manager")
	current_scene.queue_free()
	await process_frame
	sandbox = load("res://scenes/sandbox.tscn").instantiate()
	sandbox.world_scale = 1.5
	root.add_child(sandbox)
	current_scene = sandbox
	await ticks(100)
	check(sandbox.player.is_on_floor() and absf(sandbox.player.position.y - 864.0) < 1.0, "scaled sandbox has consistent ground and character dimensions")
	check(sandbox.player.movement.max_speed == 495 and sandbox.player.movement.gravity == 2400, "world scale updates movement units")
	world = current_scene
	world.queue_free()
	await process_frame
	print("RESULT: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
