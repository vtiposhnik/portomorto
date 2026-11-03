class_name EnemyBrain
extends Node

enum Style { MELEE, RANGED }
enum State { IDLE, APPROACH, ATTACK }
@export var style: Style = Style.MELEE
@export var detection_range: float = 650.0
@export var attack_range: float = 58.0
@export var attack_interval: float = 0.9
@export var damage: float = 18.0
@export var knockback: float = 220.0
@export var projectile_speed: float = 650.0
var state: State = State.IDLE
var cooldown: float = 0.0
var attacks: int = 0
@onready var motor: EnemyMotor = get_parent()

func _physics_process(delta: float) -> void:
	cooldown = maxf(0.0, cooldown - delta)
	var target: Node2D = get_tree().get_first_node_in_group("player")
	motor.direction = 0.0
	if not is_instance_valid(target) or target.get_node("Health").current <= 0:
		state = State.IDLE
		return
	var offset: Vector2 = target.global_position - motor.global_position
	if offset.length() > detection_range:
		state = State.IDLE
		return
	if offset.length() > attack_range:
		state = State.APPROACH
		motor.direction = signf(offset.x)
		return
	state = State.ATTACK
	if cooldown > 0.0 or not line_of_sight(target):
		return
	cooldown = attack_interval
	attacks += 1
	if style == Style.MELEE:
		Damage.deliver(target, DamageEvent.new(damage, offset.normalized()*knockback + Vector2.UP*80, motor))
	else:
		var shot: RigidBody2D = ProjectileEmitter.PROJECTILE.instantiate()
		var scale: float = motor.get_meta("world_scale",1.0)
		WorldUnits.resize_body(shot,scale)
		shot.position = motor.global_position + offset.normalized()*30*scale
		shot.linear_velocity = offset.normalized()*projectile_speed
		shot.damage = damage
		shot.collision_mask = 55 # world, player, crates, targets and enemies
		shot.shooter = motor
		motor.get_parent().add_child(shot)
		shot.add_collision_exception_with(motor)

func line_of_sight(target: Node2D) -> bool:
	var ray := PhysicsRayQueryParameters2D.create(motor.global_position,target.global_position,1)
	return motor.get_world_2d().direct_space_state.intersect_ray(ray).is_empty()
