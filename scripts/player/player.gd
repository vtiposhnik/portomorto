class_name PlayerController
extends CharacterBody2D

@export var movement: MovementSettings
@onready var traveller: PortalTraveller = $PortalTraveller
var coyote_left: float = 0.0
var jump_left: float = 0.0
var jumped: bool = false

func _ready() -> void:
	if movement == null:
		movement = MovementSettings.new()

func apply_impulse(impulse: Vector2) -> void:
	velocity += impulse

func _physics_process(delta: float) -> void:
	step(delta, Input.get_axis("move_left", "move_right"),
		Input.is_action_just_pressed("jump"), Input.is_action_pressed("jump"))

# Explicit input arguments make the real controller testable without simulated keyboards.
func step(delta: float, axis: float, jump_pressed: bool, jump_held: bool) -> void:
	coyote_left = movement.coyote_time if is_on_floor() else maxf(0.0, coyote_left - delta)
	jump_left = movement.jump_buffer if jump_pressed else maxf(0.0, jump_left - delta)
	if jump_left > 0.0 and coyote_left > 0.0:
		velocity.y = -movement.jump_speed
		jump_left = 0.0
		coyote_left = 0.0
		jumped = true
	if jumped and not jump_held and velocity.y < 0.0:
		velocity.y *= movement.jump_cut
		jumped = false
	if velocity.y >= 0.0:
		jumped = false
	velocity.y += movement.gravity * delta
	if axis != 0.0:
		var target: float = axis * movement.max_speed
		# Accelerate toward running speed, but never clamp a faster portal launch.
		if velocity.x * axis < movement.max_speed:
			velocity.x = move_toward(velocity.x, target, movement.acceleration * (1.0 if is_on_floor() else movement.air_control) * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, (movement.deceleration if is_on_floor() else movement.air_drag) * delta)
	var before: Vector2 = global_position
	move_and_slide()
	var result: Dictionary = traveller.resolve_motion(before, global_position, velocity)
	if not result.is_empty():
		global_position = result.position
		velocity = result.velocity
		coyote_left = 0.0
	for index in get_slide_collision_count():
		var collision: KinematicCollision2D = get_slide_collision(index)
		var body: Object = collision.get_collider()
		if body is RigidBody2D:
			body.apply_central_force(-collision.get_normal() * movement.push_force)
