class_name ActivationSwitch
extends StaticBody2D

signal activation_changed(source: Node, active: bool)
@export var damage_activation: bool = true
@export var cooldown: float = 0.3
var active: bool = false
var cooldown_left: float = 0.0

func _ready() -> void:
	add_to_group("interactables")
	$Health.damaged.connect(_damaged)

func _physics_process(delta: float) -> void:
	cooldown_left = maxf(0.0,cooldown_left-delta)

func interact() -> void:
	if cooldown_left > 0:
		return
	cooldown_left = cooldown
	active = not active
	activation_changed.emit(self,active)

func _damaged(_event: DamageEvent) -> void:
	$Health.current = $Health.maximum
	if damage_activation:
		interact()
