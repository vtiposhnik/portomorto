extends "res://tests/run.gd"

func enemy(kind: String, point: Vector2) -> EnemyMotor:
	return spawn("res://scenes/entities/"+kind+"_enemy.tscn",point) as EnemyMotor

func run() -> void:
	await fresh()
	wall(Vector2(0,300),Vector2(3000,40))
	var player := spawn("res://scenes/entities/player.tscn",Vector2(45,256)) as PlayerController
	var melee: EnemyMotor = enemy("melee",Vector2(0,256))
	await ticks(20)
	check(melee.get_node("Brain").attacks > 0 and player.get_node("Health").current < 100,"melee detects and damages player")
	var health: HealthComponent = player.get_node("Health")
	# At low render caps the first melee hit may already be older than 0.5s.
	# Establish a fresh accepted hit before testing immediate duplicate rejection.
	if health.invulnerability_left <= 0.0:
		Damage.deliver(player,DamageEvent.new(1))
	var hp: float = health.current
	check(not Damage.deliver(player,DamageEvent.new(10)) and health.current == hp,"player rejects damage during invulnerability")
	melee.queue_free()
	await ticks(80)
	check(Damage.deliver(player,DamageEvent.new(5)),"invulnerability expires in simulation time")
	await fresh()
	wall(Vector2(0,300),Vector2(3000,40))
	player = spawn("res://scenes/entities/player.tscn",Vector2(300,256)) as PlayerController
	var ranged: EnemyMotor = enemy("ranged",Vector2(0,256))
	await ticks(100)
	check(ranged.get_node("Brain").attacks > 0,"ranged detects and fires")
	check(player.get_node("Health").current < 100,"physical enemy projectile damages player")
	Damage.deliver(ranged,DamageEvent.new(1000))
	await ticks(2)
	check(not is_instance_valid(ranged),"enemy depletion removes body and AI")
	for kind in ["melee","ranged"]:
		await fresh()
		var ground: StaticBody2D = wall(Vector2(0,300),Vector2(500,40))
		var side: StaticBody2D = wall(Vector2(500,100),Vector2(40,400))
		system.endpoints[0].configure(Vector2(0,280),Vector2.UP,ground)
		system.endpoints[1].configure(Vector2(480,100),Vector2.LEFT,side)
		var body: EnemyMotor = enemy(kind,Vector2(0,120))
		body.get_node("Health").maximum = 1000
		body.get_node("Health").current = 1000
		body.apply_impulse(Vector2(0,350))
		for frame in 100:
			await ticks(1)
			if body.get_node("PortalTraveller").teleport_count:
				break
		check(body.get_node("PortalTraveller").teleport_count == 1 and body.velocity.x < -300,kind+" knockback enters floor portal and exits with transformed velocity")
		player = spawn("res://scenes/entities/player.tscn",body.position+Vector2(-100,0)) as PlayerController
		await ticks(4)
		check(body.get_node("Brain").state != EnemyBrain.State.IDLE,kind+" AI resumes targeting after transit")
	await fresh()
	var victim: EnemyMotor = enemy("melee",Vector2(180,0))
	victim.gravity = 0
	victim.get_node("Brain").set_physics_process(false)
	var crate := spawn("res://scenes/entities/crate.tscn",Vector2(0,0)) as RigidBody2D
	crate.gravity_scale = 0
	crate.linear_velocity = Vector2(1000,0)
	var hits: Array[float] = []
	victim.get_node("Health").damaged.connect(func(event: DamageEvent): hits.append(event.amount))
	await ticks(35)
	check(hits.size() == 1 and hits[0] > 20,"launched crate inflicts one relative-speed impact on enemy")
	await fresh()
	victim = enemy("melee",Vector2(0,0))
	victim.gravity = 0
	victim.set_physics_process(false)
	crate = spawn("res://scenes/entities/crate.tscn",Vector2(200,0)) as RigidBody2D
	crate.freeze = true
	var impact: ImpactDamage = crate.get_node("ImpactDamage")
	impact.report(victim,Vector2.LEFT,Vector2(1000,0),Vector2(950,0))
	check(victim.get_node("Health").current == 80,"high shared velocity with low relative speed causes no damage")
	await ticks(5)
	impact.report(victim,Vector2.LEFT,Vector2(900,0),Vector2.ZERO)
	var remaining: float = victim.get_node("Health").current
	impact.report(victim,Vector2.LEFT,Vector2(900,0),Vector2.ZERO)
	check(remaining == 60 and victim.get_node("Health").current == remaining,"duplicate impact callback does not repeat damage")
	await fresh()
	wall(Vector2(0,500),Vector2(1000,40))
	victim = enemy("melee",Vector2(0,0))
	victim.get_node("Brain").set_physics_process(false)
	var fall_hits: Array[float] = []
	victim.get_node("Health").damaged.connect(func(event: DamageEvent): fall_hits.append(event.amount))
	await ticks(100)
	check(not fall_hits.is_empty() and fall_hits[0] > 20,"hard landing damages enemy")
	await fresh()
	var hazard := Area2D.new()
	hazard.set_script(load("res://scripts/combat/hazard.gd"))
	hazard.collision_mask = 32
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(100,100)
	shape.shape = rectangle
	hazard.add_child(shape)
	world.add_child(hazard)
	victim = enemy("melee",Vector2.ZERO)
	victim.set_physics_process(false)
	victim.get_node("Brain").set_physics_process(false)
	await ticks(5)
	check(victim.get_node("Health").current == 50,"environmental hazard damages overlapping enemy")
	await fresh()
	var launch_floor: StaticBody2D = wall(Vector2(0,300),Vector2(500,40))
	var launch_wall: StaticBody2D = wall(Vector2(500,100),Vector2(40,400))
	system.endpoints[0].configure(Vector2(0,280),Vector2.UP,launch_floor)
	system.endpoints[1].configure(Vector2(480,100),Vector2.LEFT,launch_wall)
	victim = enemy("melee",Vector2(300,100))
	victim.gravity = 0
	victim.get_node("Brain").set_physics_process(false)
	victim.get_node("Health").current = 30
	crate = spawn("res://scenes/entities/crate.tscn",Vector2(0,100)) as RigidBody2D
	crate.linear_velocity = Vector2(0,900)
	await ticks(80)
	check(crate.get_node("PortalTraveller").teleport_count == 1 and not is_instance_valid(victim),"portal-launched crate kills an enemy through impact damage")
	# Redirect an actual ranged-enemy attack after it has been fired.
	await fresh()
	player = spawn("res://scenes/entities/player.tscn",Vector2(300,0)) as PlayerController
	player.set_physics_process(false)
	ranged = enemy("ranged",Vector2.ZERO)
	ranged.gravity = 0
	await ticks(2)
	ranged.get_node("Brain").set_physics_process(false)
	var entry: StaticBody2D = wall(Vector2(200,0),Vector2(40,300))
	var exit_wall: StaticBody2D = wall(Vector2(-200,0),Vector2(40,300))
	system.endpoints[0].configure(Vector2(180,0),Vector2.LEFT,entry)
	system.endpoints[1].configure(Vector2(-180,0),Vector2.RIGHT,exit_wall)
	var transit_count: Array[int] = [0]
	system.transit.connect(func(_body: PortalTraveller,_a:int,_b:int): transit_count[0]+=1)
	await ticks(95)
	check(transit_count[0] > 0 and ranged.get_node("Health").current < 80,"portal redirects enemy projectile back into its shooter")
	world.queue_free()
	await process_frame
	var sandbox: Node = load("res://scenes/sandbox.tscn").instantiate()
	root.add_child(sandbox)
	current_scene = sandbox
	await ticks(10)
	Input.action_press("focus")
	await ticks(3)
	check(is_equal_approx(Engine.time_scale,0.2),"Focus active in combat sandbox")
	var focused_enemy: Node2D = get_nodes_in_group("enemies")[0]
	focused_enemy.global_position = sandbox.player.global_position + Vector2(45,0)
	await ticks(12)
	check(focused_enemy.get_node("Brain").attacks > 0 and sandbox.player.get_node("Health").current < 100,"enemy attacks and player takes damage during Focus")
	sandbox.player.get_node("Health").invulnerability_left = 0.0
	var old_id: int = sandbox.get_instance_id()
	Damage.deliver(sandbox.player,DamageEvent.new(1000))
	check(sandbox.player.dead,"player enters death state")
	Input.action_release("focus")
	await ticks(140)
	check(current_scene.get_instance_id() != old_id and current_scene.player.get_node("Health").current == 100,"death resets room and restores player health")
	check(get_nodes_in_group("enemies").size() == 2 and Engine.time_scale == 1.0,"respawn restores enemies and normal time")
	current_scene.queue_free()
	await process_frame
	print("COMBAT RESULT: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
