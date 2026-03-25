extends BaseComponent

@export var brightness := 0.0
@export var is_broken := false

var light: PointLight2D
var sprite: Sprite2D

func _ready():
	component_type = ComponentType.BULB
	_setup_visual()

func _setup_visual():
	sprite = Sprite2D.new()
	sprite.texture = preload("res://assets/bulb_off.png")  # Ваша текстура выключенной лампы
	sprite.scale = Vector2(0.5, 0.5)
	add_child(sprite)
	
	# Добавляем свет
	light = PointLight2D.new()
	light.energy = 0
	light.texture = preload("res://assets/light_texture.png")  # Текстура света
	light.scale = Vector2(2, 2)
	add_child(light)

func _on_power_updated():
	if is_powered and not is_broken:
		brightness = min(brightness + 0.1, 1.0)
		sprite.texture = preload("res://assets/bulb_on.png")
		light.energy = brightness * 2
	else:
		brightness = max(brightness - 0.05, 0.0)
		if brightness == 0:
			sprite.texture = preload("res://assets/bulb_off.png")
		light.energy = brightness

func break_bulb():
	is_broken = true
	_on_power_updated()
