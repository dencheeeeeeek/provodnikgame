extends Node2D

# === Узлы ===
@onready var camera = $Camera2D if has_node("Camera2D") else null
@onready var tools_panel = $ToolsPanel if has_node("ToolsPanel") else null
@onready var components_container = $ToolsPanel/ComponentsContainer if has_node("ToolsPanel/ComponentsContainer") else null
@onready var clear_button = $ToolsPanel/ClearButton if has_node("ToolsPanel/ClearButton") else null
@onready var zoom_in_button = $ToolsPanel/ZoomIn if has_node("ToolsPanel/ZoomIn") else null
@onready var zoom_out_button = $ToolsPanel/ZoomOut if has_node("ToolsPanel/ZoomOut") else null
@onready var reset_view_button = $ToolsPanel/ResetView if has_node("ToolsPanel/ResetView") else null

# === Загрузка компонентов ===
var battery_scene = preload("res://components/Battery.tscn")
var bulb_scene = preload("res://components/Bulb.tscn")
var switch_scene = preload("res://components/Switch.tscn")
var resistor_scene = preload("res://components/Resistor.tscn")

# === Переменные ===
var current_tool = null
var is_dragging = false
var is_panning = false
var drag_start = Vector2()
var camera_drag_start = Vector2()
var selected_component = null
var components = []
var wires = []
var zoom_level = 1.0
var min_zoom = 0.5
var max_zoom = 2.0

# === Переменные для проводов ===
var wire_mode_active = false
var first_wire_component = null
var temp_wire = null

# === Словарь типов компонентов ===
var component_types = {
	"battery": {"scene": battery_scene, "name": "Батарейка", "icon": "🔋"},
	"bulb": {"scene": bulb_scene, "name": "Лампочка", "icon": "💡"},
	"switch": {"scene": switch_scene, "name": "Выключатель", "icon": "🔘"},
	"resistor": {"scene": resistor_scene, "name": "Резистор", "icon": "📏"}
}

func _ready():
	setup_ui()
	create_tool_buttons()
	
	if not camera:
		camera = Camera2D.new()
		camera.name = "Camera2D"
		add_child(camera)

func setup_ui():
	if camera:
		camera.zoom = Vector2(zoom_level, zoom_level)
		camera.position_smoothing_enabled = true
		camera.position_smoothing_speed = 5.0
	
	if clear_button:
		clear_button.pressed.connect(clear_all)
	
	if zoom_in_button:
		zoom_in_button.pressed.connect(_zoom_in)
	
	if zoom_out_button:
		zoom_out_button.pressed.connect(_zoom_out)
	
	if reset_view_button:
		reset_view_button.pressed.connect(_reset_view)

func create_tool_buttons():
	if not components_container:
		if not tools_panel:
			tools_panel = Panel.new()
			tools_panel.name = "ToolsPanel"
			tools_panel.position = Vector2(10, 10)
			tools_panel.size = Vector2(200, 400)
			add_child(tools_panel)
		
		components_container = VBoxContainer.new()
		components_container.name = "ComponentsContainer"
		components_container.position = Vector2(5, 5)
		tools_panel.add_child(components_container)
		
		clear_button = Button.new()
		clear_button.name = "ClearButton"
		clear_button.text = "Очистить всё"
		clear_button.position = Vector2(5, 350)
		clear_button.size = Vector2(190, 40)
		tools_panel.add_child(clear_button)
		clear_button.pressed.connect(clear_all)
		
		zoom_in_button = Button.new()
		zoom_in_button.name = "ZoomIn"
		zoom_in_button.text = "+ Приблизить"
		zoom_in_button.position = Vector2(5, 395)
		zoom_in_button.size = Vector2(190, 40)
		tools_panel.add_child(zoom_in_button)
		zoom_in_button.pressed.connect(_zoom_in)
		
		zoom_out_button = Button.new()
		zoom_out_button.name = "ZoomOut"
		zoom_out_button.text = "- Отдалить"
		zoom_out_button.position = Vector2(5, 440)
		zoom_out_button.size = Vector2(190, 40)
		tools_panel.add_child(zoom_out_button)
		zoom_out_button.pressed.connect(_zoom_out)
		
		reset_view_button = Button.new()
		reset_view_button.name = "ResetView"
		reset_view_button.text = "Сбросить вид"
		reset_view_button.position = Vector2(5, 485)
		reset_view_button.size = Vector2(190, 40)
		tools_panel.add_child(reset_view_button)
		reset_view_button.pressed.connect(_reset_view)
	
	for child in components_container.get_children():
		child.queue_free()
	
	# Кнопка режима проводов
	var wire_button = Button.new()
	wire_button.text = "🔌 Режим проводов"
	wire_button.custom_minimum_size = Vector2(140, 50)
	wire_button.add_theme_font_size_override("font_size", 16)
	wire_button.pressed.connect(_activate_wire_mode)
	components_container.add_child(wire_button)
	
	var separator = HSeparator.new()
	separator.custom_minimum_size = Vector2(140, 10)
	components_container.add_child(separator)
	
	for tool_key in component_types:
		var tool_data = component_types[tool_key]
		var button = Button.new()
		button.text = tool_data["icon"] + " " + tool_data["name"]
		button.custom_minimum_size = Vector2(140, 50)
		button.add_theme_font_size_override("font_size", 16)
		button.pressed.connect(_select_tool.bind(tool_key))
		components_container.add_child(button)

func _activate_wire_mode():
	_clear_selection()
	wire_mode_active = true
	first_wire_component = null
	print("🎯 Режим проводов активирован. Нажми на компонент, чтобы начать провод.")

func _select_tool(tool_type):
	current_tool = tool_type
	wire_mode_active = false
	first_wire_component = null
	_remove_temp_wire()
	_clear_selection()
	print("✅ Выбран инструмент: ", tool_type)

func _clear_selection():
	if selected_component:
		if selected_component.has_method("deselect"):
			selected_component.deselect()
		selected_component = null

func _remove_temp_wire():
	if temp_wire:
		temp_wire.queue_free()
		temp_wire = null

func _input(event):
	# Обработка мыши для временного провода
	if wire_mode_active and first_wire_component and event is InputEventMouseMotion:
		_update_temp_wire()
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_on_press(event.position)
			else:
				_on_release(event.position)
		
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and not OS.has_feature("mobile"):
			_zoom(0.1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and not OS.has_feature("mobile"):
			_zoom(-0.1)
	
	elif event is InputEventMouseMotion:
		if is_dragging and selected_component:
			var new_pos = get_global_mouse_position()
			selected_component.global_position = new_pos
			_update_all_wires()
		elif is_panning and camera:
			camera.position -= event.relative / camera.zoom

func _update_temp_wire():
	if not temp_wire:
		temp_wire = Line2D.new()
		temp_wire.width = 4
		temp_wire.default_color = Color(1, 1, 0, 0.8)
		temp_wire.antialiased = true
		add_child(temp_wire)
	
	temp_wire.clear_points()
	
	if first_wire_component and first_wire_component.has_method("get_connection_point"):
		temp_wire.add_point(first_wire_component.get_connection_point())
	else:
		temp_wire.add_point(get_global_mouse_position())
	
	temp_wire.add_point(get_global_mouse_position())

func _on_press(screen_position):
	var mouse_pos = get_global_mouse_position()
	var clicked_component = get_component_at_position(mouse_pos)
	
	# === РЕЖИМ ПРОВОДОВ ===
	if wire_mode_active:
		if clicked_component:
			if not first_wire_component:
				# Первый клик - выбираем начальный компонент
				first_wire_component = clicked_component
				if first_wire_component.has_method("set_selected_for_wire"):
					first_wire_component.set_selected_for_wire(true)
				print("📌 Выбран первый компонент для провода")
			else:
				# Второй клик - создаём провод
				if first_wire_component != clicked_component:
					create_wire(first_wire_component, clicked_component)
				else:
					print("⚠️ Нельзя соединить компонент сам с собой")
				# Выходим из режима проводов
				_deactivate_wire_mode()
		else:
			# Клик на пустое место - отмена
			_deactivate_wire_mode()
		return
	
	# === РЕЖИМ ПЕРЕМЕЩЕНИЯ И СОЗДАНИЯ ===
	if clicked_component:
		# Выделяем компонент для перемещения
		if selected_component and selected_component != clicked_component:
			if selected_component.has_method("deselect"):
				selected_component.deselect()
		
		selected_component = clicked_component
		if selected_component.has_method("select"):
			selected_component.select()
		
		is_dragging = true
		drag_start = mouse_pos
		current_tool = null
	elif current_tool:
		# Создаём новый компонент
		create_component(current_tool, mouse_pos)
		current_tool = null
	else:
		# Перемещение камеры
		is_panning = true
		if camera:
			camera_drag_start = camera.position
		_clear_selection()

func _deactivate_wire_mode():
	if first_wire_component and first_wire_component.has_method("set_selected_for_wire"):
		first_wire_component.set_selected_for_wire(false)
	first_wire_component = null
	wire_mode_active = false
	_remove_temp_wire()
	print("🔌 Режим проводов деактивирован")

func _on_release(screen_position):
	is_dragging = false
	is_panning = false

func create_component(component_type, position):
	var tool_data = component_types.get(component_type)
	if not tool_data or not tool_data["scene"]:
		print("❌ Ошибка: не найден компонент типа ", component_type)
		return
	
	var component = tool_data["scene"].instantiate()
	component.global_position = position
	component.component_id = components.size()
	
	if component.has_signal("clicked"):
		component.clicked.connect(_on_component_clicked)
	
	add_child(component)
	components.append(component)
	
	update_simulation()
	print("✅ Создан компонент: ", component_type)

func _on_component_clicked(component):
	# Если в режиме проводов - не обрабатываем обычный клик
	if wire_mode_active:
		return
	
	if selected_component and selected_component != component:
		if selected_component.has_method("deselect"):
			selected_component.deselect()
	
	selected_component = component
	if selected_component.has_method("select"):
		selected_component.select()
	
	current_tool = null

func create_wire(comp1, comp2):
	# Проверка на существование провода
	for wire in wires:
		if (wire.from == comp1 and wire.to == comp2) or (wire.from == comp2 and wire.to == comp1):
			print("⚠️ Провод уже существует между этими компонентами")
			return
	
	var wire = {
		"from": comp1,
		"to": comp2,
		"line": null
	}
	
	# Создаём линию
	var line = Line2D.new()
	line.width = 4
	line.default_color = Color(1, 0.8, 0.2, 1)
	line.antialiased = true
	
	if comp1.has_method("get_connection_point") and comp2.has_method("get_connection_point"):
		line.add_point(comp1.get_connection_point())
		line.add_point(comp2.get_connection_point())
	
	add_child(line)
	wire.line = line
	wires.append(wire)
	
	# Сохраняем связи в компонентах
	if not comp1.has_meta("connected_to"):
		comp1.set_meta("connected_to", [])
	if not comp2.has_meta("connected_to"):
		comp2.set_meta("connected_to", [])
	
	comp1.get_meta("connected_to").append(comp2)
	comp2.get_meta("connected_to").append(comp1)
	
	print("🔗 Создан провод между компонентами")
	update_simulation()

func _update_all_wires():
	for wire in wires:
		if wire.from and wire.to:
			if wire.line:
				wire.line.clear_points()
				if wire.from.has_method("get_connection_point") and wire.to.has_method("get_connection_point"):
					wire.line.add_point(wire.from.get_connection_point())
					wire.line.add_point(wire.to.get_connection_point())
	
	update_simulation()

func get_component_at_position(pos):
	for i in range(components.size() - 1, -1, -1):
		var component = components[i]
		if component.has_method("get_rect"):
			var rect = component.get_rect()
			var component_pos = component.global_position
			if rect.has_point(pos - component_pos + rect.position):
				return component
	return null

# === ФИЗИКА ЭЛЕКТРИЧЕСТВА ===
func update_simulation():
	# Сначала сбрасываем ток у всех компонентов
	for component in components:
		component.set_meta("current", 0.0)
	
	# Находим все замкнутые цепи
	var circuits = find_closed_circuits()
	
	if circuits.is_empty():
		print("🔴 Нет замкнутых цепей")
		for component in components:
			if component.has_method("update_state"):
				component.update_state(0.0)
		return
	
	# Для каждой замкнутой цепи рассчитываем ток
	for circuit in circuits:
		calculate_circuit_parameters(circuit)
	
	print("🟢 Найдено замкнутых цепей: ", circuits.size())

func find_closed_circuits() -> Array:
	var circuits = []
	var visited_components = []
	
	for component in components:
		if component not in visited_components:
			# Ищем цепь через поиск в глубину
			var circuit = []
			var stack = [component]
			var component_to_parent = {}  # Для отслеживания пути
			
			while stack:
				var current = stack.pop_back()
				if current in visited_components:
					continue
				
				visited_components.append(current)
				circuit.append(current)
				
				if current.has_meta("connected_to"):
					for connected in current.get_meta("connected_to"):
						if connected not in visited_components:
							stack.append(connected)
							component_to_parent[connected] = current
			
			# Проверяем, замкнута ли цепь
			if circuit.size() >= 2:
				# Ищем циклы в цепи
				var has_cycle = check_for_cycle(circuit, component_to_parent)
				if has_cycle:
					circuits.append(circuit)
	
	return circuits

func check_for_cycle(circuit: Array, parent_map: Dictionary) -> bool:
	# Простая проверка: если в цепи больше 1 компонента и есть соединения
	if circuit.size() < 2:
		return false
	
	# Проверяем, есть ли у первого и последнего компонента связь
	var first = circuit[0]
	var last = circuit[circuit.size() - 1]
	
	if first.has_meta("connected_to") and last.has_meta("connected_to"):
		if last in first.get_meta("connected_to") or first in last.get_meta("connected_to"):
			return true
	
	# Дополнительная проверка на циклы
	var visited = []
	var stack = [circuit[0]]
	
	while stack:
		var current = stack.pop_back()
		if current in visited:
			continue
		visited.append(current)
		
		if current.has_meta("connected_to"):
			for connected in current.get_meta("connected_to"):
				if connected in visited and connected != parent_map.get(current):
					return true
				if connected not in visited:
					stack.append(connected)
	
	return false

func calculate_circuit_parameters(circuit: Array):
	var total_voltage = 0.0
	var total_resistance = 0.0
	
	# Суммируем все напряжения и сопротивления
	for component in circuit:
		if component.has_method("get_voltage"):
			total_voltage += component.get_voltage()
		if component.has_method("get_resistance"):
			total_resistance += component.get_resistance()
		
		# Проверяем выключатели
		if component.has_method("is_switch_on"):
			if not component.is_switch_on():
				# Если выключатель разомкнут - цепь не замкнута
				for comp in circuit:
					comp.set_meta("current", 0.0)
					if comp.has_method("update_state"):
						comp.update_state(0.0)
				return
	
	# Рассчитываем ток по закону Ома
	var current = 0.0
	if total_resistance > 0:
		current = total_voltage / total_resistance
		current = clamp(current, 0.0, 10.0)  # Ограничиваем максимальный ток
	
	print("📊 Цепь: V=", total_voltage, "V, R=", total_resistance, "Ω, I=", current, "A")
	
	# Применяем ток ко всем компонентам цепи
	for component in circuit:
		component.set_meta("current", current)
		if component.has_method("update_state"):
			component.update_state(current)

func clear_all():
	for component in components:
		if is_instance_valid(component):
			component.queue_free()
	
	for wire in wires:
		if wire.line and is_instance_valid(wire.line):
			wire.line.queue_free()
	
	components.clear()
	wires.clear()
	_clear_selection()
	_deactivate_wire_mode()
	print("🗑️ Все компоненты и провода очищены")

func _zoom(delta):
	zoom_level += delta
	zoom_level = clamp(zoom_level, min_zoom, max_zoom)
	if camera:
		camera.zoom = Vector2(zoom_level, zoom_level)

func _zoom_in():
	_zoom(0.1)

func _zoom_out():
	_zoom(-0.1)

func _reset_view():
	if camera:
		var tween = create_tween()
		tween.tween_property(camera, "position", Vector2.ZERO, 0.3)
		tween.parallel().tween_property(camera, "zoom", Vector2.ONE, 0.3)
	zoom_level = 1.0
