extends RigidBody2D

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	$ImpactDamage.rigid_contacts(state)
	$PortalTraveller.integrate(state)
	$ImpactDamage.previous_velocity = state.linear_velocity
