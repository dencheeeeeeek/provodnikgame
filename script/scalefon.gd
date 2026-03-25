extends Control

@export var menu_size = Vector2(274, 110)  # размер вашей картинки

func _ready():
	center_background()
	get_viewport().connect("size_changed", Callable(self, "center_background"))

func center_background():
	var window_size = get_viewport().get_visible_rect().size
	var background = $Background  # ваш TextureRect с картинкой
	
	# Вычисляем масштаб
	var scale = min(
		window_size.x / menu_size.x,
		window_size.y / menu_size.y
	)
	
	# Масштабируем
	background.scale = Vector2(scale, scale)
	
	# Центрируем
	background.position = (window_size - menu_size * scale) / 2
