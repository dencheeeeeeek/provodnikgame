extends Area2D
class_name Battery

signal clicked
signal voltage_changed(new_voltage)

@export var voltage: float = 9.0
@export var component_id: int = 0

var is_selected: bool = false
var is_long_pressing: bool = false
var long_press_timer: float = 0.0
var voltage_menu_open: bool = false
var sprite: Sprite2D
var voltage_label: Label
var outline: Sprite2D
var current_dialog: Window = null

const LONG_PRESS_TIME = 0.5

func _ready():
	_draw_battery()
	_setup_collision()
	_setup_signals()

func _draw_battery():
	if sprite:
		sprite.queue_free()
	if voltage_label:
		voltage_label.queue_free()
	if outline:
		outline.queue_free()
	
	var image = Image.create(80, 60, false, Image.FORMAT_RGBA8)
	
	for x in range(80):
		for y in range(60):
			if x > 10 and x < 70 and y > 10 and y < 50:
				image.set_pixel(x, y, Color(0.3, 0.3, 0.3, 1))
			elif x > 35 and x < 45 and y > 3 and y < 12:
				image.set_pixel(x, y, Color.RED)
			elif x > 35 and x < 45 and y > 48 and y < 57:
				image.set_pixel(x, y, Color.BLUE)
	
	var texture = ImageTexture.create_from_image(image)
	sprite = Sprite2D.new()
	sprite.texture = texture
	sprite.centered = true
	add_child(sprite)
	
	voltage_label = Label.new()
	voltage_label.text = str(int(voltage)) + "V"
	voltage_label.position = Vector2(-10, -10)
	voltage_label.add_theme_font_size_override("font_size", 14)
	add_child(voltage_label)
	
	outline = Sprite2D.new()
	var outline_image = Image.create(84, 64, false, Image.FORMAT_RGBA8)
	for x in range(84):
		for y in range(64):
			if x == 0 or x == 83 or y == 0 or y == 63:
				outline_image.set_pixel(x, y, Color.YELLOW)
	var outline_texture = ImageTexture.create_from_image(outline_image)
	outline.texture = outline_texture
	outline.visible = false
	add_child(outline)

func _setup_collision():
	for child in get_children():
		if child is CollisionShape2D:
			child.queue_free()
	
	var collision = CollisionShape2D.new()
	var rect_shape = RectangleShape2D.new()
	rect_shape.size = Vector2(70, 50)
	collision.shape = rect_shape
	collision.position = Vector2(0, 0)
	add_child(collision)

func _setup_signals():
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered():
	if not is_selected:
		modulate = Color(1.2, 1.2, 1.2)

func _on_mouse_exited():
	if not is_selected:
		modulate = Color.WHITE
	is_long_pressing = false
	long_press_timer = 0.0

func _process(delta):
	if is_long_pressing and not voltage_menu_open:
		long_press_timer += delta
		if long_press_timer >= LONG_PRESS_TIME:
			is_long_pressing = false
			_open_voltage_menu()

func _input_event(viewport, event, shape_idx):
	# Левый клик/касание - выделение
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		clicked.emit(self)
	
	# Правый клик мыши - меню напряжения
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		_open_voltage_menu()
		get_viewport().set_input_as_handled()
	
	# Тач для мобильных устройств
	if event is InputEventScreenTouch:
		if event.pressed:
			is_long_pressing = true
			long_press_timer = 0.0
		else:
			if long_press_timer < LONG_PRESS_TIME and long_press_timer > 0 and not voltage_menu_open:
				clicked.emit(self)
			is_long_pressing = false
			long_press_timer = 0.0
func _open_voltage_menu():
	if voltage_menu_open:
		return
	
	voltage_menu_open = true
	
	var dialog = Window.new()
	current_dialog = dialog
	dialog.title = ""
	dialog.size = Vector2(420, 480)
	dialog.exclusive = true
	dialog.transient = true
	dialog.popup_centered()
	
	# Убираем возможность изменения размера и делаем окно без рамки
	dialog.unresizable = true
	dialog.borderless = true  # Убирает рамку и заголовок
	
	# Создаём основной контейнер с красивым фоном
	var main_panel = Panel.new()
	main_panel.size = Vector2(400, 460)
	main_panel.position = Vector2(10, 10)
	
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.08, 0.12, 0.98)
	panel_style.set_border_width_all(2)
	panel_style.border_color = Color(0.5, 0.7, 1, 1)
	panel_style.set_corner_radius_all(20)
	panel_style.shadow_size = 10
	panel_style.shadow_color = Color(0, 0, 0, 0.5)
	main_panel.add_theme_stylebox_override("panel", panel_style)
	dialog.add_child(main_panel)
	
	# Заголовок
	var title_panel = Panel.new()
	title_panel.size = Vector2(400, 50)
	title_panel.position = Vector2(0, 0)
	var title_style = StyleBoxFlat.new()
	title_style.bg_color = Color(0.15, 0.15, 0.25, 1)
	title_style.corner_radius_top_left = 20
	title_style.corner_radius_top_right = 20
	title_style.corner_radius_bottom_left = 0
	title_style.corner_radius_bottom_right = 0
	title_panel.add_theme_stylebox_override("panel", title_style)
	main_panel.add_child(title_panel)
	
	# Заголовок - позиционируем по центру
	var title_label = Label.new()
	title_label.text = "⚡ НАСТРОЙКА НАПРЯЖЕНИЯ ⚡"
	title_label.position = Vector2(80, 12)
	title_label.size = Vector2(240, 30)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 16)
	title_label.add_theme_color_override("font_color", Color(1, 0.9, 0.5, 1))
	title_panel.add_child(title_label)
	
	# Кнопка закрытия
	var close_btn = Button.new()
	close_btn.text = "✕"
	close_btn.position = Vector2(365, 10)
	close_btn.size = Vector2(30, 30)
	close_btn.add_theme_font_size_override("font_size", 18)
	close_btn.add_theme_color_override("font_color", Color(1, 0.5, 0.5, 1))
	
	var close_style = StyleBoxFlat.new()
	close_style.bg_color = Color(0.5, 0.2, 0.2, 1)
	close_style.set_corner_radius_all(15)
	close_btn.add_theme_stylebox_override("normal", close_style)
	
	var close_hover_style = StyleBoxFlat.new()
	close_hover_style.bg_color = Color(0.7, 0.3, 0.3, 1)
	close_hover_style.set_corner_radius_all(15)
	close_btn.add_theme_stylebox_override("hover", close_hover_style)
	
	close_btn.pressed.connect(func():
		voltage_menu_open = false
		current_dialog = null
		dialog.queue_free()
	)
	title_panel.add_child(close_btn)
	
	var vbox = VBoxContainer.new()
	vbox.position = Vector2(30, 70)
	vbox.size = Vector2(340, 360)
	vbox.add_theme_constant_override("separation", 15)
	main_panel.add_child(vbox)
	
	# Иконка батарейки
	var icon_container = CenterContainer.new()
	icon_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(icon_container)
	
	var icon_label = Label.new()
	icon_label.text = "🔋"
	icon_label.add_theme_font_size_override("font_size", 64)
	icon_label.add_theme_color_override("font_color", Color(1, 0.8, 0.2, 1))
	icon_container.add_child(icon_label)
	
	# Текущее напряжение
	var current_frame = Panel.new()
	current_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	current_frame.custom_minimum_size = Vector2(0, 80)
	var frame_style = StyleBoxFlat.new()
	frame_style.bg_color = Color(0.12, 0.12, 0.18, 1)
	frame_style.set_border_width_all(1)
	frame_style.border_color = Color(0.4, 0.6, 0.9, 0.5)
	frame_style.set_corner_radius_all(12)
	current_frame.add_theme_stylebox_override("panel", frame_style)
	vbox.add_child(current_frame)
	
	var current_vbox = VBoxContainer.new()
	current_vbox.position = Vector2(10, 10)
	current_vbox.size = Vector2(320, 60)
	current_frame.add_child(current_vbox)
	
	var current_label = Label.new()
	current_label.text = "ТЕКУЩЕЕ НАПРЯЖЕНИЕ"
	current_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	current_label.add_theme_font_size_override("font_size", 12)
	current_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.9, 1))
	current_vbox.add_child(current_label)
	
	var voltage_display = Label.new()
	voltage_display.text = str(int(voltage)) + " В"
	voltage_display.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	voltage_display.add_theme_font_size_override("font_size", 42)
	voltage_display.add_theme_color_override("font_color", Color(1, 0.9, 0.3, 1))
	current_vbox.add_child(voltage_display)
	
	# Слайдер
	var slider_label = Label.new()
	slider_label.text = "ВЫБЕРИТЕ НАПРЯЖЕНИЕ (1-40 В)"
	slider_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	slider_label.add_theme_font_size_override("font_size", 12)
	slider_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.9, 1))
	vbox.add_child(slider_label)
	
	var slider = HSlider.new()
	slider.min_value = 1.0
	slider.max_value = 40.0
	slider.step = 1.0
	slider.value = voltage
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size = Vector2(0, 30)
	
	var slider_style = StyleBoxFlat.new()
	slider_style.bg_color = Color(0.2, 0.2, 0.3, 1)
	slider_style.set_corner_radius_all(8)
	slider.add_theme_stylebox_override("slider", slider_style)
	
	var grabber_style = StyleBoxFlat.new()
	grabber_style.bg_color = Color(0.5, 0.7, 1, 1)
	grabber_style.set_corner_radius_all(12)
	slider.add_theme_stylebox_override("grabber", grabber_style)
	
	vbox.add_child(slider)
	
	var slider_value_label = Label.new()
	slider_value_label.text = str(int(voltage)) + " В"
	slider_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	slider_value_label.add_theme_font_size_override("font_size", 20)
	slider_value_label.add_theme_color_override("font_color", Color(0.8, 0.9, 1, 1))
	vbox.add_child(slider_value_label)
	
	slider.value_changed.connect(func(value):
		slider_value_label.text = str(int(value)) + " В"
		voltage_display.text = str(int(value)) + " В"
	)
	
	# Кнопки
	var buttons_container = HBoxContainer.new()
	buttons_container.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons_container.add_theme_constant_override("separation", 20)
	vbox.add_child(buttons_container)
	
	var ok_btn = Button.new()
	ok_btn.text = "ПРИМЕНИТЬ"
	ok_btn.custom_minimum_size = Vector2(130, 45)
	ok_btn.add_theme_font_size_override("font_size", 14)
	
	var ok_style = StyleBoxFlat.new()
	ok_style.bg_color = Color(0.2, 0.5, 0.2, 1)
	ok_style.set_border_width_all(1)
	ok_style.border_color = Color(0.3, 0.8, 0.3, 1)
	ok_style.set_corner_radius_all(10)
	ok_btn.add_theme_stylebox_override("normal", ok_style)
	
	var ok_hover_style = StyleBoxFlat.new()
	ok_hover_style.bg_color = Color(0.3, 0.6, 0.3, 1)
	ok_hover_style.set_border_width_all(1)
	ok_hover_style.border_color = Color(0.4, 0.9, 0.4, 1)
	ok_hover_style.set_corner_radius_all(10)
	ok_btn.add_theme_stylebox_override("hover", ok_hover_style)
	
	var cancel_btn = Button.new()
	cancel_btn.text = "ОТМЕНА"
	cancel_btn.custom_minimum_size = Vector2(130, 45)
	cancel_btn.add_theme_font_size_override("font_size", 14)
	
	var cancel_style = StyleBoxFlat.new()
	cancel_style.bg_color = Color(0.5, 0.2, 0.2, 1)
	cancel_style.set_border_width_all(1)
	cancel_style.border_color = Color(0.8, 0.3, 0.3, 1)
	cancel_style.set_corner_radius_all(10)
	cancel_btn.add_theme_stylebox_override("normal", cancel_style)
	
	var cancel_hover_style = StyleBoxFlat.new()
	cancel_hover_style.bg_color = Color(0.6, 0.3, 0.3, 1)
	cancel_hover_style.set_border_width_all(1)
	cancel_hover_style.border_color = Color(0.9, 0.4, 0.4, 1)
	cancel_hover_style.set_corner_radius_all(10)
	cancel_btn.add_theme_stylebox_override("hover", cancel_hover_style)
	
	buttons_container.add_child(ok_btn)
	buttons_container.add_child(cancel_btn)
	
	ok_btn.pressed.connect(func():
		voltage = slider.value
		voltage_label.text = str(int(voltage)) + "V"
		voltage_changed.emit(voltage)
		voltage_menu_open = false
		current_dialog = null
		dialog.queue_free()
		
		var parent = get_parent()
		while parent:
			if parent.has_method("update_simulation"):
				parent.update_simulation()
				break
			parent = parent.get_parent()
	)
	
	cancel_btn.pressed.connect(func():
		voltage_menu_open = false
		current_dialog = null
		dialog.queue_free()
	)
	
	add_child(dialog)
	dialog.popup_centered()

func update_state(current: float):
	set_meta("current", current)
	if current > 0:
		var intensity = clamp(current * 0.2, 0.1, 0.5)
		modulate = Color(1, 1 + intensity, 1 + intensity)
	else:
		modulate = Color.WHITE

func get_connection_point() -> Vector2:
	return global_position

func get_voltage() -> float:
	return voltage

func get_rect() -> Rect2:
	return Rect2(position - Vector2(40, 30), Vector2(80, 60))

# ============ ДОБАВЬ ЭТИ ФУНКЦИИ СЮДА ============
func start_long_press():
	is_long_pressing = true
	long_press_timer = 0.0

func cancel_long_press():
	is_long_pressing = false
	long_press_timer = 0.0

func is_menu_open() -> bool:
	return voltage_menu_open
