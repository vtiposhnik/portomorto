extends Area2D

@export var damage: float = 30.0
@export var interval: float = 0.65
var cooldowns: Dictionary = {}

func _physics_process(delta: float) -> void:
	for key in cooldowns.keys():
		cooldowns[key] -= delta
		if cooldowns[key] <= 0:
			cooldowns.erase(key)
	for body in get_overlapping_bodies():
		var id: int = body.get_instance_id()
		if not cooldowns.has(id):
			Damage.deliver(body,DamageEvent.new(damage,Vector2(0,-180),self))
			cooldowns[id] = interval
