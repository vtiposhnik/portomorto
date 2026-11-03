class_name ImpactDamage
extends Node

@export var threshold: float = 700.0
@export var damage_per_speed: float = 0.10
@export var maximum_damage: float = 100.0
# One shared contact ledger prevents both participants reporting the same impact.
# A pair rearms only after separation (no contact reports for three physics ticks).
static var contacts: Dictionary = {}
var previous_velocity: Vector2 = Vector2.ZERO

func report(other: Node, normal: Vector2, own_velocity: Vector2, other_velocity: Vector2) -> void:
	if not is_instance_valid(other) or other.collision_layer & 8:
		return
	var body: Node = get_parent()
	var a: int = body.get_instance_id()
	var b: int = other.get_instance_id()
	var pair: String = "%d:%d" % [mini(a,b),maxi(a,b)]
	var frame: int = Engine.get_physics_frames()
	var previous: int = contacts.get(pair, -100)
	contacts[pair] = frame
	if frame - previous <= 3:
		return
	var closing: float = maxf(0.0, -(own_velocity - other_velocity).dot(normal))
	if closing <= threshold:
		return
	var amount: float = minf(maximum_damage, (closing - threshold) * damage_per_speed)
	# Contact resolution already supplies the physical impulse; do not add it twice.
	Damage.deliver(body, DamageEvent.new(amount, Vector2.ZERO, other))
	Damage.deliver(other, DamageEvent.new(amount, Vector2.ZERO, body))
	if contacts.size() > 256:
		for key in contacts.keys():
			if frame - contacts[key] > 300:
				contacts.erase(key)

func character_contacts(body: CharacterBody2D, incoming: Vector2) -> void:
	for index in body.get_slide_collision_count():
		var hit: KinematicCollision2D = body.get_slide_collision(index)
		report(hit.get_collider(), hit.get_normal(), incoming, hit.get_collider_velocity())
	previous_velocity = body.velocity

func rigid_contacts(state: PhysicsDirectBodyState2D) -> void:
	for index in state.get_contact_count():
		var other: Object = state.get_contact_collider_object(index)
		if other is Node:
			var other_velocity: Vector2 = state.get_contact_collider_velocity_at_position(index)
			var component: ImpactDamage = other.get_node_or_null("ImpactDamage")
			if component:
				other_velocity = component.previous_velocity
			report(other, state.transform.basis_xform(state.get_contact_local_normal(index)), previous_velocity, other_velocity)
	previous_velocity = state.linear_velocity
