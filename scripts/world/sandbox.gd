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

func _ready() -> void:
	wall(Vector2(700, 650), Vector2(2400, 100))
	wall(Vector2(-450, 250), Vector2(100, 800))
	wall(Vector2(1850, 200), Vector2(100, 900))
	wall(Vector2(650, 400), Vector2(340, 36))
	wall(Vector2(1120, 200), Vector2(320, 36))
	wall(Vector2(700, -100), Vector2(700, 50))
	wall(Vector2(1450, 430), Vector2(50, 340))
	wall(Vector2(120, 280), Vector2(220, 36), -0.3)
	player = PLAYER.instantiate()
	player.position = Vector2(150, 540) * world_scale
	WorldUnits.resize_body(player, world_scale)
	add_child(player)
	for property: String in ["max_speed", "acceleration", "deceleration", "air_drag", "gravity", "jump_speed", "push_force"]:
		player.movement.set(property, player.movement.get(property) * world_scale)
	var crate: RigidBody2D = CRATE.instantiate()
	crate.position = Vector2(360, 540) * world_scale
	WorldUnits.resize_body(crate, world_scale)
	add_child(crate)
	var target: StaticBody2D = TARGET.instantiate()
	target.position = Vector2(1700, 564) * world_scale
	WorldUnits.resize_body(target, world_scale)
	add_child(target)
	var system := PortalSystem.new()
	system.exit_margin *= world_scale
	for endpoint: PortalEndpoint in system.endpoints:
		endpoint.half_length *= world_scale
	add_child(system)
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
	hud.player = player
	hud.system = system
	hud.visuals = visuals
	hud.time_control = time_control
	hud.target = target
	hud.debug_enabled = debug_enabled
	add_child(hud)
	label_at(Vector2(-80, 660), "MOMENTUM RUNWAY")
	label_at(Vector2(480, 430), "FLOOR / CEILING TRANSFER")
	label_at(Vector2(1490, 660), "PROJECTILE / DAMAGE RANGE")
	label_at(Vector2(-5, 190), "ROTATED SURFACE")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("reset"):
		get_tree().reload_current_scene()
	if event.is_action_pressed("fire"):
		var direction: Vector2 = (get_global_mouse_position() - player.global_position).normalized()
		var projectile: RigidBody2D = ProjectileEmitter.PROJECTILE.instantiate()
		projectile.position = player.global_position + direction * 30.0 * world_scale
		projectile.linear_velocity = direction * 850.0 * world_scale
		WorldUnits.resize_body(projectile, world_scale)
		add_child(projectile)

func _physics_process(_delta: float) -> void:
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
