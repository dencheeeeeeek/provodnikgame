extends Area2D
class_name Resistor

signal clicked

@export var resistance: float = 100.0
@export var component_id: int = 0

var is_selected: bool = false
var sprite: Sprite2D
var resistance_label: Label
var outline: Sprite2D

func _ready():
	_draw_resistor()
	_setup_collision()
	_setup_signals()

func _draw_resistor():
	if sprite:
		sprite.queue_free()
	if resistance_label:
		resistance_label.queue_free()
	
	var image = Image.create(90, 50, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	
	for x in range(90):
		for y in range(50):
			if x > 0 and x < 15 and y > 22 and y < 28:
				image.set_pixel(x, y, Color(0.8, 0.6, 0.2, 1))
			if x > 75 and x < 90 and y > 22 and y < 28:
				image.set_pixel(x, y, Color(0.8, 0.6, 0.2, 1))
			if x > 20 and x < 70 and y > 15 and y < 35:
				var color_intensity = clamp(resistance / 500.0, 0.3, 1.0)
				image.set_pixel(x, y, Color(0.6 * color_intensity, 0.3 * color_intensity, 0.1 * color_intensity, 1))
			if x > 30 and x < 40 and y > 15 and y < 35:
				image.set_pixel(x, y, Color(1, 0.5, 0, 1))
			if x > 45 and x < 55 and y > 15 and y < 35:
				image.set_pixel(x, y, Color(0, 0, 0, 1))
			if x > 60 and x < 65 and y > 15 and y < 35:
				image.set_pixel(x, y, Color(1, 0, 0, 1))
	
	var texture = ImageTexture.create_from_image(image)
	sprite = Sprite2D.new()
	sprite.texture = texture
	add_child(sprite)
	
	resistance_label = Label.new()
	if resistance >= 1000:
		resistance_label.text = str(resistance / 1000) + "kΩ"
	else:
		resistance_label.text = str(resistance) + "Ω"
	resistance_label.position = Vector2(30, 40)
	resistance_label.add_theme_font_size_override("font_size", 12)
	add_child(resistance_label)
	
	if not outline:
		outline = Sprite2D.new()
		var outline_image = Image.create(94, 54, false, Image.FORMAT_RGBA8)
		for x in range(94):
			for y in range(54):
				if x == 0 or x == 93 or y == 0 or y == 53:
					outline_image.set_pixel(x, y, Color.YELLOW)
		var outline_texture = ImageTexture.create_from_image(outline_image)
		outline.texture = outline_texture
		outline.visible = false
		add_child(outline)

func _setup_collision():
	var collision = CollisionShape2D.new()
	var rect_shape = RectangleShape2D.new()
	rect_shape.size = Vector2(80, 40)
	collision.shape = rect_shape
	collision.position = Vector2(45, 25)
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

func update_state(current: float):
	var voltage_drop = current * resistance
	set_meta("current", current)
	set_meta("voltage_drop", voltage_drop)
	
	if current > 0:
		var intensity = clamp(current * 10, 0.3, 1.0)
		sprite.modulate = Color(1, intensity, intensity)
		if resistance >= 1000:
			resistance_label.text = str(resistance / 1000) + "kΩ ⚡"
		else:
			resistance_label.text = str(resistance) + "Ω ⚡"
	else:
		sprite.modulate = Color.WHITE
		if resistance >= 1000:
			resistance_label.text = str(resistance / 1000) + "kΩ"
		else:
			resistance_label.text = str(resistance) + "Ω"

func get_connection_point() -> Vector2:
	return global_position + Vector2(45, 25)

func get_resistance() -> float:
	return resistance

func get_rect() -> Rect2:
	return Rect2(position - Vector2(45, 25), Vector2(90, 50))

func set_resistance(new_resistance: float):
	resistance = new_resistance
	_draw_resistor()
	update_state(get_meta("current", 0.0))
