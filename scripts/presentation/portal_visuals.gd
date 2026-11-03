class_name PortalVisuals
extends Node2D

var system: PortalSystem
var placement: PortalPlacement
var debug_enabled: bool = true
var pulse: float = 0.0
var colors: Array[Color] = [Color("54ccff"), Color("bd86ff")]

func _ready() -> void:
	system.transit.connect(func(_who: PortalTraveller, _a: int, _b: int): pulse = 0.2)

func _process(delta: float) -> void:
	pulse = maxf(0.0, pulse - TimeControl.real_delta(delta))
	queue_redraw()

func aperture(center: Vector2, normal: Vector2, half: float, color: Color) -> void:
	var tangent: Vector2 = PortalMath.tangent(normal)
	for thickness in [18.0, 10.0, 4.0]:
		var tint := Color(color, 0.1 if thickness > 4 else 1.0)
		draw_line(center - tangent * half, center + tangent * half, tint, thickness)
	if debug_enabled:
		draw_line(center, center + normal * 36.0, color, 2.0)
		draw_circle(center + normal * 36.0, 3.0, color)

func _draw() -> void:
	for index in 2:
		var portal: PortalEndpoint = system.endpoints[index]
		if portal.placed:
			var color: Color = colors[index] if system.linked() else colors[index].darkened(0.5)
			aperture(portal.center, portal.normal, portal.half_length, Color.WHITE if pulse > 0 else color)
	if not placement.preview.is_empty():
		var preview: Dictionary = placement.preview
		aperture(preview.position, preview.normal, system.endpoints[0].half_length, Color("89f3b2") if preview.valid else Color("fa5966"))
	if debug_enabled:
		for node: Node in get_tree().get_nodes_in_group("portal_travellers"):
			var traveller := node as PortalTraveller
			draw_line(traveller.body.global_position, traveller.body.global_position + traveller.get_velocity() * 0.12, Color("efca6c"), 2.0)
