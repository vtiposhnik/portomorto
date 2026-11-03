class_name PortalEffect
extends Resource

# Override this one operation in a Resource to alter a computed result later.
# Ordinary portals have no effect resource. Clearance is checked after effects.
func modify(result: Dictionary) -> Dictionary:
	return result
