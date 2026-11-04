class_name DebugHUD
extends CanvasLayer

@export var debug_enabled: bool = true
var player: PlayerController
var system: PortalSystem
var visuals: PortalVisuals
var time_control: TimeControl
var target: StaticBody2D
var effect_controls: PortalEffectControls
var effect_text: Label
var info: Label
var status: Label

func _ready() -> void:
	var panel := ColorRect.new()
	panel.color = Color(0.025, 0.035, 0.06, 0.92)
	panel.size = Vector2(1280, 88)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)
	var title := Label.new()
	title.position = Vector2(24, 12)
	title.text = "PORTOMORTO   /   MECHANICS LAB"
	title.add_theme_font_size_override("font_size", 22)
	add_child(title)
	var controls := Label.new()
	controls.position = Vector2(24, 48)
	controls.text = "A/D  Move     Space  Jump     LMB/RMB  Portals     Shift  Focus     F  Fire     E  Grab/use     R  Reset     F3  Debug"
	add_child(controls)
	effect_text = Label.new()
	effect_text.position = Vector2(24, 96)
	add_child(effect_text)
	info = Label.new()
	info.position = Vector2(24, 134)
	info.add_theme_font_size_override("font_size", 15)
	add_child(info)
	status = Label.new()
	status.position = Vector2(24, 664)
	status.add_theme_font_size_override("font_size", 18)
	add_child(status)

func _process(_delta: float) -> void:
	if effect_controls:
		effect_text.text = effect_controls.description()
	if Input.is_action_just_pressed("debug"):
		debug_enabled = not debug_enabled
	visuals.debug_enabled = debug_enabled
	info.visible = debug_enabled
	var a: PortalEndpoint = system.endpoints[0]
	var b: PortalEndpoint = system.endpoints[1]
	info.text = "FPS %d   |   Physics %d Hz\nPosition %s   Velocity %s\nGrounded %s   Simulation %.2fx\nA: %s normal %s\nB: %s normal %s\nPlayer transits: %d   Target HP: %.0f" % [Engine.get_frames_per_second(), Engine.physics_ticks_per_second, player.position.round(), player.velocity.round(), player.is_on_floor(), Engine.time_scale, "placed" if a.placed else "empty", a.normal, "placed" if b.placed else "empty", b.normal, player.traveller.teleport_count, target.get_node("Health").current]
	for node: Node in get_tree().get_nodes_in_group("portal_travellers"):
		var traveller := node as PortalTraveller
		if traveller.body is RigidBody2D:
			info.text += "\n%s: %s  sleeping=%s  transits=%d" % [traveller.body.name, traveller.get_velocity().round(), traveller.body.sleeping, traveller.teleport_count]
	status.text = "FOCUS  •  20% simulation" if time_control.focused else "Place two portals on slate surfaces. Green preview = valid. Red = blocked."
	status.text += "   |   HP %.0f / %.0f%s" % [player.get_node("Health").current, player.get_node("Health").maximum, "  DEAD — resetting" if player.dead else ""]
	if is_instance_valid(player.get_node("Interaction").held):
		status.text = "CARRYING — LMB throw / E release   |   HP %.0f" % player.get_node("Health").current
	status.modulate = Color("bd86ff") if time_control.focused else Color("93a6b8")
