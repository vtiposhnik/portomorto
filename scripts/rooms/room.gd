class_name PrototypeRoom
extends Node2D

signal exit_reached
signal restart_requested
@export_range(0,2) var room_index: int = 0
@export var death_delay: float = 0.6
var player: PlayerController
var portals: PortalSystem
var placement: PortalPlacement
var effects: PortalEffectControls
var camera: FollowCamera
var time_control: TimeControl
var exit_area: Area2D
var exit_visual: BodyVisual
var exit_unlocked: bool = false
var exit_sent: bool = false
var death_left: float = -1.0
var crate: RigidBody2D
var plate: PressurePlate
var door: MechanismDoor
var enemies_left: int = 0
var objective: String
var heading: Label
var status: Label
var effect_text: Label

func _ready() -> void:
	_build_geometry()
	player = entity("res://scenes/entities/player.tscn",Vector2(120,576)) as PlayerController
	player.died.connect(func(): death_left = death_delay)
	portals = PortalSystem.new()
	add_child(portals)
	placement = PortalPlacement.new()
	placement.system = portals
	placement.aim_origin = player
	add_child(placement)
	effects = PortalEffectControls.new()
	effects.system = portals
	add_child(effects)
	var visuals := PortalVisuals.new()
	visuals.system = portals
	visuals.placement = placement
	visuals.debug_enabled = false
	add_child(visuals)
	time_control = TimeControl.new()
	add_child(time_control)
	camera = FollowCamera.new()
	camera.target = player
	camera.view_zoom = 0.65
	add_child(camera)
	_build_exit()
	_build_hud()

func entity(path: String, point: Vector2) -> Node2D:
	var body: Node2D = load(path).instantiate()
	body.position = point
	add_child(body)
	return body

func wall(point: Vector2, size: Vector2, portal_surface: bool = true) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.position = point
	if portal_surface:
		body.add_to_group("portal_surfaces")
	var collision := CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	var shape := RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	var visual := BodyVisual.new()
	visual.size = size
	visual.color = Color("34495e")
	body.add_child(visual)
	add_child(body)
	return body

func _build_geometry() -> void:
	wall(Vector2(-70,300),Vector2(60,1000))
	wall(Vector2(1330,300),Vector2(60,1000))
	if room_index == 0:
		objective = "Cross the gap: link the near floor to the far wall. Walk into A."
		wall(Vector2(160,650),Vector2(520,100))
		wall(Vector2(1030,650),Vector2(540,100))
		wall(Vector2(140,500),Vector2(160,20))
		wall(Vector2(280,410),Vector2(100,20))
		wall(Vector2(1060,430),Vector2(240,20))
		exit_unlocked = true
		world_text(Vector2(160,660),"A: NEAR FLOOR")
		world_text(Vector2(780,660),"LANDING — optional shortcut: place B near EXIT")
	elif room_index == 1:
		objective = "E carries/releases. Put the crate on the green plate, then jump over it to reach the exit."
		wall(Vector2(600,650),Vector2(1400,100))
		wall(Vector2(600,290),Vector2(1400,40))
		crate = entity("res://scenes/entities/crate.tscn",Vector2(320,582)) as RigidBody2D
		plate = entity("res://scenes/environment/plate.tscn",Vector2(650,591)) as PressurePlate
		plate.minimum_mass = 2.0
		plate.allow_characters = false
		plate.required_group = &"carryable"
		door = entity("res://scenes/environment/door.tscn",Vector2(920,530)) as MechanismDoor
		plate.activation_changed.connect(door.receive_activation)
		plate.activation_changed.connect(func(_source: Node,active: bool): exit_unlocked = active)
		door.receive_activation(plate,false)
		world_text(Vector2(270,660),"E grab/release · Aim with mouse · Carry above the plate, then release")
	else:
		objective = "Defeat both enemies. F fires; portals, crate, barrel and spikes also work."
		wall(Vector2(600,650),Vector2(1400,100))
		wall(Vector2(600,200),Vector2(800,40))
		wall(Vector2(350,490),Vector2(180,20))
		crate = entity("res://scenes/entities/crate.tscn",Vector2(350,582)) as RigidBody2D
		entity("res://scenes/environment/barrel.tscn",Vector2(820,582))
		entity("res://scenes/environment/spikes.tscn",Vector2(930,591))
		for data in [["melee_enemy",Vector2(650,576)],["ranged_enemy",Vector2(1080,576)]]:
			var enemy: EnemyMotor = entity("res://scenes/entities/"+data[0]+".tscn",data[1]) as EnemyMotor
			enemies_left += 1
			enemy.tree_exited.connect(_enemy_removed)
		world_text(Vector2(280,660),"Use the ledge for cover; the barrel and spikes can defeat enemies too")

func _enemy_removed() -> void:
	# Room-local accounting; unloading a whole room cannot unlock another room.
	enemies_left = maxi(0,enemies_left-1)
	exit_unlocked = enemies_left == 0

func _build_exit() -> void:
	exit_area = Area2D.new()
	exit_area.position = Vector2(1200,550)
	exit_area.collision_layer = 0
	exit_area.collision_mask = 2
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(100,100)
	collision.shape = shape
	exit_area.add_child(collision)
	exit_visual = BodyVisual.new()
	exit_visual.size = shape.size
	exit_area.add_child(exit_visual)
	add_child(exit_area)
	world_text(Vector2(1160,475),"EXIT →")

func _physics_process(delta: float) -> void:
	if death_left >= 0:
		death_left -= delta
		if death_left <= 0:
			death_left = -1
			restart_requested.emit()
		return
	if player.global_position.y > 950:
		Damage.deliver(player,DamageEvent.new(player.get_node("Health").maximum))
	if not player.dead and exit_unlocked and not exit_sent and player in exit_area.get_overlapping_bodies():
		exit_sent = true
		exit_reached.emit()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("fire"):
		fire_toward(get_global_mouse_position())

func fire_toward(point: Vector2) -> void:
	if player.dead:
		return
	var direction: Vector2 = (point-player.global_position).normalized()
	var shot: RigidBody2D = ProjectileEmitter.PROJECTILE.instantiate()
	shot.position = player.global_position + direction*30
	shot.linear_velocity = direction*850
	add_child(shot)

func _build_hud() -> void:
	var hud := CanvasLayer.new()
	var background := ColorRect.new()
	background.color = Color(0.025,0.035,0.06,0.92)
	background.size = Vector2(1280,155)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(background)
	heading = Label.new()
	heading.position = Vector2(24,14)
	heading.add_theme_font_size_override("font_size",22)
	hud.add_child(heading)
	var task := Label.new()
	task.position = Vector2(24,47)
	task.text = objective
	hud.add_child(task)
	effect_text = Label.new()
	effect_text.position = Vector2(24,78)
	hud.add_child(effect_text)
	status = Label.new()
	status.position = Vector2(24,113)
	hud.add_child(status)
	add_child(hud)

func _process(_delta: float) -> void:
	heading.text = "ROOM %d / 3 — %s    |    HP %.0f / %.0f" % [room_index+1,["PORTAL TRAVERSAL","PHYSICS PUZZLE","COMBAT ARENA"][room_index],player.get_node("Health").current,player.get_node("Health").maximum]
	if time_control.focused:
		heading.text += "   [FOCUS]"
	effect_text.text = effects.description()
	status.text = "A/D move · Space jump · LMB/RMB portals · E grab/release · F fire · Shift Focus · R restart"
	if is_instance_valid(player.get_node("Interaction").held):
		status.text = "CARRYING: LMB throws · E releases · R restarts room"
	if player.dead:
		status.text = "DEAD — restarting this room…  |  R restarts immediately"
	exit_visual.color = Color(0.2,0.8,0.4,0.45) if exit_unlocked else Color(0.8,0.25,0.2,0.45)

func world_text(point: Vector2, text: String) -> void:
	var label := Label.new()
	label.position = point
	label.text = text
	label.modulate = Color("93a6b8")
	add_child(label)
