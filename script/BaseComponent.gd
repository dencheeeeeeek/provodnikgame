extends Node2D
class_name BaseComponent

enum ComponentType {
	BATTERY,
	BULB,
	SWITCH,
	WIRE
}

@export var component_type: ComponentType
@export var is_powered := false
@export var power_value := 0.0

var connections: Array = []

func connect_to(component):
	if component not in connections and component != self:
		connections.append(component)
		component.connections.append(self)
		_update_power()

func get_all_connected_components() -> Array:
	var visited = []
	var stack = [self]
	
	while stack.size() > 0:
		var current = stack.pop_back()
		if current in visited:
			continue
		visited.append(current)
		for conn in current.connections:
			if conn not in visited:
				stack.append(conn)
	
	return visited

func _update_power():
	var circuit = get_all_connected_components()
	var has_power_source = false
	var total_power = 0.0
	
	for component in circuit:
		if component.component_type == ComponentType.BATTERY:
			has_power_source = true
			total_power += component.power_value
	
	for component in circuit:
		component.is_powered = has_power_source and _is_circuit_closed()
		component._on_power_updated()

func _is_circuit_closed() -> bool:
	return true

func _on_power_updated():
	pass
