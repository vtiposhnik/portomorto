class_name PortalEffect
extends Resource

# Pure transform of a fresh result: position, velocity, and unspent motion.
# Called for clearance prediction and once for committed traversal. Never mutate
# an entity or retain state here. Only resolve() commits the result/signals.
# Ordinary portals have no effect resource. Clearance is checked after effects.
func modify(result: Dictionary) -> Dictionary:
	return result
