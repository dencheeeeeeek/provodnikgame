extends Area2D
class_name Switch

signal clicked
signal toggled(is_on)

@export var is_on: bool = true
@export var component_id: int = 0

var is_selected: bool = false
var sprite: Sprite2D
var outline: Sprite2D
var state_label: Label

func _ready():
	print("🔘 Switch _ready() вызван для ", name, ", is_on = ", is_on)
	_draw_switch()
	_setup_collision()
	_setup_signals()
	input_event.connect(_on_click)
	set_meta("is_on", is_on)

func _draw_switch():
	if sprite:
		sprite.queue_free()
	if state_label:
		state_label.queue_free()
	
	var image = Image.create(70, 70, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	
	for x in range(70):
		for y in range(70):
			if x > 15 and x < 55 and y > 20 and y < 50:
				image.set_pixel(x, y, Color(0.4, 0.4, 0.4, 1))
			if x > 20 and x < 50 and y > 25 and y < 45:
				image.set_pixel(x, y, Color(0.2, 0.2, 0.2, 1))
			
			if is_on:
				if x > 28 and x < 42 and y > 12 and y < 28:
					image.set_pixel(x, y, Color(0, 1, 0, 1))
				if x > 33 and x < 37 and y > 28 and y < 35:
					image.set_pixel(x, y, Color(0, 0.5, 0, 1))
			else:
				if x > 28 and x < 42 and y > 42 and y < 58:
					image.set_pixel(x, y, Color(1, 0, 0, 1))
				if x > 33 and x < 37 and y > 35 and y < 42:
					image.set_pixel(x, y, Color(0.5, 0, 0, 1))
			
			if x > 50 and x < 58 and y > 30 and y < 40:
				if is_on:
					image.set_pixel(x, y, Color(0, 1, 0, 0.8))
				else:
					image.set_pixel(x, y, Color(0.5, 0, 0, 0.8))
	
	var texture = ImageTexture.create_from_image(image)
	sprite = Sprite2D.new()
	sprite.texture = texture
	add_child(sprite)
	
	state_label = Label.new()
	if is_on:
		state_label.text = "ON"
		state_label.add_theme_color_override("font_color", Color.GREEN)
	else:
		state_label.text = "OFF"
		state_label.add_theme_color_override("font_color", Color.RED)
	state_label.position = Vector2(50, 30)
	state_label.add_theme_font_size_override("font_size", 12)
	add_child(state_label)
	
	if not outline:
		outline = Sprite2D.new()
		var outline_image = Image.create(74, 74, false, Image.FORMAT_RGBA8)
		for x in range(74):
			for y in range(74):
				if x == 0 or x == 73 or y == 0 or y == 73:
					outline_image.set_pixel(x, y, Color.YELLOW)
		var outline_texture = ImageTexture.create_from_image(outline_image)
		outline.texture = outline_texture
		outline.visible = false
		add_child(outline)

func _setup_collision():
	var collision = CollisionShape2D.new()
	var rect_shape = RectangleShape2D.new()
	rect_shape.size = Vector2(60, 50)
	collision.shape = rect_shape
	collision.position = Vector2(35, 35)
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

func _on_click(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		toggle()
		clicked.emit(self)

func toggle():
	is_on = !is_on
	_draw_switch()
	toggled.emit(is_on)
	set_meta("is_on", is_on)

	var tree = get_tree()
	if tree:
		var main_scene = tree.current_scene
		if main_scene and main_scene.has_method("update_simulation"):
			main_scene.update_simulation()
			print("🔄 Выключатель ", name, " переключен в положение: ", "ON" if is_on else "OFF")
		else:
			var nodes = tree.get_nodes_in_group("circuit")
			for node in nodes:
				if node.has_method("update_simulation"):
					node.update_simulation()
					print("🔄 Выключатель ", name, " (через группу) переключен в положение: ", "ON" if is_on else "OFF")
					break
	else:
		print("⚠️ Выключатель ", name, " - get_tree() вернул null!")

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

func get_connection_point() -> Vector2:
	return global_position + Vector2(35, 35)

func get_resistance() -> float:
	return 0.0 if is_on else 999999.0

func is_switch_on() -> bool:
	return is_on

func get_rect() -> Rect2:
	return Rect2(position - Vector2(35, 35), Vector2(70, 70))
