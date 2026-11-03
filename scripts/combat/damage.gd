class_name Damage
extends RefCounted

static func deliver(target: Node, event: DamageEvent) -> bool:
	var health: HealthComponent = target.get_node_or_null("Health")
	if health == null:
		return false
	health.receive(event)
	return true
