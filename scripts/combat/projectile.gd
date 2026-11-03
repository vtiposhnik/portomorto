extends RigidBody2D

@export var damage: float = 25.0
@export var knockback: float = 180.0
@export var lifetime: float = 8.0
var spent: bool = false
var travel_direction: Vector2 = Vector2.RIGHT

func _ready() -> void:
	travel_direction = linear_velocity.normalized()
	body_entered.connect(_hit)

func _physics_process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	$PortalTraveller.integrate(state)
	if state.linear_velocity.length_squared() > 1.0:
		travel_direction = state.linear_velocity.normalized()

func _hit(target: Node) -> void:
	if spent:
		return
	spent = true
	Damage.deliver(target, DamageEvent.new(damage, travel_direction * knockback, self))
	queue_free()
