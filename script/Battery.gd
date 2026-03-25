extends BaseComponent
class_name Battery

@export var voltage := 9.0
@export var energy := 100.0

var sprite: Sprite2D
var charge_bar: ColorRect

func _ready():
	component_type = ComponentType.BATTERY
	power_value = voltage
	_setup_visual()

func _setup_visual():
	sprite = Sprite2D.new()
	sprite.texture = _create_temp_texture(Color.YELLOW)
	sprite.scale = Vector2(0.5, 0.5)
	add_child(sprite)
	
	charge_bar = ColorRect.new()
	charge_bar.size = Vector2(30, 5)
	charge_bar.position = Vector2(-15, -25)
	charge_bar.color = Color.GREEN
	add_child(charge_bar)
	
	_update_charge_bar()

func _create_temp_texture(color: Color) -> ImageTexture:
	var image = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	image.fill(color)
	for x in range(64):
		image.set_pixel(x, 0, Color.BLACK)
		image.set_pixel(x, 63, Color.BLACK)
		image.set_pixel(0, x, Color.BLACK)
		image.set_pixel(63, x, Color.BLACK)
	for i in range(20, 45):
		image.set_pixel(16, i, Color.BLACK)
		image.set_pixel(48, i, Color.BLACK)
	return ImageTexture.create_from_image(image)

func _update_charge_bar():
	if not charge_bar:
		return
	var charge_percent = energy / 100.0
	charge_bar.size.x = 30 * charge_percent
	if charge_percent < 0.2:
		charge_bar.color = Color.RED
	elif charge_percent < 0.5:
		charge_bar.color = Color.YELLOW
	else:
		charge_bar.color = Color.GREEN

func _on_power_updated():
	if is_powered and energy > 0:
		energy -= 0.01
		_update_charge_bar()
