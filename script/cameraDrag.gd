extends Camera2D

# Настройки
@export var drag_speed := 1.0
@export var inertia := 0.95
@export var min_inertia_velocity := 5.0

# Внутренние переменные
var dragging := false
var drag_start_position := Vector2.ZERO
var camera_start_position := Vector2.ZERO
var drag_velocity := Vector2.ZERO
var last_drag_position := Vector2.ZERO

func _ready():
	if OS.get_name() == "Android" or OS.get_name() == "iOS":
		drag_speed = 1.5

func _input(event):
	# Проверяем, не над UI ли курсор
	if _is_mouse_over_ui():
		return
	
	# Обработка мыши
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_start_drag(event.position)
			else:
				_stop_drag(event.position)
	
	# Обработка касания
	if event is InputEventScreenTouch:
		if event.pressed:
			_start_drag(event.position)
		else:
			_stop_drag(event.position)
	
	# Обработка движения
	if (event is InputEventMouseMotion or event is InputEventScreenDrag) and dragging:
		_update_drag(event.position)

func _start_drag(screen_position: Vector2):
	dragging = true
	drag_start_position = screen_position
	camera_start_position = position
	last_drag_position = screen_position
	drag_velocity = Vector2.ZERO

func _stop_drag(screen_position: Vector2):
	dragging = false
	var current_pos = position
	var time_delta = get_process_delta_time()
	if time_delta > 0:
		drag_velocity = (current_pos - camera_start_position) / time_delta

func _update_drag(current_screen_position: Vector2):
	var drag_offset = (current_screen_position - drag_start_position) * drag_speed
	var new_position = camera_start_position + drag_offset
	position = new_position
	
	var delta = get_process_delta_time()
	if delta > 0:
		drag_velocity = (position - camera_start_position) / delta
	last_drag_position = current_screen_position
	camera_start_position = position
	drag_start_position = current_screen_position

func _process(delta):
	if not dragging and drag_velocity.length() > min_inertia_velocity:
		position += drag_velocity * delta
		drag_velocity *= inertia
		
		if drag_velocity.length() < min_inertia_velocity:
			drag_velocity = Vector2.ZERO

func _is_mouse_over_ui() -> bool:
	var ui_layer = get_tree().current_scene.get_node_or_null("UI")
	if not ui_layer:
		return false
	
	var mouse_pos = get_viewport().get_mouse_position()
	return _check_ui_children(ui_layer, mouse_pos)

func _check_ui_children(node: Node, mouse_pos: Vector2) -> bool:
	if node is Control:
		var control = node as Control
		if control.visible and control.get_global_rect().has_point(mouse_pos):
			return true
	
	for child in node.get_children():
		if _check_ui_children(child, mouse_pos):
			return true
	
	return false
