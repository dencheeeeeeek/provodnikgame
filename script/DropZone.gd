extends Node2D

func _ready():
	print("DropZone: Узел создан и готов принимать сбросы")
	add_to_group("drop_zones")

func _can_drop_data(_position: Vector2, _data) -> bool:
	print("DropZone: _can_drop_data - разрешаем сброс")
	return true

func _drop_data(position: Vector2, data):
	print("DropZone: _drop_data вызван на позиции ", position)
	if data.has("item_data"):
		var gameworld = get_parent()
		if gameworld and gameworld.has_method("spawn_item"):
			print("DropZone: вызываем gameworld.spawn_item")
			gameworld.spawn_item(position, data["item_data"])
		else:
			print("DropZone: у Gameworld нет метода spawn_item!")
