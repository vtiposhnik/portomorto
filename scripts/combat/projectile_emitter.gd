class_name ProjectileEmitter
extends Node2D

const PROJECTILE = preload("res://scenes/entities/projectile.tscn")
@export var world_scale: float = 1.0
@export var speed: float = 700.0
@export var interval: float = 2.5
@export var automatic: bool = true
var elapsed: float = 0.0

func _physics_process(delta: float) -> void:
	if not automatic:
		return
	elapsed += delta
	if elapsed >= interval:
		elapsed = 0.0
		fire(Vector2.RIGHT.rotated(global_rotation))

func fire(direction: Vector2) -> RigidBody2D:
	var projectile: RigidBody2D = PROJECTILE.instantiate()
	projectile.position = global_position + direction * 20.0 * world_scale
	projectile.linear_velocity = direction.normalized() * speed
	WorldUnits.resize_body(projectile, world_scale)
	get_parent().add_child(projectile)
	return projectile
