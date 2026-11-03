class_name EnemyMotor
extends CharacterBody2D

@export var speed: float = 150.0
@export var acceleration: float = 900.0
@export var gravity: float = 1600.0
var direction: float = 0.0
var dead: bool = false

func _ready() -> void:
	add_to_group("enemies")
	$Health.depleted.connect(_die)

func apply_impulse(impulse: Vector2) -> void:
	velocity += impulse

func _die() -> void:
	dead = true
	$Brain.set_physics_process(false)
	queue_free()

func _physics_process(delta: float) -> void:
	if dead:
		return
	velocity.y += gravity * delta
	# Motor acceleration is bounded; portal launches and knockback are never clamped.
	if direction != 0.0 and velocity.x * direction < speed:
		velocity.x = move_toward(velocity.x, direction * speed, acceleration * delta)
	elif direction == 0.0:
		velocity.x = move_toward(velocity.x, 0.0, (250.0 if is_on_floor() else 40.0) * delta)
	var before: Vector2 = global_position
	var incoming: Vector2 = velocity
	move_and_slide()
	$ImpactDamage.character_contacts(self, incoming)
	var result: Dictionary = $PortalTraveller.resolve_motion(before,global_position,velocity)
	if not result.is_empty():
		global_position = result.position
		velocity = result.velocity
		$ImpactDamage.previous_velocity = velocity
	if global_position.y > 2400.0:
		_die()
