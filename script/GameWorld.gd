extends Node2D

@onready var objects_container = $Objects
@onready var wires_container = $Wires
@onready var tilemap = $Field
@onready var camera = $Camera2D

var components: Array = []

func _ready():
	print("GameWorld: _ready() вызван")
	_setup_tilemap()

func _setup_tilemap():
	print("GameWorld: Настройка поля")
	if not tilemap:
		print("Ошибка: Field (TileMapLayer) не найден!")
		return
	
	if not tilemap.tile_set:
		_create_temp_tileset()
	
	# Генерируем поле
	for x in range(-30, 30):
		for y in range(-30, 30):
			tilemap.set_cell(Vector2i(x, y), 0, Vector2i(0, 0))
	print("GameWorld: Поле создано")

func _create_temp_tileset():
	print("GameWorld: Создаём временный TileSet")
	var tileset = TileSet.new()
	var image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.2, 0.5, 0.2))
	var texture = ImageTexture.create_from_image(image)
	var source = TileSetAtlasSource.new()
	source.texture = texture
	source.create_tile(Vector2i(0, 0))
	tileset.add_source(source)
	tilemap.tile_set = tileset

# ГЛАВНЫЙ МЕТОД ДЛЯ СОЗДАНИЯ ПРЕДМЕТОВ
func spawn_item(world_position: Vector2, item_data: Dictionary):
	print("=== GameWorld.spawn_item ВЫЗВАН ===")
	print("Предмет: ", item_data["name"])
	print("Тип: ", item_data["type"])
	print("Позиция: ", world_position)
	
	# Загружаем скрипты компонентов
	var BatteryScript = preload("res://script/Battery.gd")
	var BulbScript = preload("res://script/Bulb.gd")
	var SwitchScript = preload("res://script/Switch.gd")
	
	var component = null
	
	match item_data["type"]:
		"battery":
			component = BatteryScript.new()
			component.voltage = item_data.get("power", 9.0)
			component.energy = 100.0
			print("Создана батарейка")
		
		"bulb":
			component = BulbScript.new()
			component.is_broken = false
			print("Создана лампочка")
		
		"switch":
			component = SwitchScript.new()
			component.is_closed = false
			print("Создан выключатель")
		
		_:
			print("Неизвестный тип предмета: ", item_data["type"])
			return
	
	if component:
		component.position = world_position
		objects_container.add_child(component)
		components.append(component)
		print("Компонент добавлен в Objects, всего компонентов: ", components.size())

func _on_circuit_updated():
	_update_ui_status()

func _update_ui_status():
	var ui = get_tree().current_scene.get_node_or_null("UI")
	if ui and ui.has_method("update_circuit_status"):
		ui.update_circuit_status(_get_circuit_status())

func _get_circuit_status() -> Dictionary:
	var powered_count = 0
	var total_power = 0.0
	
	for component in components:
		if component.is_powered:
			powered_count += 1
			total_power += component.power_value
	
	return {
		"circuit_closed": _is_any_circuit_closed(),
		"total_power": total_power,
		"powered_count": powered_count
	}

func _is_any_circuit_closed() -> bool:
	for component in components:
		if component.component_type == 0:  # BATTERY
			var circuit = component.get_all_connected_components()
			if circuit.size() > 1:
				return true
	return false
