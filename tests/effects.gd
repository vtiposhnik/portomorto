extends "res://tests/run.gd"

func action(controls: PortalEffectControls, name: String) -> void:
	var event := InputEventAction.new()
	event.action = name
	event.pressed = true
	controls._unhandled_input(event)

func pair() -> void:
	var floor_body: StaticBody2D = wall(Vector2(0,300),Vector2(500,40))
	var wall_body: StaticBody2D = wall(Vector2(500,100),Vector2(40,400))
	system.endpoints[0].configure(Vector2(0,280),Vector2.UP,floor_body)
	system.endpoints[1].configure(Vector2(480,100),Vector2.LEFT,wall_body)

func run() -> void:
	var accelerator := AcceleratorEffect.new()
	for normal in [Vector2.UP,Vector2.DOWN,Vector2.LEFT,Vector2.RIGHT,Vector2(0.6,0.8)]:
		var standard: Vector2 = PortalMath.transform_vector(Vector2(100,500),Vector2.UP,normal)
		var modified: Dictionary = accelerator.modify({"velocity":standard,"motion":standard*0.01})
		check(modified.velocity.is_equal_approx(standard*1.5) and modified.motion.is_equal_approx(standard*0.015),"acceleration and remainder follow exit orientation %s" % normal)
	for angle in [-75.0,-15.0,0.0,15.0,75.0]:
		var rotation := RotatorEffect.new()
		rotation.angle_degrees = angle
		var result: Dictionary = rotation.modify({"velocity":Vector2(700,0),"motion":Vector2(7,0)})
		check(result.velocity.is_equal_approx(Vector2(700,0).rotated(deg_to_rad(angle))) and is_equal_approx(result.velocity.length(),700),"rotator signed angle and speed %s" % angle)
	var capped: Dictionary = accelerator.modify({"velocity":Vector2(2200,0),"motion":Vector2(22,0)})
	check(capped.velocity.is_equal_approx(Vector2(2400,0)) and capped.motion.is_equal_approx(Vector2(24,0)),"speed cap also limits unspent displacement")
	await fresh()
	pair()
	var controls := PortalEffectControls.new()
	controls.system = system
	world.add_child(controls)
	var location: Vector2 = system.endpoints[0].center
	action(controls,"effect_accelerator")
	action(controls,"configure_b")
	action(controls,"effect_rotator")
	action(controls,"rotate_clockwise")
	check(system.endpoints[0].effect is AcceleratorEffect and system.endpoints[1].effect is RotatorEffect and system.endpoints[1].effect.angle_degrees == 15,"A and B independently configurable")
	check(system.endpoints[0].center == location and system.linked(),"switching does not replace portals")
	action(controls,"rotate_counterclockwise")
	check(system.endpoints[1].effect.angle_degrees == 0,"wheel counterclockwise reverses angle increment")
	action(controls,"effect_standard")
	check(system.endpoints[1].effect == null and system.endpoints[0].effect is AcceleratorEffect,"standard selection only changes selected endpoint")
	# Each adapter commits a single modified result, rather than accumulating during preparation.
	for entity in ["player","melee_enemy","ranged_enemy","crate","projectile"]:
		await fresh()
		pair()
		system.endpoints[1].effect = AcceleratorEffect.new()
		var body: PhysicsBody2D = spawn("res://scenes/entities/"+entity+".tscn",Vector2(0,120))
		if body is RigidBody2D:
			body.gravity_scale = 0
			body.linear_velocity = Vector2(0,600)
		elif body is PlayerController:
			body.movement.gravity = 0
			body.velocity = Vector2(0,600)
		else:
			body.gravity = 0
			body.velocity = Vector2(0,600)
			body.get_node("Brain").set_physics_process(false)
		for frame in 90:
			await ticks(1)
			if body.get_node("PortalTraveller").teleport_count > 0:
				break
		var traveller: PortalTraveller = body.get_node("PortalTraveller")
		check(traveller.teleport_count == 1 and absf(traveller.get_velocity().length()-900) < 8,entity+" receives one acceleration and preserves launch")
	await fresh()
	pair()
	var rotator := RotatorEffect.new()
	rotator.angle_degrees = 180
	system.endpoints[1].effect = rotator
	var player := spawn("res://scenes/entities/player.tscn",Vector2(0,120)) as PlayerController
	await ticks(90)
	check(player.traveller.teleport_count == 0 and player.is_on_floor(),"backward exit trajectory leaves entrance solid")
	# Live configuration during Focus, with physics continuing at slow speed.
	controls = PortalEffectControls.new()
	controls.system = system
	world.add_child(controls)
	var time := TimeControl.new()
	world.add_child(time)
	time.set_process(false)
	time.set_focus(true)
	action(controls,"configure_b")
	action(controls,"effect_rotator")
	action(controls,"rotate_clockwise")
	check(system.endpoints[1].effect.angle_degrees == 15 and Engine.time_scale == 0.2,"effect controls operate during Focus")
	player.position = Vector2(0,120)
	player.velocity = Vector2(0,600)
	player.movement.gravity = 0
	for frame in 250:
		await ticks(1)
		if player.traveller.teleport_count > 0:
			break
	check(player.traveller.teleport_count == 1 and player.velocity.x < -500 and player.velocity.y < -100,"rotated physical exit during Focus")
	time.set_focus(false)
	await fresh()
	var bottom: StaticBody2D = wall(Vector2(0,300),Vector2(600,40))
	var top: StaticBody2D = wall(Vector2(0,-100),Vector2(600,40))
	system.endpoints[0].configure(Vector2(0,280),Vector2.UP,bottom)
	system.endpoints[1].configure(Vector2(0,-80),Vector2.DOWN,top)
	accelerator = AcceleratorEffect.new()
	accelerator.maximum_speed = 1500
	system.endpoints[1].effect = accelerator
	var shot := spawn("res://scenes/entities/projectile.tscn",Vector2(0,100)) as RigidBody2D
	shot.lifetime = 30
	shot.linear_velocity = Vector2(0,600)
	await ticks(240)
	check(shot.get_node("PortalTraveller").teleport_count >= 3 and is_equal_approx(shot.linear_velocity.length(),1500),"successive boosts saturate at cap without in-frame loop or momentum loss")
	# A rotated projectile must hit a target on the new trajectory.
	await fresh()
	var entry_wall: StaticBody2D = wall(Vector2(200,0),Vector2(40,300))
	var exit_wall: StaticBody2D = wall(Vector2(500,0),Vector2(40,300))
	system.endpoints[0].configure(Vector2(180,0),Vector2.LEFT,entry_wall)
	system.endpoints[1].configure(Vector2(520,0),Vector2.RIGHT,exit_wall)
	rotator = RotatorEffect.new()
	rotator.angle_degrees = 30
	system.endpoints[1].effect = rotator
	var target: PhysicsBody2D = spawn("res://scenes/entities/target.tscn",Vector2(740,122))
	shot = spawn("res://scenes/entities/projectile.tscn",Vector2(0,0)) as RigidBody2D
	shot.linear_velocity = Vector2(700,0)
	await ticks(110)
	check(target.get_node("Health").current == 75,"rotator redirects projectile into damageable target")
	# Compare identical collisions after standard and accelerated crate launches.
	var damages: Array[float] = []
	for boost in [false,true]:
		await fresh()
		pair()
		if boost:
			system.endpoints[1].effect = AcceleratorEffect.new()
		target = spawn("res://scenes/entities/target.tscn",Vector2(300,100))
		var crate := spawn("res://scenes/entities/crate.tscn",Vector2(0,120)) as RigidBody2D
		crate.gravity_scale = 0
		crate.linear_velocity = Vector2(0,800)
		await ticks(80)
		damages.append(100.0-target.get_node("Health").current)
	check(damages[0] > 0 and damages[1] > damages[0],"accelerated crate causes greater collision damage from actual speed")
	await fresh()
	entry_wall = wall(Vector2(200,0),Vector2(40,300))
	exit_wall = wall(Vector2(500,0),Vector2(40,300))
	system.endpoints[0].configure(Vector2(180,0),Vector2.LEFT,entry_wall)
	system.endpoints[1].configure(Vector2(520,0),Vector2.RIGHT,exit_wall)
	system.endpoints[1].effect = AcceleratorEffect.new()
	target = spawn("res://scenes/entities/target.tscn",Vector2(580,0))
	shot = spawn("res://scenes/entities/projectile.tscn",Vector2(0,0)) as RigidBody2D
	shot.linear_velocity = Vector2(6000,0)
	await ticks(25)
	check(target.get_node("Health").current == 75,"capped high-speed exit sweep cannot tunnel past nearby target")
	await fresh()
	pair()
	player = spawn("res://scenes/entities/player.tscn",Vector2(0,270)) as PlayerController
	player.set_physics_process(false)
	player.velocity = Vector2(0,100)
	player.traveller.allow_surface(system.endpoints[0].surface)
	rotator = RotatorEffect.new()
	rotator.angle_degrees = 180
	system.endpoints[1].effect = rotator
	system._physics_process(1.0/120.0)
	check(player.position.y <= 253 and player.traveller.exceptions.is_empty(),"unsafe effect switch recovers a partially inserted body")
	check(InputMap.action_get_events("effect_accelerator").size() > 0 and InputMap.action_get_events("rotate_clockwise").size() > 0,"effect and wheel controls are registered in Input Map")
	world.queue_free()
	await process_frame
	print("EFFECTS RESULT: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
