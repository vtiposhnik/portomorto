class_name BodyVisual
extends Node2D

@export var size: Vector2 = Vector2(32, 48)
@export var color: Color = Color("6de5ca")
@export var circular: bool = false
var flash: float = 0.0

func _ready() -> void:
	var health: HealthComponent = get_parent().get_node_or_null("Health")
	if health:
		health.damaged.connect(func(_event: DamageEvent): flash = 0.15)

func _process(delta: float) -> void:
	flash = maxf(0.0, flash - TimeControl.real_delta(delta))
	queue_redraw()

func _draw() -> void:
	var tint: Color = Color.WHITE if flash > 0 else color
	if circular:
		draw_circle(Vector2.ZERO, size.x * 0.5, tint)
	else:
		draw_rect(Rect2(-size * 0.5, size), tint)
		draw_rect(Rect2(-size * 0.5, size), tint.lightened(0.4), false, 2.0)
