extends Node2D

const PLAYER = preload("res://scenes/entities/player.tscn")
const CRATE = preload("res://scenes/entities/crate.tscn")
const TARGET = preload("res://scenes/entities/target.tscn")
var player: PlayerController

@export_range(0.5, 2.0) var world_scale: float = 1.0
@export var camera_zoom: float = 0.8
@export var debug_enabled: bool = true
var emitter: ProjectileEmitter
var time_control: TimeControl
var respawn_left: float = -1.0
@export var respawn_delay: float = 0.8

func _ready() -> void:
	wall(Vector2(1450, 650), Vector2(3900, 100))
	wall(Vector2(-450, 250), Vector2(100, 800))
	wall(Vector2(3400, 0), Vector2(100, 1400))
	wall(Vector2(650, 400), Vector2(340, 36))
	wall(Vector2(1120, 200), Vector2(320, 36))
	wall(Vector2(700, -100), Vector2(700, 50))
	wall(Vector2(1450, 430), Vector2(50, 340))
	wall(Vector2(120, 280), Vector2(220, 36), -0.3)
	# Open runway and vertical launch shaft beyond the original combat room.
	wall(Vector2(2700,-650),Vector2(1100,50))
	wall(Vector2(2200,100),Vector2(260,36),0.35)
	player = PLAYER.instantiate()
	player.position = Vector2(150, 540) * world_scale
	WorldUnits.resize_body(player, world_scale)
	add_child(player)
	player.died.connect(func(): respawn_left = respawn_delay)
	for property: String in ["max_speed", "acceleration", "deceleration", "air_drag", "gravity", "jump_speed", "push_force"]:
		player.movement.set(property, player.movement.get(property) * world_scale)
	var crate: RigidBody2D = CRATE.instantiate()
	crate.position = Vector2(360, 540) * world_scale
	WorldUnits.resize_body(crate, world_scale)
	add_child(crate)
	for entry in [["melee_enemy", Vector2(850,540)], ["ranged_enemy", Vector2(1320,540)]]:
		var enemy: EnemyMotor = load("res://scenes/entities/"+entry[0]+".tscn").instantiate()
		enemy.position = entry[1] * world_scale
		WorldUnits.resize_body(enemy,world_scale)
		enemy.speed *= world_scale
		enemy.gravity *= world_scale
		add_child(enemy)
	var extra: RigidBody2D = CRATE.instantiate()
	extra.position = Vector2(1100,100)*world_scale
	WorldUnits.resize_body(extra,world_scale)
	add_child(extra)
	var hazard := Area2D.new()
	hazard.set_script(preload("res://scripts/combat/hazard.gd"))
	hazard.position = Vector2(1000,590)*world_scale
	hazard.collision_layer = 0
	hazard.collision_mask = 38
	var hazard_shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(130,20)*world_scale
	hazard_shape.shape = rectangle
	hazard.add_child(hazard_shape)
	var hazard_visual := BodyVisual.new()
	hazard_visual.size = rectangle.size
	hazard_visual.color = Color("e53535")
	hazard.add_child(hazard_visual)
	add_child(hazard)
	var target: StaticBody2D = TARGET.instantiate()
	target.position = Vector2(1700, 564) * world_scale
	WorldUnits.resize_body(target, world_scale)
	add_child(target)
	var system := PortalSystem.new()
	system.exit_margin *= world_scale
	for endpoint: PortalEndpoint in system.endpoints:
		endpoint.half_length *= world_scale
	system.set_meta("world_scale",world_scale)
	add_child(system)
	var effect_controls := PortalEffectControls.new()
	effect_controls.system = system
	add_child(effect_controls)
	var placement := PortalPlacement.new()
	placement.range_limit *= world_scale
	placement.edge_margin *= world_scale
	placement.system = system
	placement.aim_origin = player
	add_child(placement)
	var visuals := PortalVisuals.new()
	visuals.system = system
	visuals.placement = placement
	add_child(visuals)
	time_control = TimeControl.new()
	add_child(time_control)
	var camera := FollowCamera.new()
	camera.target = player
	camera.view_zoom = camera_zoom / world_scale
	add_child(camera)
	emitter = ProjectileEmitter.new()
	emitter.position = Vector2(1510, 560) * world_scale
	emitter.world_scale = world_scale
	emitter.speed *= world_scale
	add_child(emitter)
	var emitter_visual := BodyVisual.new()
	emitter_visual.size = Vector2(26, 26) * world_scale
	emitter_visual.color = Color("efca6c")
	emitter.add_child(emitter_visual)
	var hud := DebugHUD.new()
	hud.effect_controls = effect_controls
	hud.player = player
	hud.system = system
	hud.visuals = visuals
	hud.time_control = time_control
	hud.target = target
	hud.debug_enabled = debug_enabled
	add_child(hud)
	var lab_crate: RigidBody2D = CRATE.instantiate()
	lab_crate.position = Vector2(2400,560)*world_scale
	WorldUnits.resize_body(lab_crate,world_scale)
	add_child(lab_crate)
	var lab_target: StaticBody2D = TARGET.instantiate()
	lab_target.position = Vector2(3200,564)*world_scale
	WorldUnits.resize_body(lab_target,world_scale)
	add_child(lab_target)
	var lab_emitter := ProjectileEmitter.new()
	lab_emitter.position = Vector2(2500,450)*world_scale
	lab_emitter.world_scale = world_scale
	lab_emitter.speed *= world_scale
	add_child(lab_emitter)
	label_at(Vector2(2400,660),"ACCELERATION RUNWAY / VERTICAL LAUNCH SHAFT")
	label_at(Vector2(-80, 660), "MOMENTUM RUNWAY")
	label_at(Vector2(480, 430), "FLOOR / CEILING TRANSFER")
	label_at(Vector2(1490, 660), "PROJECTILE / DAMAGE RANGE")
	label_at(Vector2(-5, 190), "ROTATED SURFACE")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("reset"):
		get_tree().reload_current_scene()
	if event.is_action_pressed("fire") and not player.dead:
		var direction: Vector2 = (get_global_mouse_position() - player.global_position).normalized()
		var projectile: RigidBody2D = ProjectileEmitter.PROJECTILE.instantiate()
		projectile.position = player.global_position + direction * 30.0 * world_scale
		projectile.linear_velocity = direction * 850.0 * world_scale
		WorldUnits.resize_body(projectile, world_scale)
		add_child(projectile)

func _physics_process(delta: float) -> void:
	if respawn_left >= 0.0:
		respawn_left -= delta
		if respawn_left <= 0.0:
			get_tree().reload_current_scene()
			return
	if player.position.y > 1400.0 * world_scale:
		get_tree().reload_current_scene()

func label_at(point: Vector2, text: String) -> void:
	var label := Label.new()
	label.position = point * world_scale
	label.text = text
	label.modulate = Color("8194a6")
	add_child(label)

func wall(center: Vector2, size: Vector2, angle: float = 0.0) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.position = center * world_scale
	body.rotation = angle
	body.add_to_group("portal_surfaces")
	var collision := CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	var shape := RectangleShape2D.new()
	shape.size = size * world_scale
	collision.shape = shape
	body.add_child(collision)
	var visual := BodyVisual.new()
	visual.size = size * world_scale
	visual.color = Color("34495e")
	body.add_child(visual)
	add_child(body)
	return body
