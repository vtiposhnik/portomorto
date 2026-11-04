extends "res://tests/run.gd"

func object(scene_name: String, point: Vector2) -> Node2D:
	var node: Node2D = load("res://scenes/environment/"+scene_name+".tscn").instantiate()
	node.position = point
	world.add_child(node)
	return node

func run() -> void:
	await fresh()
	wall(Vector2(0,300),Vector2(2000,40))
	var player := spawn("res://scenes/entities/player.tscn",Vector2(0,256)) as PlayerController
	var crate := spawn("res://scenes/entities/crate.tscn",Vector2(60,256)) as RigidBody2D
	await ticks(5)
	var interaction: ObjectInteraction = player.get_node("Interaction")
	check(interaction.grab(crate),"eligible nearby object can be grabbed")
	await ticks(100)
	check(absf(crate.position.distance_to(player.position)-interaction.hold_distance) < 18 and crate.linear_velocity.length() < 60,"spring hold settles at aim distance without teleporting")
	interaction.release()
	var released_y: float = crate.position.y
	await ticks(18)
	check(crate.position.y > released_y+5,"release restores natural falling")
	crate.mass = 20
	check(not interaction.grab(crate),"mass restriction rejects heavy object")
	crate.mass = 2
	check(interaction.grab(crate),"released object can be grabbed again")
	var before_speed: float = crate.linear_velocity.x
	interaction.throw_toward(player.position+Vector2(500,0))
	await ticks(2)
	check(not is_instance_valid(interaction.held) and crate.linear_velocity.x > before_speed+800,"throw adds bounded forward momentum and releases")
	await fresh()
	player = spawn("res://scenes/entities/player.tscn",Vector2(0,100)) as PlayerController
	player.set_physics_process(false)
	crate = spawn("res://scenes/entities/crate.tscn",Vector2(60,100)) as RigidBody2D
	crate.gravity_scale = 0
	wall(Vector2(30,100),Vector2(10,200))
	await ticks(3)
	check(not player.get_node("Interaction").grab(crate),"cannot grab through solid wall")
	await fresh()
	player = spawn("res://scenes/entities/player.tscn",Vector2(0,100)) as PlayerController
	player.set_physics_process(false)
	crate = spawn("res://scenes/entities/crate.tscn",Vector2(60,100)) as RigidBody2D
	crate.gravity_scale = 0
	interaction = player.get_node("Interaction")
	check(interaction.grab(crate),"generic carry group works without object subclass knowledge")
	wall(Vector2(30,0),Vector2(200,20))
	await ticks(80)
	check(crate.position.y >= 27.75,"held shape remains outside solid ceiling")
	var mouse := InputEventMouseButton.new()
	mouse.button_index = MOUSE_BUTTON_LEFT
	mouse.pressed = true
	interaction._input(mouse)
	check(not is_instance_valid(interaction.held) and root.is_input_handled(),"carried left click is consumed before portal placement")
	# Thrown crate -> accelerator -> rotator on return; shared traveller only.
	await fresh()
	var entry: StaticBody2D = wall(Vector2(200,100),Vector2(40,400))
	var exit_wall: StaticBody2D = wall(Vector2(500,100),Vector2(40,400))
	system.endpoints[0].configure(Vector2(180,100),Vector2.LEFT,entry)
	system.endpoints[1].configure(Vector2(520,100),Vector2.RIGHT,exit_wall)
	system.endpoints[1].effect = AcceleratorEffect.new()
	player = spawn("res://scenes/entities/player.tscn",Vector2(0,100)) as PlayerController
	player.set_physics_process(false)
	crate = spawn("res://scenes/entities/crate.tscn",Vector2(60,100)) as RigidBody2D
	crate.gravity_scale = 0
	interaction = player.get_node("Interaction")
	interaction.grab(crate)
	interaction.throw_toward(Vector2(1000,100))
	for frame in 50:
		await ticks(1)
		if crate.get_node("PortalTraveller").teleport_count:
			break
	check(crate.get_node("PortalTraveller").teleport_count == 1 and crate.linear_velocity.x > 1400,"thrown crate retains amplified portal velocity")
	await fresh()
	var barrel: RigidBody2D = object("barrel",Vector2.ZERO)
	var next_barrel: RigidBody2D = object("barrel",Vector2(80,0))
	barrel.gravity_scale = 0
	next_barrel.gravity_scale = 0
	crate = spawn("res://scenes/entities/crate.tscn",Vector2(0,80)) as RigidBody2D
	crate.gravity_scale = 0
	var target: PhysicsBody2D = spawn("res://scenes/entities/target.tscn",Vector2(-100,0))
	var detonations: Array[int] = [0]
	barrel.get_node("Explosive").detonated.connect(func(): detonations[0]+=1)
	next_barrel.get_node("Explosive").detonated.connect(func(): detonations[0]+=1)
	await ticks(3)
	Damage.deliver(barrel,DamageEvent.new(25))
	barrel.get_node("Explosive").trigger()
	await ticks(5)
	check(detonations[0] == 2 and not is_instance_valid(barrel) and not is_instance_valid(next_barrel),"explosive chain detonates each barrel exactly once")
	check(crate.linear_velocity.length() > 100 and target.get_node("Health").current < 100,"radial explosion pushes bodies and damages by distance")
	await fresh()
	barrel = object("barrel",Vector2.ZERO)
	barrel.gravity_scale = 0
	barrel.linear_velocity = Vector2(1200,0)
	wall(Vector2(180,0),Vector2(40,300))
	await ticks(35)
	check(not is_instance_valid(barrel),"sufficient collision impact detonates barrel")
	await fresh()
	barrel = object("barrel",Vector2(180,0))
	barrel.gravity_scale = 0
	var projectile := spawn("res://scenes/entities/projectile.tscn",Vector2.ZERO) as RigidBody2D
	projectile.linear_velocity = Vector2(700,0)
	await ticks(55)
	check(not is_instance_valid(barrel),"physical projectile detonates barrel")
	await fresh()
	var barrier: StaticBody2D = object("barrier",Vector2(180,0))
	Damage.deliver(barrier,DamageEvent.new(25))
	check(barrier.get_node("Health").current == 35,"barrier loses durability through shared damage contract")
	Damage.deliver(barrier,DamageEvent.new(40))
	await ticks(3)
	var ray := PhysicsRayQueryParameters2D.create(Vector2.ZERO,Vector2(300,0),1)
	check(not is_instance_valid(barrier) and world.get_world_2d().direct_space_state.intersect_ray(ray).is_empty(),"destroyed barrier disappears and no longer blocks physics")
	await fresh()
	var plate: PressurePlate = object("plate",Vector2.ZERO)
	plate.minimum_mass = 3
	var first := spawn("res://scenes/entities/crate.tscn",Vector2(-25,0)) as RigidBody2D
	var second := spawn("res://scenes/entities/crate.tscn",Vector2(25,0)) as RigidBody2D
	first.freeze = true
	second.freeze = true
	await ticks(5)
	check(plate.active,"pressure plate sums multiple bodies to meet mass threshold")
	first.queue_free()
	await ticks(5)
	check(not plate.active,"removing one body updates aggregate pressure")
	plate.minimum_mass = 1
	await ticks(3)
	check(plate.active,"remaining body keeps plate active at lower threshold")
	second.queue_free()
	await ticks(3)
	check(not plate.active,"empty plate deactivates")
	await fresh()
	var button: ActivationSwitch = object("switch",Vector2(0,0))
	var door: MechanismDoor = object("door",Vector2(200,0))
	var door2: MechanismDoor = object("door",Vector2(400,0))
	button.activation_changed.connect(door.receive_activation)
	button.activation_changed.connect(door2.receive_activation)
	button.interact()
	await ticks(110)
	check(door.position.y < -140 and door2.position.y < -140,"one switch opens multiple doors via signals")
	crate = spawn("res://scenes/entities/crate.tscn",Vector2(200,0)) as RigidBody2D
	crate.freeze = true
	button.interact()
	await ticks(160)
	check(door.blocked and door.position.y < -80 and door2.position.y > -1,"closing door stops before trapping a body")
	crate.queue_free()
	await ticks(110)
	check(not door.blocked and absf(door.position.y) < 1,"door closes once obstruction leaves")
	var source := Node.new()
	world.add_child(source)
	door.receive_activation(button,true)
	door.receive_activation(source,true)
	door.receive_activation(button,false)
	check(door.requested_open,"multiple sources independently influence one door")
	source.queue_free()
	await ticks(3)
	check(not door.requested_open,"removing active source clears its door contribution")
	await ticks(50)
	projectile = spawn("res://scenes/entities/projectile.tscn",Vector2(-150,0)) as RigidBody2D
	projectile.linear_velocity = Vector2(700,0)
	var old_active: bool = button.active
	await ticks(40)
	check(button.active != old_active,"projectile activates configured switch")
	await fresh()
	var platform: MovingPlatform = object("platform",Vector2(0,300))
	platform.waypoints = PackedVector2Array([Vector2.ZERO,Vector2(400,0)])
	player = spawn("res://scenes/entities/player.tscn",Vector2(0,264)) as PlayerController
	crate = spawn("res://scenes/entities/crate.tscn",Vector2(45,270)) as RigidBody2D
	await ticks(90)
	check(player.position.x > 30 and absf(player.position.y-264) < 2,"moving platform transports grounded player")
	check(crate.position.x > 65 and absf(crate.position.y-270) < 3,"moving platform transports rigid crate without vertical drift")
	platform.add_to_group("portal_surfaces")
	var placement := PortalPlacement.new()
	placement.system = system
	placement.aim_origin = player
	world.add_child(placement)
	check(not placement.candidate(platform.position+Vector2(0,-150),platform.position,0).get("valid",true),"moving surface rejects portal placement even if misgrouped")
	await fresh()
	var hazard: Area2D = object("spikes",Vector2.ZERO)
	player = spawn("res://scenes/entities/player.tscn",Vector2.ZERO) as PlayerController
	player.set_physics_process(false)
	await ticks(5)
	check(player.get_node("Health").current == 70,"spikes deal contact damage")
	await ticks(5)
	check(player.get_node("Health").current == 70,"hazard cooldown prevents damage every physics tick")
	hazard.queue_free()
	player.get_node("Health").invulnerability_left = 0
	object("lethal_area",Vector2.ZERO)
	await ticks(5)
	check(player.dead,"lethal area uses player death contract")
	await fresh()
	var crusher: MovingPlatform = object("crusher",Vector2(0,100))
	player = spawn("res://scenes/entities/player.tscn",Vector2(0,180)) as PlayerController
	player.set_physics_process(false)
	await ticks(80)
	check(player.dead,"descending crusher damages struck entity")
	check(crusher.step < 0 or crusher.destination == 0,"crusher retreats after strike rather than forcing body into floor")
	# Barrels use the same portal adapter; explosion force may launch them toward a portal.
	await fresh()
	entry = wall(Vector2(200,0),Vector2(40,400))
	exit_wall = wall(Vector2(500,0),Vector2(40,400))
	system.endpoints[0].configure(Vector2(180,0),Vector2.LEFT,entry)
	system.endpoints[1].configure(Vector2(520,0),Vector2.RIGHT,exit_wall)
	var rotator := RotatorEffect.new()
	rotator.angle_degrees = 30
	system.endpoints[1].effect = rotator
	barrel = object("barrel",Vector2(0,0))
	barrel.gravity_scale = 0
	barrel.linear_velocity = Vector2(700,0)
	for frame in 70:
		await ticks(1)
		if barrel.get_node("PortalTraveller").teleport_count:
			break
	check(barrel.get_node("PortalTraveller").teleport_count == 1 and barrel.linear_velocity.y > 300,"barrel traverses rotator with transformed trajectory")
	await fresh()
	entry = wall(Vector2(200,0),Vector2(40,400))
	exit_wall = wall(Vector2(500,0),Vector2(40,400))
	system.endpoints[0].configure(Vector2(180,0),Vector2.LEFT,entry)
	system.endpoints[1].configure(Vector2(520,0),Vector2.RIGHT,exit_wall)
	barrel = object("barrel",Vector2(0,0))
	barrel.gravity_scale = 0
	barrel.get_node("Explosive").impulse = 2400
	crate = spawn("res://scenes/entities/crate.tscn",Vector2(80,0)) as RigidBody2D
	crate.gravity_scale = 0
	await ticks(3)
	Damage.deliver(barrel,DamageEvent.new(25))
	await ticks(50)
	check(crate.get_node("PortalTraveller").teleport_count == 1,"explosion pushes a physical object through a portal")
	await fresh()
	entry = wall(Vector2(0,300),Vector2(500,40))
	exit_wall = wall(Vector2(500,100),Vector2(40,400))
	system.endpoints[0].configure(Vector2(0,280),Vector2.UP,entry)
	system.endpoints[1].configure(Vector2(480,100),Vector2.LEFT,exit_wall)
	plate = object("plate",Vector2(450,100))
	plate.minimum_mass = 1
	var activations: Array[int] = [0]
	plate.activation_changed.connect(func(_source: Node,value: bool):
		if value: activations[0]+=1)
	crate = spawn("res://scenes/entities/crate.tscn",Vector2(0,100)) as RigidBody2D
	await ticks(100)
	check(activations[0] > 0 and crate.get_node("PortalTraveller").teleport_count == 1,"teleported object activates pressure plate")
	await fresh()
	wall(Vector2(0,300),Vector2(2000,40))
	player = spawn("res://scenes/entities/player.tscn",Vector2(0,256)) as PlayerController
	crate = spawn("res://scenes/entities/crate.tscn",Vector2(60,256)) as RigidBody2D
	interaction = player.get_node("Interaction")
	interaction.grab(crate)
	player.get_node("PortalTraveller").teleported.emit(0,1)
	check(not is_instance_valid(interaction.held),"carrier transit releases hold instead of pulling across portal")
	await fresh()
	barrier = object("barrier",Vector2(180,0))
	for index in 3:
		projectile = spawn("res://scenes/entities/projectile.tscn",Vector2(-index*30,0)) as RigidBody2D
		projectile.linear_velocity = Vector2(700,0)
	await ticks(65)
	check(not is_instance_valid(barrier),"projectiles destroy barrier through physical collisions")
	await fresh()
	barrier = object("barrier",Vector2(60,0))
	barrel = object("barrel",Vector2.ZERO)
	barrel.gravity_scale = 0
	await ticks(3)
	Damage.deliver(barrel,DamageEvent.new(25))
	await ticks(4)
	check(not is_instance_valid(barrier),"explosion destroys nearby barrier")
	await fresh()
	barrier = object("barrier",Vector2(180,0))
	crate = spawn("res://scenes/entities/crate.tscn",Vector2.ZERO) as RigidBody2D
	crate.gravity_scale = 0
	crate.linear_velocity = Vector2(1600,0)
	await ticks(35)
	check(not is_instance_valid(barrier),"high-speed crate destroys barrier")
	await fresh()
	platform = object("platform",Vector2.ZERO)
	platform.waypoints = PackedVector2Array([Vector2.ZERO,Vector2(20,0),Vector2(20,-20)])
	platform.speed = 100
	var returned: bool = false
	for frame in 100:
		await ticks(1)
		returned = returned or platform.step < 0
	check(returned,"waypoint platform reverses in ping-pong mode")
	platform.ping_pong = false
	platform.step = 1
	var wrapped: bool = false
	for frame in 100:
		await ticks(1)
		wrapped = wrapped or platform.destination == 0
	check(wrapped,"waypoint platform loops through final segment")
	# Slow-time mechanisms and damage share simulation time, not render frames.
	await fresh()
	var time := TimeControl.new()
	world.add_child(time)
	time.set_process(false)
	time.set_focus(true)
	player = spawn("res://scenes/entities/player.tscn",Vector2(0,256)) as PlayerController
	player.set_physics_process(false)
	crate = spawn("res://scenes/entities/crate.tscn",Vector2(60,256)) as RigidBody2D
	interaction = player.get_node("Interaction")
	check(interaction.grab(crate),"grabbing works during Focus")
	await ticks(100)
	check(is_instance_valid(interaction.held) and crate.linear_velocity.is_finite(),"carrying stays stable during Focus")
	interaction.throw_toward(Vector2(1000,256))
	await ticks(2)
	check(crate.linear_velocity.x > 800,"throw impulse is not reduced by Focus time scale")
	button = object("switch",Vector2.ZERO)
	door = object("door",Vector2(200,0))
	button.activation_changed.connect(door.receive_activation)
	button.interact()
	await ticks(90)
	check(door.position.y < 0 and door.position.y > -100,"door moves consistently under Focus")
	barrel = object("barrel",Vector2(500,0))
	Damage.deliver(barrel,DamageEvent.new(25))
	await ticks(4)
	check(not is_instance_valid(barrel),"explosion detonation works during Focus")
	time.set_focus(false)
	world.queue_free()
	await process_frame
	print("ENVIRONMENT RESULT: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
