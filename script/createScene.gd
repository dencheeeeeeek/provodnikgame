extends Node2D

# === ЗАГРУЗКА КОМПОНЕНТОВ ===
var battery_scene = preload("res://components/Battery.tscn")
var bulb_scene = preload("res://components/Bulb.tscn")
var switch_scene = preload("res://components/Switch.tscn")
var resistor_scene = preload("res://components/Resistor.tscn")
var ammeter_scene = preload("res://components/Ammeter.tscn")
var voltmeter_scene = preload("res://components/Voltmeter.tscn")

# === ЗАГРУЗКА ФОНА ===
var background_texture = preload("res://chank.png")
var background_sprites: Array[Sprite2D] = []

# === ПЕРЕМЕННЫЕ ДЛЯ ПЕРЕТАСКИВАНИЯ ПАНЕЛЕЙ ===
var is_dragging_tools_panel = false
var is_dragging_info_panel = false
var drag_panel_offset = Vector2()

var tools_panel: Panel = null
var info_panel: Panel = null
var components_container: VBoxContainer = null
var info_label: Label = null

# === ПЕРЕМЕННЫЕ ===
var camera: Camera2D
var is_dragging = false
var is_panning = false
var selected_component = null
var components = []
var wires = []
var zoom_level = 1.0
var last_camera_pos: Vector2 = Vector2.ZERO

# === ПЕРЕМЕННЫЕ ДЛЯ ПРОВОДОВ ===
var is_wire_mode = false
var wire_start_component = null
var temp_wire = null
var pending_component_type = null

var is_delete_mode = false 

# === ИНФОРМАЦИЯ О ЦЕПИ ===
var circuit_voltage = 0.0
var circuit_current = 0.0
var circuit_resistance = 0.0
var circuit_power = 0.0
var is_circuit_closed = false

# === ПУТЬ ДЛЯ СОХРАНЕНИЯ ===
var current_game_name = ""
var save_path = ""

# === СЛОВАРЬ КОМПОНЕНТОВ ===
var component_types = {
	"battery": {"scene": battery_scene, "name": "Батарейка", "icon": "🔋"},
	"bulb": {"scene": bulb_scene, "name": "Лампочка", "icon": "💡"},
	"switch": {"scene": switch_scene, "name": "Выключатель", "icon": "🔘"},
	"resistor": {"scene": resistor_scene, "name": "Резистор", "icon": "📏"},
	"ammeter": {"scene": ammeter_scene, "name": "Амперметр", "icon": "🔧"},
	"voltmeter": {"scene": voltmeter_scene, "name": "Вольтметр", "icon": "📊"}
}

func _ready():
	_get_game_name()
	_create_infinite_background()
	_setup_camera()
	_create_tool_panel()
	_create_info_panel()
	_create_back_button()
	add_to_group("circuit")
	_load_scene()
	print("✅ Сцена готова! Игра: ", current_game_name)
	
	# Обновляем позицию кнопки при изменении размера окна
	get_viewport().size_changed.connect(_update_back_button_position)

func _update_back_button_position():
	var btn = get_node_or_null("BackButton")
	if btn:
		btn.position = Vector2(get_viewport().size.x - 160, get_viewport().size.y - 50)

func update_simulation():
	_update_simulation()

func _create_infinite_background():
	var tex_size = background_texture.get_size()
	
	for i in range(-2, 3):
		for j in range(-2, 3):
			var bg = Sprite2D.new()
			bg.texture = background_texture
			bg.position = Vector2(i * tex_size.x, j * tex_size.y)
			bg.centered = false
			bg.z_index = -10
			add_child(bg)
			background_sprites.append(bg)
	
	call_deferred("_update_background")

func _update_background():
	if not camera:
		return
	
	var cam_pos = camera.global_position
	var tex_size = background_texture.get_size()
	
	for bg in background_sprites:
		var grid_x = round((cam_pos.x - bg.position.x) / tex_size.x)
		var grid_y = round((cam_pos.y - bg.position.y) / tex_size.y)
		bg.position = Vector2(grid_x * tex_size.x, grid_y * tex_size.y)

func _create_notification_label():
	var notification = Label.new()
	notification.name = "NotificationLabel"
	notification.add_theme_font_size_override("font_size", 20)
	notification.add_theme_color_override("font_color", Color(0.2, 0.8, 0.2, 1))
	notification.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	notification.add_theme_constant_override("shadow_offset_x", 2)
	notification.add_theme_constant_override("shadow_offset_y", 2)
	notification.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.7)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	notification.add_theme_stylebox_override("normal", style)
	
	if camera:
		camera.add_child(notification)
	else:
		add_child(notification)
	
	var viewport_size = get_viewport().get_visible_rect().size
	notification.position = Vector2(viewport_size.x / 2 - 150, viewport_size.y - 60)
	notification.size = Vector2(300, 50)
	notification.modulate = Color(1, 1, 1, 0)
	
	return notification

func _show_notification(message: String):
	var notification = null
	if camera:
		notification = camera.get_node_or_null("NotificationLabel")
	else:
		notification = get_node_or_null("NotificationLabel")
	
	if not notification:
		notification = _create_notification_label()
	
	if not notification:
		return
	
	notification.text = message
	notification.modulate = Color(1, 1, 1, 0)
	
	var tween = create_tween()
	tween.tween_property(notification, "modulate", Color(1, 1, 1, 1), 0.2)
	tween.tween_property(notification, "modulate", Color(1, 1, 1, 1), 1.5)
	tween.tween_property(notification, "modulate", Color(1, 1, 1, 0), 0.2)

func _process(delta):
	var notification = null
	if camera:
		notification = camera.get_node_or_null("NotificationLabel")
	else:
		notification = get_node_or_null("NotificationLabel")
	
	if notification:
		var viewport_size = get_viewport().get_visible_rect().size
		notification.position = Vector2(viewport_size.x / 2 - 150, viewport_size.y - 60)
	
	if camera and camera.global_position != last_camera_pos:
		_update_background()
		last_camera_pos = camera.global_position

func _get_game_name():
	var scene_path = get_tree().current_scene.scene_file_path
	var file_name = scene_path.get_file()
	current_game_name = file_name.replace(".tscn", "")
	
	var save_folder = "user://saves/"
	var dir = DirAccess.open("user://")
	if not dir.dir_exists("saves"):
		dir.make_dir("saves")
	
	save_path = "user://saves/" + current_game_name + ".json"
	print("📁 Путь сохранения: ", save_path)

func _create_back_button():
	var btn = Button.new()
	btn.name = "BackButton"
	btn.text = "🏠 ВЫЙТИ"
	btn.position = Vector2(get_viewport().size.x - 160, get_viewport().size.y - 50)
	btn.size = Vector2(150, 45)
	
	# ПОДКЛЮЧЕНИЕ ШРИФТА
	var custom_font = preload("res://fonts/Jovanny Lemonad - Bender-Bold.otf")
	if custom_font:
		btn.add_theme_font_override("font", custom_font)
	
	btn.add_theme_font_size_override("font_size", 14)
	btn.pressed.connect(_to_main_scene)
	add_child(btn)

func _setup_camera():
	camera = Camera2D.new()
	camera.name = "Camera2D"
	camera.zoom = Vector2(1, 1)
	add_child(camera)
	
	last_camera_pos = camera.global_position
	_create_notification_label()

func _create_info_panel():
	info_panel = Panel.new()
	info_panel.name = "InfoPanel"
	info_panel.position = Vector2(get_viewport().size.x - 420, 10)
	info_panel.size = Vector2(350, 500)
	add_child(info_panel)
	
	# Заголовок для перетаскивания
	var title_bar = Panel.new()
	title_bar.name = "TitleBar"
	title_bar.position = Vector2(0, 0)
	title_bar.size = Vector2(350, 30)
	
	# Стилизация заголовка (вместо color)
	var title_style = StyleBoxFlat.new()
	title_style.bg_color = Color(0.2, 0.2, 0.3, 1)
	title_bar.add_theme_stylebox_override("panel", title_style)
	
	info_panel.add_child(title_bar)
	
	var title_label = Label.new()
	title_label.text = "☰ ПАРАМЕТРЫ ЦЕПИ"
	title_label.position = Vector2(10, 5)
	title_label.add_theme_font_size_override("font_size", 14)
	title_label.add_theme_color_override("font_color", Color.WHITE)
	title_bar.add_child(title_label)
	
	# Настраиваем перетаскивание
	title_bar.gui_input.connect(_on_info_panel_drag.bind(title_bar, info_panel))
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.1, 0.95)
	style.set_border_width_all(2)
	style.border_color = Color(0.4, 0.6, 0.9, 1)
	style.set_corner_radius_all(12)
	info_panel.add_theme_stylebox_override("panel", style)
	
	info_label = Label.new()
	info_label.name = "InfoLabel"
	info_label.position = Vector2(15, 40)
	info_label.size = Vector2(370, 330)
	info_label.add_theme_font_size_override("font_size", 14)
	info_label.add_theme_color_override("font_color", Color.WHITE)
	info_panel.add_child(info_label)
	
	_update_info_panel()
	
func _on_tools_panel_drag(event: InputEvent, title_bar: Panel, panel: Panel):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_dragging_tools_panel = true
			drag_panel_offset = panel.position - get_global_mouse_position()
		else:
			is_dragging_tools_panel = false
	
	if event is InputEventMouseMotion and is_dragging_tools_panel:
		var new_pos = get_global_mouse_position() + drag_panel_offset
		# Ограничиваем, чтобы панель не выходила за экран
		new_pos.x = clamp(new_pos.x, 0, get_viewport().size.x - panel.size.x)
		new_pos.y = clamp(new_pos.y, 0, get_viewport().size.y - panel.size.y)
		panel.position = new_pos

func _on_info_panel_drag(event: InputEvent, title_bar: Panel, panel: Panel):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_dragging_info_panel = true
			drag_panel_offset = panel.position - get_global_mouse_position()
		else:
			is_dragging_info_panel = false
	
	if event is InputEventMouseMotion and is_dragging_info_panel:
		var new_pos = get_global_mouse_position() + drag_panel_offset
		# Ограничиваем, чтобы панель не выходила за экран
		new_pos.x = clamp(new_pos.x, 0, get_viewport().size.x - panel.size.x)
		new_pos.y = clamp(new_pos.y, 0, get_viewport().size.y - panel.size.y)
		panel.position = new_pos

func _update_info_panel():
	var panel = get_node_or_null("InfoPanel")
	if not panel:
		return
	var label = panel.get_node_or_null("InfoLabel")
	if not label:
		return
	
	var status_text = "ЗАМКНУТА 🟢" if is_circuit_closed else "РАЗОМКНУТА 🔴"
	
	label.text = """
┌──────────────────────────────────┐
│        ⚡ ПАРАМЕТРЫ ЦЕПИ ⚡        │
├──────────────────────────────────┤
│                                  │
│   ⚡ Напряжение:         %6.1f V  │
│                                  │
│   🔌 Сопротивление:      %6.1f Ω  │
│                                  │
│   💨 Сила тока:          %6.3f A  │
│                                  │
│   💡 Мощность:           %6.2f W  │
│                                  │
├──────────────────────────────────┤
│                                  │
│   📊 Состояние цепи: %s          │
│                                  │
└──────────────────────────────────┘
""" % [circuit_voltage, circuit_resistance, circuit_current, circuit_power, status_text]

func _create_tool_panel():
	tools_panel = Panel.new()
	tools_panel.name = "ToolsPanel"
	tools_panel.position = Vector2(10, 10)
	tools_panel.size = Vector2(220, 800)
	add_child(tools_panel)
	
	# Заголовок для перетаскивания
	var title_bar = Panel.new()
	title_bar.name = "TitleBar"
	title_bar.position = Vector2(0, 0)
	title_bar.size = Vector2(220, 30)
	
	# Стилизация заголовка (вместо color)
	var title_style = StyleBoxFlat.new()
	title_style.bg_color = Color(0.2, 0.2, 0.3, 1)
	title_bar.add_theme_stylebox_override("panel", title_style)
	
	tools_panel.add_child(title_bar)
	
	var title_label = Label.new()
	title_label.text = "☰ ИНСТРУМЕНТЫ"
	title_label.position = Vector2(10, 5)
	title_label.add_theme_font_size_override("font_size", 14)
	title_label.add_theme_color_override("font_color", Color.WHITE)
	title_bar.add_child(title_label)
	
	# Настраиваем перетаскивание
	title_bar.gui_input.connect(_on_tools_panel_drag.bind(title_bar, tools_panel))
	
	components_container = VBoxContainer.new()
	components_container.name = "ComponentsContainer"
	components_container.position = Vector2(5, 35)
	components_container.size = Vector2(210, 660)
	tools_panel.add_child(components_container)
	
	# Кнопка режима проводов
	var wire_btn = Button.new()
	wire_btn.text = "🔌 РЕЖИМ ПРОВОДОВ"
	wire_btn.custom_minimum_size = Vector2(180, 50)
	wire_btn.pressed.connect(_activate_wire_mode)
	components_container.add_child(wire_btn)
	
	# Кнопка выхода из режима проводов
	var exit_wire_btn = Button.new()
	exit_wire_btn.text = "❌ ВЫЙТИ ИЗ РЕЖИМА"
	exit_wire_btn.custom_minimum_size = Vector2(180, 45)
	exit_wire_btn.pressed.connect(_deactivate_wire_mode)
	components_container.add_child(exit_wire_btn)
	
	# Кнопка режима удаления
	var delete_btn = Button.new()
	delete_btn.text = "🗑️ РЕЖИМ УДАЛЕНИЯ"
	delete_btn.custom_minimum_size = Vector2(180, 45)
	delete_btn.pressed.connect(_activate_delete_mode)
	components_container.add_child(delete_btn)
	
	# Кнопка выхода из режима удаления
	var exit_delete_btn = Button.new()
	exit_delete_btn.text = "✅ ВЫЙТИ ИЗ УДАЛЕНИЯ"
	exit_delete_btn.custom_minimum_size = Vector2(180, 45)
	exit_delete_btn.pressed.connect(_deactivate_delete_mode)
	components_container.add_child(exit_delete_btn)
	
	var sep = HSeparator.new()
	components_container.add_child(sep)
	
	for type in component_types:
		var btn = Button.new()
		btn.text = component_types[type]["icon"] + " " + component_types[type]["name"]
		btn.custom_minimum_size = Vector2(180, 45)
		btn.pressed.connect(_start_create_component.bind(type))
		components_container.add_child(btn)
	
	var sep2 = HSeparator.new()
	components_container.add_child(sep2)
	
	var save_btn = Button.new()
	save_btn.text = "💾 СОХРАНИТЬ"
	save_btn.custom_minimum_size = Vector2(180, 45)
	save_btn.pressed.connect(_save_scene)
	components_container.add_child(save_btn)
	
	var load_btn = Button.new()
	load_btn.text = "📂 ЗАГРУЗИТЬ"
	load_btn.custom_minimum_size = Vector2(180, 45)
	load_btn.pressed.connect(_load_scene)
	components_container.add_child(load_btn)
	
	var clear_btn = Button.new()
	clear_btn.text = "🗑️ ОЧИСТИТЬ ВСЁ"
	clear_btn.custom_minimum_size = Vector2(180, 45)
	clear_btn.pressed.connect(_clear_all)
	components_container.add_child(clear_btn)
	
	var zoom_in_btn = Button.new()
	zoom_in_btn.text = "+ ПРИБЛИЗИТЬ"
	zoom_in_btn.custom_minimum_size = Vector2(180, 45)
	zoom_in_btn.pressed.connect(_zoom_in)
	components_container.add_child(zoom_in_btn)
	
	var zoom_out_btn = Button.new()
	zoom_out_btn.text = "- ОТДАЛИТЬ"
	zoom_out_btn.custom_minimum_size = Vector2(180, 45)
	zoom_out_btn.pressed.connect(_zoom_out)
	components_container.add_child(zoom_out_btn)

func _deactivate_wire_mode():
	is_wire_mode = false
	wire_start_component = null
	if temp_wire:
		temp_wire.queue_free()
		temp_wire = null
	print("🔌 Режим проводов ВЫКЛЮЧЕН! Теперь можно перемещаться по полю.")
	_show_notification("🔌 Режим проводов выключен")

func _start_create_component(comp_type):
	is_wire_mode = false
	wire_start_component = null
	if temp_wire:
		temp_wire.queue_free()
		temp_wire = null
	pending_component_type = comp_type
	print("✅ Нажми на поле, чтобы создать: ", component_types[comp_type]["name"])

func _activate_wire_mode():
	pending_component_type = null
	is_wire_mode = true
	wire_start_component = null
	if temp_wire:
		temp_wire.queue_free()
		temp_wire = null
	print("🔌 РЕЖИМ ПРОВОДОВ ВКЛЮЧЁН!")
	_show_notification("🔌 Режим проводов включён")
func _activate_delete_mode():
	# Выключаем другие режимы
	is_wire_mode = false
	wire_start_component = null
	pending_component_type = null
	if temp_wire:
		temp_wire.queue_free()
		temp_wire = null
	
	is_delete_mode = true
	print("🗑️ РЕЖИМ УДАЛЕНИЯ ВКЛЮЧЁН! Нажми на компонент, чтобы удалить его.")
	_show_notification("🗑️ Режим удаления включён. Нажми на компонент для удаления.")

func _deactivate_delete_mode():
	is_delete_mode = false
	print("✅ РЕЖИМ УДАЛЕНИЯ ВЫКЛЮЧЕН")
	_show_notification("✅ Режим удаления выключен")
func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_on_click(event.position)
			else:
				_on_release()
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom(0.1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom(-0.1)
	elif event is InputEventMouseMotion:
		# В режиме проводов и есть начатый провод - рисуем временный провод
		if is_wire_mode and wire_start_component:
			_update_temp_wire(event.position)
		
		# Перетаскивание компонента
		if is_dragging and selected_component:
			var new_pos = get_global_mouse_position()
			selected_component.global_position = new_pos
			_update_all_wires()
		# Перемещение камеры
		elif is_panning and camera and not (is_wire_mode and wire_start_component):
			camera.position -= event.relative / camera.zoom

func _on_click(screen_pos):
	var world_pos = get_global_mouse_position()
	var clicked = get_component_at_position(world_pos)
	
	# === РЕЖИМ УДАЛЕНИЯ (ПРИОРИТЕТ) ===
	if is_delete_mode:
		if clicked:
			_delete_component(clicked)
			print("🗑️ Удалён компонент: ", clicked.name)
			_show_notification("🗑️ Удалён: " + clicked.name)
		return
	
	# === РЕЖИМ ПРОВОДОВ ===
	if is_wire_mode:
		if clicked:
			if not wire_start_component:
				wire_start_component = clicked
				print("📌 Выбран компонент: ", wire_start_component.name)
			else:
				if wire_start_component != clicked:
					_create_wire(wire_start_component, clicked)
				else:
					print("⚠️ Нельзя соединить компонент сам с собой")
				wire_start_component = null
				if temp_wire:
					temp_wire.queue_free()
					temp_wire = null
		else:
			if wire_start_component:
				wire_start_component = null
				if temp_wire:
					temp_wire.queue_free()
					temp_wire = null
		return
	
	# === РЕЖИМ СОЗДАНИЯ КОМПОНЕНТОВ ===
	if pending_component_type != null:
		if not clicked:
			_create_component(pending_component_type, world_pos)
			pending_component_type = null
		return
	
	# === ОБЫЧНЫЙ РЕЖИМ ===
	if clicked:
		if selected_component and selected_component != clicked:
			if selected_component.has_method("deselect"):
				selected_component.deselect()
		selected_component = clicked
		if selected_component.has_method("select"):
			selected_component.select()
		is_dragging = true
	else:
		is_panning = true
		if selected_component:
			if selected_component.has_method("deselect"):
				selected_component.deselect()
			selected_component = null
func _delete_component(component):
	# Удаляем все провода, связанные с этим компонентом
	var wires_to_remove = []
	for wire in wires:
		if wire.from == component or wire.to == component:
			wires_to_remove.append(wire)
	
	for wire in wires_to_remove:
		if wire.line and is_instance_valid(wire.line):
			wire.line.queue_free()
		wires.erase(wire)
	
	# Удаляем сам компонент
	if is_instance_valid(component):
		component.queue_free()
	
	# Удаляем из списка компонентов
	components.erase(component)
	
	# Если удалённый компонент был выбран - сбрасываем выделение
	if selected_component == component:
		selected_component = null
	
	# Обновляем симуляцию и сохраняем
	update_simulation()
	_save_scene()

func _on_release():
	is_dragging = false
	is_panning = false

func _create_component(comp_type, pos):
	var scene = component_types[comp_type]["scene"]
	if not scene:
		return
	var comp = scene.instantiate()
	comp.global_position = pos
	comp.component_id = components.size()
	comp.name = comp_type + "_" + str(comp.component_id)
	if comp.has_signal("clicked"):
		comp.clicked.connect(_on_component_clicked)
	add_child(comp)
	components.append(comp)
	print("✅ Создан: ", comp.name)
	_save_scene()

func _on_component_clicked(comp):
	if selected_component:
		if selected_component.has_method("deselect"):
			selected_component.deselect()
	selected_component = comp
	if selected_component.has_method("select"):
		selected_component.select()

func _update_temp_wire(screen_pos):
	if not wire_start_component:
		return
	if not temp_wire:
		temp_wire = Line2D.new()
		temp_wire.width = 5
		temp_wire.default_color = Color(1, 1, 0, 1)
		temp_wire.antialiased = true
		add_child(temp_wire)
	var mouse_pos = get_global_mouse_position()
	var start_pos = wire_start_component.global_position
	temp_wire.clear_points()
	temp_wire.add_point(start_pos)
	temp_wire.add_point(mouse_pos)

func _create_wire(comp1, comp2):
	for w in wires:
		if (w.from == comp1 and w.to == comp2) or (w.from == comp2 and w.to == comp1):
			print("⚠️ Провод уже есть!")
			return
	var wire = {
		"from": comp1,
		"to": comp2,
		"line": null
	}
	var line = Line2D.new()
	line.width = 5
	line.default_color = Color(1, 0.5, 0, 1)
	line.antialiased = true
	line.add_point(comp1.global_position)
	line.add_point(comp2.global_position)
	add_child(line)
	wire.line = line
	wires.append(wire)
	if not comp1.has_meta("connections"):
		comp1.set_meta("connections", [])
	if not comp2.has_meta("connections"):
		comp2.set_meta("connections", [])
	comp1.get_meta("connections").append(comp2)
	comp2.get_meta("connections").append(comp1)
	print("🔗 Проводов теперь: ", wires.size())
	update_simulation()
	_save_scene()

func _update_all_wires():
	for wire in wires:
		if wire.line:
			wire.line.clear_points()
			wire.line.add_point(wire.from.global_position)
			wire.line.add_point(wire.to.global_position)
	update_simulation()

func get_component_at_position(pos):
	for i in range(components.size() - 1, -1, -1):
		var comp = components[i]
		var dist = pos.distance_to(comp.global_position)
		if dist < 50:
			return comp
	return null

# ============ СОХРАНЕНИЕ ============
func _save_scene():
	if save_path.is_empty():
		print("❌ Путь сохранения не установлен!")
		return
	
	print("========== СОХРАНЕНИЕ ==========")
	print("Игра: ", current_game_name)
	
	var save_data = {
		"version": "1.0",
		"game_name": current_game_name,
		"components": [],
		"wires": [],
		"camera_pos": [camera.position.x, camera.position.y] if camera else [0, 0],
		"camera_zoom": zoom_level,
		"saved_at": Time.get_datetime_string_from_system()
	}
	
	# Добавляем позиции панелей
	if tools_panel:
		save_data["tools_panel_pos"] = [tools_panel.position.x, tools_panel.position.y]
	if info_panel:
		save_data["info_panel_pos"] = [info_panel.position.x, info_panel.position.y]
	
	for comp in components:
		var comp_type = comp.name.split("_")[0].to_lower()
		var comp_data = {
			"type": comp_type,
			"pos_x": comp.global_position.x,
			"pos_y": comp.global_position.y,
			"id": int(comp.component_id)
		}
		
		if comp_type == "switch" and comp.has_method("is_switch_on"):
			comp_data["switch_on"] = comp.is_switch_on()
		
		if comp_type == "resistor" and comp.has_method("get_resistance"):
			comp_data["resistance"] = comp.get_resistance()
		
		if comp_type == "battery" and comp.has_method("get_voltage"):
			comp_data["voltage"] = comp.get_voltage()
		
		save_data["components"].append(comp_data)
	
	for wire in wires:
		save_data["wires"].append({
			"from_id": int(wire.from.component_id),
			"to_id": int(wire.to.component_id)
		})
	
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(save_data, "\t"))
	file.close()
	
	print("✅ СОХРАНЕНО! Компонентов: ", components.size(), ", проводов: ", wires.size())
	_show_notification("💾 ИГРА СОХРАНЕНА!")

func _load_scene():
	if save_path.is_empty():
		print("❌ Путь сохранения не установлен!")
		return
	
	
	print("========== ЗАГРУЗКА ==========")
	print("Игра: ", current_game_name)
	
	if not FileAccess.file_exists(save_path):
		print("❌ Нет сохранений для этой игры!")
		_show_notification("📂 НЕТ СОХРАНЕНИЙ")
		return
	
	var file = FileAccess.open(save_path, FileAccess.READ)
	var content = file.get_as_text()
	file.close()
	
	var save_data = JSON.parse_string(content)
	if not save_data:
		print("❌ Ошибка парсинга!")
		_show_notification("❌ ОШИБКА ЗАГРУЗКИ")
		return
	
	print("Время сохранения: ", save_data.get("saved_at", "неизвестно"))
	
	_clear_all()
	
	var component_map = {}
	for comp_data in save_data["components"]:
		var comp_type = comp_data["type"].to_lower()
		
		if not component_types.has(comp_type):
			continue
		
		var comp = component_types[comp_type]["scene"].instantiate()
		comp.global_position = Vector2(comp_data["pos_x"], comp_data["pos_y"])
		
		var comp_id = int(comp_data["id"])
		comp.component_id = comp_id
		comp.name = comp_type + "_" + str(comp_id)
		
		if comp.has_signal("clicked"):
			comp.clicked.connect(_on_component_clicked)
		
		if comp_type == "switch" and comp_data.has("switch_on"):
			if comp.has_method("is_switch_on"):
				if comp.is_switch_on() != comp_data["switch_on"]:
					if comp.has_method("toggle"):
						comp.toggle()
		
		if comp_type == "battery" and comp_data.has("voltage"):
			if comp.has_method("set_voltage"):
				comp.set_voltage(comp_data["voltage"])
		
		add_child(comp)
		components.append(comp)
		component_map[comp_id] = comp
	
	for wire_data in save_data["wires"]:
		var from_id = int(wire_data["from_id"])
		var to_id = int(wire_data["to_id"])
		var from_comp = component_map.get(from_id)
		var to_comp = component_map.get(to_id)
		
		if from_comp and to_comp:
			var wire = {
				"from": from_comp,
				"to": to_comp,
				"line": null
			}
			var line = Line2D.new()
			line.width = 5
			line.default_color = Color(1, 0.5, 0, 1)
			line.antialiased = true
			line.add_point(from_comp.global_position)
			line.add_point(to_comp.global_position)
			add_child(line)
			wire.line = line
			wires.append(wire)
			
			if not from_comp.has_meta("connections"):
				from_comp.set_meta("connections", [])
			if not to_comp.has_meta("connections"):
				to_comp.set_meta("connections", [])
			from_comp.get_meta("connections").append(to_comp)
			to_comp.get_meta("connections").append(from_comp)
	
	if camera and save_data.has("camera_pos"):
		camera.position = Vector2(save_data["camera_pos"][0], save_data["camera_pos"][1])
	if save_data.has("camera_zoom"):
		zoom_level = save_data["camera_zoom"]
		camera.zoom = Vector2(zoom_level, zoom_level)
	if save_data.has("tools_panel_pos") and tools_panel:
		tools_panel.position = Vector2(save_data["tools_panel_pos"][0], save_data["tools_panel_pos"][1])
	if save_data.has("info_panel_pos") and info_panel:
		info_panel.position = Vector2(save_data["info_panel_pos"][0], save_data["info_panel_pos"][1])
	
	update_simulation()
	_update_background()
	print("✅ ЗАГРУЗКА ЗАВЕРШЕНА! Компонентов: ", components.size())
	_show_notification("📂 ИГРА ЗАГРУЖЕНА!")

# ============ ФИЗИКА ЦЕПИ ============

func _update_simulation():
	print("\n========== ОБНОВЛЕНИЕ СИМУЛЯЦИИ ==========")
	
	for wire in wires:
		if wire.line:
			wire.line.default_color = Color(0.3, 0.3, 0.3, 1)
	
	circuit_voltage = 0.0
	circuit_current = 0.0
	circuit_resistance = 0.0
	circuit_power = 0.0
	is_circuit_closed = false
	
	var batteries = []
	for comp in components:
		if comp.name.to_lower().contains("battery"):
			batteries.append(comp)
			print("🔋 Найдена батарейка: ", comp.name)
	
	if batteries.is_empty():
		print("❌ Нет батареек!")
		_update_info_panel()
		return
	
	for battery in batteries:
		var result = _analyze_circuit_correct(battery)
		if result.is_closed:
			circuit_voltage = result.voltage
			circuit_current = result.total_current
			circuit_resistance = result.total_resistance
			circuit_power = result.total_power
			is_circuit_closed = true
			
			for amm_data in result.ammeter_currents:
				var ammeter = amm_data["ammeter"]
				var current = amm_data["current"]
				if ammeter and ammeter.has_method("update_state"):
					ammeter.update_state(current)
					print("   🔧 Амперметр ", ammeter.name, " показывает ", current, " A")
			
			for volt_data in result.voltmeter_voltages:
				var voltmeter = volt_data["voltmeter"]
				var voltage = volt_data["voltage"]
				if voltmeter and voltmeter.has_method("update_state"):
					voltmeter.update_state(voltage)
					print("   📊 Вольтметр ", voltmeter.name, " показывает ", voltage, " V")
			
			print("\n✅ ЦЕПЬ ЗАМКНУТА!")
			print("   📊 Напряжение: ", circuit_voltage, " V")
			print("   📊 Общее сопротивление: ", circuit_resistance, " Ω")
			print("   📊 Общий ток: ", circuit_current, " A")
			print("   📊 Мощность: ", circuit_power, " W")
			break
		else:
			print("❌ Цепь НЕ ЗАМКНУТА!")
	
	_update_info_panel()
	print("=====================================\n")

func _analyze_circuit_correct(battery) -> Dictionary:
	var result = {
		"is_closed": false,
		"voltage": 0.0,
		"total_current": 0.0,
		"total_resistance": 0.0,
		"total_power": 0.0,
		"component_currents": {},
		"branch_currents": {},
		"component_voltages": {},
		"ammeter_currents": [],
		"voltmeter_voltages": []
	}
	
	var connections = battery.get_meta("connections", [])
	print("   Подключено проводов к батарейке: ", connections.size())
	
	if connections.size() < 2:
		print("   ❌ Недостаточно проводов!")
		return result
	
	var all_paths = _find_all_paths_from_to(connections[0], connections[1], battery)
	
	print("   Найдено путей: ", all_paths.size())
	
	if all_paths.is_empty():
		print("   ❌ Нет путей!")
		return result
	
	var all_switches_on = true
	for path in all_paths:
		for comp in path:
			if comp.name.to_lower().contains("switch"):
				var is_on = _get_switch_state(comp)
				print("   🔘 Выключатель ", comp.name, " = ", "ON" if is_on else "OFF")
				if not is_on:
					all_switches_on = false
					break
		if not all_switches_on:
			break
	
	if not all_switches_on:
		return result
	
	var total_voltage = _get_battery_voltage(battery)
	result.voltage = total_voltage
	print("   ⚡ Общее напряжение источника: ", total_voltage, " V")
	
	var path_resistances = []
	var path_components = []
	
	for path in all_paths:
		var path_res = 0.0
		var comp_list = []
		print("   Путь ", path_resistances.size() + 1, ":")
		for comp in path:
			var r = _get_resistance(comp)
			print("      ", comp.name, ": R=", r, " Ω")
			if r > 0 and r < 999999:
				path_res += r
			comp_list.append(comp)
		path_res += 0.05
		path_resistances.append(path_res)
		path_components.append(comp_list)
		print("      Общее R = ", path_res, " Ω")
	
	var is_parallel = all_paths.size() > 1
	var total_resistance = 0.0
	
	if is_parallel:
		var inverse_sum = 0.0
		for r in path_resistances:
			if r > 0:
				inverse_sum += 1.0 / r
		total_resistance = 1.0 / inverse_sum if inverse_sum > 0 else 0
	else:
		total_resistance = path_resistances[0] if path_resistances.size() > 0 else 0
	
	print("   📊 Общее сопротивление: ", total_resistance, " Ω (", "параллельное" if is_parallel else "последовательное", ")")
	
	var total_current = total_voltage / total_resistance if total_resistance > 0 else 0
	total_current = clamp(total_current, 0.0, 10.0)
	result.total_current = total_current
	result.total_resistance = total_resistance
	result.total_power = total_voltage * total_current
	print("   💨 Общий ток: ", total_current, " A")
	
	if is_parallel:
		print("   📊 Параллельное соединение: напряжение на всех ветвях = ", total_voltage, " V")
		
		for i in range(path_components.size()):
			var branch_comps = path_components[i]
			var branch_resistance = path_resistances[i]
			var branch_current = total_voltage / branch_resistance if branch_resistance > 0 else 0
			branch_current = clamp(branch_current, 0.0, 10.0)
			
			print("   🌿 Ветвь ", i+1, ": I = ", branch_current, " A, U = ", total_voltage, " V")
			
			for comp in branch_comps:
				var r = _get_resistance(comp)
				if r > 0 and r < 999999:
					var comp_voltage = branch_current * r
					result.component_voltages[comp] = comp_voltage
					result.component_currents[comp] = branch_current
					result.branch_currents[comp] = branch_current
					print("      ", comp.name, ": I=", branch_current, " A, R=", r, " Ω, U=", comp_voltage, " V")
				elif r == 0:
					print("      ", comp.name, ": проводник")
					result.component_voltages[comp] = 0.0
					result.component_currents[comp] = branch_current
	else:
		var main_path = path_components[0]
		var current = total_current
		
		print("   📊 Последовательная цепь: ток = ", current, " A")
		
		for comp in main_path:
			var r = _get_resistance(comp)
			if r > 0 and r < 999999:
				var comp_voltage = current * r
				result.component_voltages[comp] = comp_voltage
				result.component_currents[comp] = current
				result.branch_currents[comp] = current
				print("      ", comp.name, ": I=", current, " A, R=", r, " Ω, U=", comp_voltage, " V")
			elif r == 0:
				print("      ", comp.name, ": проводник (R=0)")
				result.component_voltages[comp] = 0.0
				result.component_currents[comp] = current
			else:
				print("      ", comp.name, ": разрыв цепи (R=∞)")
		
		var voltage_sum = 0.0
		for comp in main_path:
			voltage_sum += result.component_voltages.get(comp, 0.0)
		print("   🔍 Проверка: сумма напряжений = ", voltage_sum, " V (должно быть ~", total_voltage, " V)")
	
	# Обновляем амперметры
	for comp in components:
		if comp.name.to_lower().contains("ammeter"):
			var current = result.component_currents.get(comp, 0.0)
			result.ammeter_currents.append({
				"ammeter": comp,
				"current": current
			})
			if comp.has_method("update_state"):
				comp.update_state(current)
				print("   🔧 Амперметр ", comp.name, " = ", current, " A")
	
	# Обновляем вольтметры
	for comp in components:
		if comp.name.to_lower().contains("voltmeter"):
			var volt_connections = comp.get_meta("connections", [])
			var target_component = null
			var target_voltage = total_voltage
			
			for conn in volt_connections:
				if conn != battery and not conn.name.to_lower().contains("switch"):
					target_component = conn
					break
			
			if target_component:
				target_voltage = result.component_voltages.get(target_component, total_voltage)
				print("   📊 Вольтметр ", comp.name, " подключен к ", target_component.name, " -> показывает ", target_voltage, " V")
			else:
				print("   📊 Вольтметр ", comp.name, " не подключен к компоненту -> показывает общее напряжение ", total_voltage, " V")
			
			result.voltmeter_voltages.append({
				"voltmeter": comp,
				"voltage": target_voltage
			})
			if comp.has_method("update_state"):
				comp.update_state(target_voltage)
	
	result.is_closed = true
	return result

func _find_all_paths_from_to(start, target, avoid) -> Array:
	var all_paths = []
	var queue = [[start]]
	var visited_paths = []
	
	while queue.size() > 0:
		var path = queue.pop_front()
		var current = path[-1]
		
		if current == target:
			var is_duplicate = false
			for existing in visited_paths:
				if existing.size() == path.size():
					var paths_equal = true
					for i in range(path.size()):
						if existing[i] != path[i]:
							paths_equal = false
							break
					if paths_equal:
						is_duplicate = true
						break
			if not is_duplicate:
				all_paths.append(path)
				visited_paths.append(path)
			continue
		
		if current.has_meta("connections"):
			for conn in current.get_meta("connections"):
				if conn != avoid and conn not in path:
					var new_path = path.duplicate()
					new_path.append(conn)
					queue.append(new_path)
	
	return all_paths

func _get_battery_voltage(battery) -> float:
	if battery.has_method("get_voltage"):
		return battery.get_voltage()
	return 9.0

func _get_switch_state(switch_comp) -> bool:
	if switch_comp.has_method("is_switch_on"):
		return switch_comp.is_switch_on()
	elif switch_comp.has_meta("is_on"):
		return switch_comp.get_meta("is_on")
	return true

func _get_resistance(comp) -> float:
	var name = comp.name.to_lower()
	if name.contains("bulb"):
		return 100.0
	elif name.contains("resistor"):
		if comp.has_method("get_resistance"):
			return comp.get_resistance()
		return 50.0
	elif name.contains("switch"):
		return 0.0
	elif name.contains("ammeter"):
		return 0.01
	elif name.contains("voltmeter"):
		return 1000000.0
	return 0.0

func _light_wire(comp1, comp2, current: float):
	for wire in wires:
		if (wire.from == comp1 and wire.to == comp2) or (wire.from == comp2 and wire.to == comp1):
			if wire.line:
				if current > 0:
					var intensity = clamp(current * 0.3, 0.2, 1.0)
					wire.line.default_color = Color(1.0, intensity * 0.5, 0.2, 1.0)
				else:
					wire.line.default_color = Color(0.5, 0.5, 0.5, 0.8)
			return

func _clear_all():
	for comp in components:
		if is_instance_valid(comp):
			comp.queue_free()
	for wire in wires:
		if wire.line and is_instance_valid(wire.line):
			wire.line.queue_free()
	components.clear()
	wires.clear()
	if selected_component:
		selected_component = null
	if temp_wire:
		temp_wire.queue_free()
		temp_wire = null
	is_wire_mode = false
	pending_component_type = null
	wire_start_component = null
	circuit_voltage = 0.0
	circuit_current = 0.0
	circuit_resistance = 0.0
	circuit_power = 0.0
	is_circuit_closed = false
	_update_info_panel()
	print("🗑️ ВСЁ ОЧИЩЕНО!")

func _zoom(delta):
	zoom_level += delta
	zoom_level = clamp(zoom_level, 0.5, 2.0)
	if camera:
		camera.zoom = Vector2(zoom_level, zoom_level)

func _zoom_in():
	_zoom(0.1)

func _zoom_out():
	_zoom(-0.1)

func _to_main_scene():
	_save_scene()
	get_tree().change_scene_to_file("res://scene/NewGameMenu.tscn")
