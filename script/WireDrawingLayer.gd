extends CanvasLayer

var is_drawing := false
var start_pos := Vector2.ZERO
var current_line: Line2D
var current_wire: Wire
var start_component: BaseComponent

func _ready():
	# Делаем слой прозрачным для кликов
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _input(event):
	# Начинаем рисование только если выбран инструмент "провод"
	if not GameState.current_tool == "wire":
		return
	
	# Проверяем, не над UI ли курсор
	if _is_mouse_over_ui():
		return
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_start_drawing()
		else:
			_finish_drawing()
	
	if event is InputEventMouseMotion and is_drawing:
		_update_drawing()

func _start_drawing():
	is_drawing = true
	start_pos = get_global_mouse_position()
	
	# Проверяем, не начали ли рисовать на компоненте
	start_component = _get_component_at_position(start_pos)
	
	# Создаём временную линию
	current_line = Line2D.new()
	current_line.width = 3
	current_line.default_color = Color.YELLOW
	current_line.add_point(start_pos)
	add_child(current_line)

func _update_drawing():
	var current_pos = get_global_mouse_position()
	current_line.clear_points()
	current_line.add_point(start_pos)
	current_line.add_point(current_pos)

func _finish_drawing():
	if not is_drawing:
		return
	
	var end_pos = get_global_mouse_position()
	var end_component = _get_component_at_position(end_pos)
	
	# Создаём провод только если оба конца на компонентах или один конец на компоненте
	if start_component or end_component:
		_create_wire(start_pos, end_pos, start_component, end_component)
	
	# Удаляем временную линию
	current_line.queue_free()
	current_line = null
	is_drawing = false
	start_component = null

func _create_wire(start: Vector2, end: Vector2, comp1: BaseComponent, comp2: BaseComponent):
	var gameworld = get_tree().current_scene.get_node("GameWorld")
	var wires_container = gameworld.get_node("Wires")
	
	var wire = Wire.new()
	wire.set_points(start, end)
	
	# Соединяем с компонентами
	if comp1:
		wire.connect_to(comp1)
	if comp2:
		wire.connect_to(comp2)
	
	wires_container.add_child(wire)

func _get_component_at_position(pos: Vector2) -> BaseComponent:
	var gameworld = get_tree().current_scene.get_node("GameWorld")
	var objects = gameworld.get_node("Objects")
	
	for child in objects.get_children():
		if child is BaseComponent:
			if child.global_position.distance_to(pos) < 25:
				return child
	
	return null

func _is_mouse_over_ui() -> bool:
	var ui = get_tree().current_scene.get_node_or_null("UI")
	if not ui:
		return false
	
	var mouse_pos = get_viewport().get_mouse_position()
	return _check_ui_children(ui, mouse_pos)

func _check_ui_children(node: Node, mouse_pos: Vector2) -> bool:
	if node is Control:
		var control = node as Control
		if control.visible and control.get_global_rect().has_point(mouse_pos):
			return true
	
	for child in node.get_children():
		if _check_ui_children(child, mouse_pos):
			return true
	
	return false
