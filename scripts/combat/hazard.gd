extends Area2D

@export var damage: float = 30.0
@export var interval: float = 0.65
@export var lethal: bool = false
@export var impulse: Vector2 = Vector2(0,-180)
@export var required_group: StringName = &""
@export var crushing_only: bool = false
var cooldowns: Dictionary = {}

func _physics_process(delta: float) -> void:
	for key in cooldowns.keys():
		cooldowns[key] -= delta
		if cooldowns[key] <= 0:
			cooldowns.erase(key)
	var struck: bool = false
	for body in get_overlapping_bodies():
		if required_group != &"" and not body.is_in_group(required_group):
			continue
		if crushing_only:
			# The underside sensor only damages while its solid parent advances.
			if not get_parent() is MovingPlatform or get_parent().current_velocity.y <= 0.0:
				continue
		var id: int = body.get_instance_id()
		if not cooldowns.has(id):
			Damage.deliver(body,DamageEvent.new(body.get_node("Health").maximum if lethal and body.has_node("Health") else damage,impulse,self))
			cooldowns[id] = interval
			struck = true
	if struck and crushing_only and get_parent() is MovingPlatform:
		get_parent().reverse_motion()
