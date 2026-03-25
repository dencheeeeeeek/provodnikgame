extends BaseComponent

var line: Line2D
var start_point: Node2D
var end_point: Node2D
var is_drawing := false

func _ready():
	component_type = ComponentType.WIRE
	_setup_visual()

func _setup_visual():
	line = Line2D.new()
	line.width = 3
	line.default_color = Color.YELLOW
	add_child(line)

func set_points(start: Vector2, end: Vector2):
	line.clear_points()
	line.add_point(start)
	line.add_point(end)
	
	# Обновляем позицию провода
	position = (start + end) / 2
	
	# Обновляем точки соединения
	_update_connection_points(start, end)

func _update_connection_points(start: Vector2, end: Vector2):
	# Проверяем, какие компоненты находятся в точках соединения
	var gameworld = get_tree().current_scene.get_node("GameWorld")
	var components = gameworld.get_node("Objects").get_children()
	
	for component in components:
		if component is BaseComponent:
			if component.global_position.distance_to(start) < 20:
				connect_to(component)
			if component.global_position.distance_to(end) < 20:
				connect_to(component)
