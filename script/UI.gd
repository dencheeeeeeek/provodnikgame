extends CanvasLayer

# Загружаем скрипт DraggableItem
const DraggableItemScript = preload("res://script/DraggableItem.gd")

@onready var menu_panel = $MenuPanel
@onready var items_panel = $MenuPanel/ItemsPanel
@onready var status_panel = $MenuPanel/StatusPanel
@onready var circuit_status = $MenuPanel/StatusPanel/CircuitStatus
@onready var power_label = $MenuPanel/StatusPanel/PowerLabel

var current_tool := "select"

func _ready():
	_setup_panel_style()
	_setup_items()
	_update_tool_display()
	
	circuit_status.text = "🔌 ЦЕПЬ: РАЗОМКНУТА"
	power_label.text = "⚡ МОЩНОСТЬ: 0 Вт"

func _setup_panel_style():
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.7)
	style.set_corner_radius_all(10)
	items_panel.add_theme_stylebox_override("panel", style)
	
	var style2 = StyleBoxFlat.new()
	style2.bg_color = Color(0, 0, 0, 0.8)
	style2.set_corner_radius_all(10)
	status_panel.add_theme_stylebox_override("panel", style2)
	
	circuit_status.add_theme_font_size_override("font_size", 16)
	power_label.add_theme_font_size_override("font_size", 14)

func _setup_items():
	# Очищаем старые предметы
	for child in items_panel.get_children():
		child.queue_free()
	
	# Создаём вертикальный контейнер
	var vbox = VBoxContainer.new()
	vbox.name = "ItemsContainer"
	vbox.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 20)
	items_panel.add_child(vbox)
	
	var items = [
		{"type": "battery", "color": Color.YELLOW, "name": "🔋 Батарейка", "power": 9.0},
		{"type": "bulb", "color": Color.GRAY, "name": "💡 Лампочка", "power": 0.0},
		{"type": "switch", "color": Color.BLUE, "name": "🔘 Выключатель", "power": 0.0},
		{"type": "wire", "color": Color.ORANGE, "name": "⚡ Провод", "power": 0.0}
	]
	
	for item in items:
		# Контейнер для каждого предмета
		var item_box = VBoxContainer.new()
		item_box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		item_box.custom_minimum_size = Vector2(90, 100)
		item_box.add_theme_constant_override("separation", 5)
		
		# Создаём DraggableItem
		var draggable = DraggableItemScript.new()
		draggable.texture = _create_temp_texture(item.color, item["type"])
		draggable.size = Vector2(64, 64)
		draggable.item_data = item
		draggable.item_dropped.connect(_on_item_dropped)
		
		# Подпись
		var label = Label.new()
		label.text = item["name"]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 12)
		label.add_theme_color_override("font_color", Color.WHITE)
		
		item_box.add_child(draggable)
		item_box.add_child(label)
		vbox.add_child(item_box)

func _create_temp_texture(color: Color, type: String) -> Texture2D:
	var image = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	image.fill(color)
	
	# Рамка
	for x in range(64):
		image.set_pixel(x, 0, Color.BLACK)
		image.set_pixel(x, 63, Color.BLACK)
		image.set_pixel(0, x, Color.BLACK)
		image.set_pixel(63, x, Color.BLACK)
	
	# Символ
	match type:
		"battery":
			for i in range(20, 45):
				image.set_pixel(16, i, Color.BLACK)
				image.set_pixel(48, i, Color.BLACK)
			for i in range(10, 55):
				image.set_pixel(i, 32, Color.BLACK)
		"bulb":
			for x in range(20, 45):
				for y in range(20, 45):
					if Vector2(x, y).distance_to(Vector2(32, 32)) < 15:
						image.set_pixel(x, y, Color.WHITE)
		"switch":
			for x in range(25, 40):
				for y in range(25, 40):
					image.set_pixel(x, y, Color.WHITE)
		"wire":
			for i in range(15):
				var x = 10 + i * 3
				var y = 32 + (i % 3 - 1) * 5
				image.set_pixel(x, y, Color.WHITE)
				image.set_pixel(x, y+1, Color.WHITE)
	
	return ImageTexture.create_from_image(image)

func _on_item_dropped(world_position: Vector2, item_data: Dictionary):
	print("UI: Получен сигнал item_dropped для: ", item_data["name"])
	
	var gameworld = get_tree().current_scene.get_node_or_null("GameWorld")
	
	if not gameworld:
		print("Ошибка: GameWorld не найден!")
		return
	
	if item_data["type"] == "wire":
		current_tool = "wire"
		_update_tool_display()
		_show_tooltip("🔌 Режим провода: нажмите на компонент и протяните к другому")
		print("Активирован режим провода")
	else:
		print("Создаём предмет: ", item_data["name"], " на позиции: ", world_position)
		gameworld.spawn_item(world_position, item_data)

func update_circuit_status(status: Dictionary):
	if not circuit_status or not power_label:
		return
	
	var is_closed = status.get("circuit_closed", false)
	var total_power = status.get("total_power", 0.0)
	var powered_count = status.get("powered_count", 0)
	
	circuit_status.text = "⚡ ЦЕПЬ: " + ("ЗАМКНУТА" if is_closed else "РАЗОМКНУТА")
	power_label.text = "💪 МОЩНОСТЬ: %.1f Вт\n🔌 ЭЛЕМЕНТОВ: %d" % [total_power, powered_count]
	
	if is_closed:
		circuit_status.add_theme_color_override("font_color", Color.GREEN)
	else:
		circuit_status.add_theme_color_override("font_color", Color.RED)

func _update_tool_display():
	match current_tool:
		"wire":
			_show_tooltip("🔌 Режим провода: нажмите на компонент и протяните")
		"delete":
			_show_tooltip("🗑️ Нажмите на компонент, чтобы удалить")

func _show_tooltip(text: String):
	var tooltip = Label.new()
	tooltip.text = text
	tooltip.position = Vector2(20, 100)
	tooltip.add_theme_color_override("font_color", Color.WHITE)
	tooltip.add_theme_color_override("font_outline_color", Color.BLACK)
	tooltip.add_theme_font_size_override("font_size", 14)
	tooltip.add_theme_constant_override("outline_size", 2)
	add_child(tooltip)
	
	var tween = create_tween()
	tween.tween_property(tooltip, "modulate:a", 0, 2.5)
	tween.tween_callback(tooltip.queue_free)

func get_current_tool() -> String:
	return current_tool
