extends BaseComponent

@export var is_closed := false
var sprite: Sprite2D

func _ready():
	component_type = ComponentType.SWITCH
	_setup_visual()

func _setup_visual():
	sprite = Sprite2D.new()
	_update_sprite()
	sprite.scale = Vector2(0.5, 0.5)
	add_child(sprite)
	
	# Добавляем Area2D для клика
	var area = Area2D.new()
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(32, 32)
	collision.shape = shape
	area.add_child(collision)
	area.input_event.connect(_on_clicked)
	add_child(area)

func _on_clicked(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		toggle()

func toggle():
	is_closed = !is_closed
	_update_sprite()
	_update_power()

func _update_sprite():
	if is_closed:
		sprite.texture = preload("res://assets/switch_on.png")
	else:
		sprite.texture = preload("res://assets/switch_off.png")

func _is_circuit_closed() -> bool:
	# Переопределяем проверку замыкания цепи
	if not is_closed:
		return false
	return super()
