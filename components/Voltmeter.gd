extends Area2D
class_name Voltmeter

signal clicked

@export var voltage_value: float = 0.0
@export var component_id: int = 0

var is_selected: bool = false
var sprite: Sprite2D
var value_label: Label
var outline: Sprite2D

func _ready():
	print("📊 Вольтметр ", name, " создан!")
	_draw_voltmeter()
	_setup_collision()
	_setup_signals()

func _draw_voltmeter():
	if sprite:
		sprite.queue_free()
	if value_label:
		value_label.queue_free()
	
	var image = Image.create(80, 80, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	
	for x in range(80):
		for y in range(80):
			var dx = x - 40
			var dy = y - 40
			var dist = sqrt(dx*dx + dy*dy)
			if dist < 35:
				image.set_pixel(x, y, Color(0.3, 0.3, 0.4, 1))
			if dist > 25 and dist < 32:
				image.set_pixel(x, y, Color(0.8, 0.8, 0.9, 1))
			if x > 35 and x < 45 and y > 35 and y < 45:
				image.set_pixel(x, y, Color(1, 1, 1, 1))
	
	var texture = ImageTexture.create_from_image(image)
	sprite = Sprite2D.new()
	sprite.texture = texture
	add_child(sprite)
	
	value_label = Label.new()
	value_label.text = "0.00 V"
	value_label.position = Vector2(20, 65)
	value_label.size = Vector2(45, 20)
	value_label.add_theme_font_size_override("font_size", 14)
	value_label.add_theme_color_override("font_color", Color.YELLOW)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(value_label)
	
	if not outline:
		outline = Sprite2D.new()
		var outline_image = Image.create(84, 84, false, Image.FORMAT_RGBA8)
		for x in range(84):
			for y in range(84):
				if x == 0 or x == 83 or y == 0 or y == 83:
					outline_image.set_pixel(x, y, Color.YELLOW)
		var outline_texture = ImageTexture.create_from_image(outline_image)
		outline.texture = outline_texture
		outline.visible = false
		add_child(outline)

func _setup_collision():
	var collision = CollisionShape2D.new()
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = 35
	collision.shape = circle_shape
	collision.position = Vector2(40, 40)
	add_child(collision)

func _setup_signals():
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	input_event.connect(_on_input_event)

func _on_mouse_entered():
	if not is_selected:
		modulate = Color(1.2, 1.2, 1.2)

func _on_mouse_exited():
	if not is_selected:
		modulate = Color.WHITE

func _on_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		clicked.emit(self)

func select():
	is_selected = true
	outline.visible = true
	modulate = Color(1.2, 1.2, 1.2)

func deselect():
	is_selected = false
	outline.visible = false
	modulate = Color.WHITE

func update_state(voltage: float):
	voltage_value = voltage
	var rounded = round(voltage_value * 100) / 100
	value_label.text = str(rounded) + " V"
	print("📊 Вольтметр ", name, " ОБНОВЛЁН: ", voltage_value, " V -> отображаем ", rounded, " V")

func get_connection_point() -> Vector2:
	return global_position + Vector2(40, 40)

func get_resistance() -> float:
	return 1000000.0

func get_rect() -> Rect2:
	return Rect2(position - Vector2(40, 40), Vector2(80, 80))
