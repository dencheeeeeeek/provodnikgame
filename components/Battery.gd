extends Area2D
class_name Battery

signal clicked
signal voltage_changed(new_voltage)

@export var voltage: float = 9.0
@export var component_id: int = 0

var is_selected: bool = false
var is_long_pressing: bool = false
var long_press_timer: float = 0.0
var sprite: Sprite2D
var voltage_label: Label
var outline: Sprite2D

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
	add_child(sprite)
	
	voltage_label = Label.new()
	voltage_label.text = str(int(voltage)) + "V"
	voltage_label.position = Vector2(30, 20)
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
	var collision = CollisionShape2D.new()
	var rect_shape = RectangleShape2D.new()
	rect_shape.size = Vector2(70, 50)
	collision.shape = rect_shape
	collision.position = Vector2(40, 30)
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
	if is_long_pressing:
		long_press_timer += delta
		if long_press_timer >= LONG_PRESS_TIME:
			is_long_pressing = false
			_open_voltage_menu()

func _input_event(viewport, event, shape_idx):
	# Правый клик мыши
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		_open_voltage_menu()
	
	# Долгое нажатие для тач-устройств
	if event is InputEventScreenTouch:
		if event.pressed:
			is_long_pressing = true
			long_press_timer = 0.0
		else:
			if long_press_timer < LONG_PRESS_TIME and long_press_timer > 0:
				clicked.emit(self)
			is_long_pressing = false
			long_press_timer = 0.0

func _open_voltage_menu():
	var dialog = Window.new()
	dialog.title = "Настройка напряжения батарейки"
	dialog.size = Vector2(350, 250)
	dialog.exclusive = true
	dialog.transient = true
	dialog.popup_centered()
	
	var main_container = VBoxContainer.new()
	main_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_container.add_theme_constant_override("separation", 15)
	
	var label = Label.new()
	label.text = "Выберите напряжение:"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 16)
	
	var slider = HSlider.new()
	slider.min_value = 1.0
	slider.max_value = 40.0
	slider.step = 1.0
	slider.value = voltage
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var value_label = Label.new()
	value_label.text = str(int(voltage)) + " V"
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value_label.add_theme_font_size_override("font_size", 24)
	value_label.add_theme_color_override("font_color", Color.YELLOW)
	
	slider.value_changed.connect(func(value):
		value_label.text = str(int(value)) + " V"
	)
	
	var buttons_container = HBoxContainer.new()
	buttons_container.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons_container.add_theme_constant_override("separation", 20)
	
	var ok_btn = Button.new()
	ok_btn.text = "Применить"
	ok_btn.custom_minimum_size = Vector2(120, 45)
	ok_btn.add_theme_font_size_override("font_size", 16)
	
	var cancel_btn = Button.new()
	cancel_btn.text = "Отмена"
	cancel_btn.custom_minimum_size = Vector2(120, 45)
	cancel_btn.add_theme_font_size_override("font_size", 16)
	
	buttons_container.add_child(ok_btn)
	buttons_container.add_child(cancel_btn)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_all", 20)
	
	main_container.add_child(label)
	main_container.add_child(slider)
	main_container.add_child(value_label)
	main_container.add_child(buttons_container)
	
	margin.add_child(main_container)
	dialog.add_child(margin)
	
	ok_btn.pressed.connect(func():
		voltage = slider.value
		voltage_label.text = str(int(voltage)) + "V"
		voltage_changed.emit(voltage)
		dialog.queue_free()
		
		# Обновляем симуляцию
		var parent = get_parent()
		while parent:
			if parent.has_method("update_simulation"):
				parent.update_simulation()
				break
			parent = parent.get_parent()
	)
	
	cancel_btn.pressed.connect(func():
		dialog.queue_free()
	)
	
	add_child(dialog)
	dialog.popup_centered()

func select():
	is_selected = true
	outline.visible = true
	modulate = Color(1.2, 1.2, 1.2)

func deselect():
	is_selected = false
	outline.visible = false
	modulate = Color.WHITE

func update_state(current: float):
	set_meta("current", current)
	if current > 0:
		var intensity = clamp(current * 0.2, 0.1, 0.5)
		modulate = Color(1, 1 + intensity, 1 + intensity)
	else:
		modulate = Color.WHITE

func get_connection_point() -> Vector2:
	return global_position + Vector2(40, 30)

func get_voltage() -> float:
	return voltage

func get_rect() -> Rect2:
	return Rect2(position - Vector2(40, 30), Vector2(80, 60))
