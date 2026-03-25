extends TextureRect

signal item_dropped(world_position: Vector2, item_data: Dictionary)

var item_data := {
	"type": "unknown",
	"name": "Item",
	"power": 0.0
}
var is_dragging := false
var drag_data = null

func _ready():
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_DRAG

func _get_drag_data(at_position: Vector2):
	print("=== НАЧАЛО ПЕРЕТАСКИВАНИЯ: ", item_data["name"])
	is_dragging = true
	
	# Получаем GameWorld
	var root = get_tree().current_scene
	var gameworld = root.get_node_or_null("GameWorld")
	
	if not gameworld:
		print("GameWorld не найден, создаём...")
		gameworld = Node2D.new()
		gameworld.name = "GameWorld"
		root.add_child(gameworld)
	
	# Убеждаемся, что есть DropZone
	var drop_zone = gameworld.get_node_or_null("DropZone")
	if not drop_zone:
		print("Создаём DropZone")
		drop_zone = Node2D.new()
		drop_zone.name = "DropZone"
		
		# Путь к скрипту DropZone
		var script = load("res://script/DropZone.gd")
		if script:
			drop_zone.set_script(script)
			print("Скрипт DropZone.gd загружен")
		else:
			print("Скрипт DropZone.gd не найден")
		
		gameworld.add_child(drop_zone)
	
	drag_data = {"item_data": item_data.duplicate()}
	
	var preview = TextureRect.new()
	preview.texture = texture
	preview.size = size
	preview.modulate = Color(1, 1, 1, 0.7)
	set_drag_preview(preview)
	
	return drag_data

func _can_drop_data(at_position: Vector2, data) -> bool:
	return true

func _drop_data(at_position: Vector2, data):
	print("=== _drop_data ВЫЗВАН ===")
	_handle_drop(data)

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		if is_dragging:
			print("=== МЫШЬ ОТПУЩЕНА ===")
			if drag_data:
				_handle_drop(drag_data)
			is_dragging = false
			drag_data = null

func _handle_drop(data):
	if not data.has("item_data"):
		print("Нет данных предмета!")
		return
	
	var item = data["item_data"]
	print("Обработка сброса: ", item["name"])
	
	# Получаем позицию в мировых координатах
	var world_pos = _screen_to_world(get_global_mouse_position())
	print("Позиция сброса: ", world_pos)
	
	# Находим GameWorld
	var gameworld = get_tree().current_scene.get_node_or_null("GameWorld")
	if not gameworld:
		print("GameWorld не найден!")
		return
	
	# Вызываем spawn_item
	if gameworld.has_method("spawn_item"):
		print("Вызываем gameworld.spawn_item")
		gameworld.spawn_item(world_pos, item)
	else:
		print("У GameWorld НЕТ метода spawn_item!")
		print("Все методы GameWorld: ", gameworld.get_method_list())

func _screen_to_world(screen_position: Vector2) -> Vector2:
	var camera = get_viewport().get_camera_2d()
	if camera:
		var viewport_center = get_viewport().get_visible_rect().size / 2
		return camera.global_position + (screen_position - viewport_center) / camera.zoom
	return screen_position
