extends Area2D
class_name Bulb

signal clicked

@export var brightness: float = 0.0
@export var component_id: int = 0

var is_selected: bool = false
var sprite: Sprite2D
var light_point: PointLight2D
var outline: Sprite2D
var is_lit: bool = false

func _ready():
	_draw_bulb()
	_setup_collision()
	_setup_signals()

func _draw_bulb():
	if sprite:
		sprite.queue_free()
	if light_point:
		light_point.queue_free()
	if outline:
		outline.queue_free()
	
	var image = Image.create(60, 60, false, Image.FORMAT_RGBA8)
	
	for x in range(60):
		for y in range(60):
			var dx = x - 30
			var dy = y - 25
			var distance = sqrt(dx*dx + dy*dy)
			
			if distance < 20:
				var alpha = 0.8
				image.set_pixel(x, y, Color(1, 0.9, 0.3, alpha))
			elif x > 20 and x < 40 and y > 45 and y < 55:
				image.set_pixel(x, y, Color(0.5, 0.5, 0.5))
			elif x > 28 and x < 32 and y > 20 and y < 35:
				image.set_pixel(x, y, Color(1, 0.5, 0))
	
	var texture = ImageTexture.create_from_image(image)
	sprite = Sprite2D.new()
	sprite.texture = texture
	add_child(sprite)
	
	light_point = PointLight2D.new()
	light_point.energy = 0
	light_point.texture = texture
	light_point.texture_scale = 0.5
	add_child(light_point)
	
	outline = Sprite2D.new()
	var outline_image = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	for x in range(64):
		for y in range(64):
			if x == 0 or x == 63 or y == 0 or y == 63:
				outline_image.set_pixel(x, y, Color.YELLOW)
	var outline_texture = ImageTexture.create_from_image(outline_image)
	outline.texture = outline_texture
	outline.visible = false
	add_child(outline)

func _setup_collision():
	var collision = CollisionShape2D.new()
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = 25
	collision.shape = circle_shape
	collision.position = Vector2(30, 30)
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
	brightness = clamp(current * 2, 0, 1)
	light_point.energy = brightness * 1.5
	
	if brightness > 0.1:
		is_lit = true
		sprite.modulate = Color(1, 1 - brightness * 0.3, 1 - brightness * 0.5)
	else:
		is_lit = false
		sprite.modulate = Color.WHITE

func get_connection_point() -> Vector2:
	return global_position + Vector2(30, 30)

func get_rect() -> Rect2:
	return Rect2(position - Vector2(30, 30), Vector2(60, 60))
