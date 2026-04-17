extends Node

# Сигналы для связи с другими системами
signal level_complete
signal circuit_updated 

# База данных: Vector2i -> Dictionary {type, atlas_coords, powered, is_closed}
var grid_data = {}

# --- НАСТРОЙКА АТЛАСА ---
# Убедись, что эти координаты совпадают с твоим TileSet
var ATLAS_MAP = {
	Vector2i(0, 0): "battery", # Батарейка
	Vector2i(2, 0): "bulb",    # Лампочка
	Vector2i(1, 0): "switch",  # Выключатель
	Vector2i(3, 0): "wire"     # Провод (если есть отдельный тайл)
}

# 1. ПОДГОТОВКА И ИНТЕРФЕЙС
func connect_ui_buttons(menu_node: CanvasLayer):
	# Ищем кнопки по именам (как на твоем скриншоте)
	var btn_save = menu_node.find_child("SaveButton", true)
	var btn_load = menu_node.find_child("LoadButton", true)
	var btn_clear = menu_node.find_child("ClearButton", true)
	
	if btn_save: btn_save.pressed.connect(save_data)
	if btn_load: btn_load.pressed.connect(load_data)
	if btn_clear: btn_clear.pressed.connect(clear_all)
	print("🔌 Интерфейс успешно подключен к менеджеру")

# 2. СКАНЕР ДЛЯ РУЧНЫХ УРОВНЕЙ
func scan_tilemap(layer: TileMapLayer):
	grid_data.clear()
	var used_cells = layer.get_used_cells()
	for pos in used_cells:
		var atlas_pos = layer.get_cell_atlas_coords(pos)
		if ATLAS_MAP.has(atlas_pos):
			# Добавляем найденный предмет в нашу логическую сетку
			_add_to_logic_only(pos, {
				"type": ATLAS_MAP[atlas_pos],
				"atlas_coords": atlas_pos
			})
	update_circuit()

# 3. УПРАВЛЕНИЕ СЕТКОЙ (Добавление/Удаление)
func add_to_grid(pos: Vector2i, data: Dictionary):
	_add_to_logic_only(pos, data)
	update_circuit()

func _add_to_logic_only(pos: Vector2i, data: Dictionary):
	grid_data[pos] = data.duplicate()
	if not grid_data[pos].has("powered"): grid_data[pos]["powered"] = false
	if not grid_data[pos].has("is_closed"): grid_data[pos]["is_closed"] = true

func remove_from_grid(pos: Vector2i):
	if grid_data.has(pos):
		grid_data.erase(pos)
		update_circuit()

func toggle_switch(pos: Vector2i):
	if grid_data.has(pos) and grid_data[pos].type == "switch":
		grid_data[pos].is_closed = !grid_data[pos].is_closed
		update_circuit()

func clear_all():
	grid_data.clear()
	var layer = get_parent()
	if layer is TileMapLayer: layer.clear()
	update_circuit()

# 4. РАСЧЕТ ЦЕПИ (BFS)
func update_circuit():
	_reset_power_states()
	
	# Ищем источники энергии
	var sources = []
	for pos in grid_data:
		if grid_data[pos].type == "battery":
			sources.append(pos)
	
	# Распространяем энергию
	for s_pos in sources:
		_propagate_power(s_pos)
	
	_sync_visuals_with_logic()
	_check_victory_conditions()
	emit_signal("circuit_updated")

func _propagate_power(start_pos: Vector2i):
	var queue = [start_pos]
	var visited = []
	
	while queue.size() > 0:
		var current = queue.pop_front()
		if current in visited: continue
		visited.append(current)
		
		grid_data[current]["powered"] = true
		
		# Если выключатель разомкнут — ток прерывается
		if grid_data[current].type == "switch" and not grid_data[current].is_closed:
			continue
			
		var directions = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
		for dir in directions:
			var n_pos = current + dir
			if grid_data.has(n_pos):
				queue.append(n_pos)

func _reset_power_states():
	for pos in grid_data:
		grid_data[pos]["powered"] = false

# 5. ВИЗУАЛИЗАЦИЯ
func _sync_visuals_with_logic():
	var layer = get_parent()
	if not layer is TileMapLayer: return

	for pos in grid_data:
		var item = grid_data[pos]
		var coords = item.atlas_coords
		
		# Логика смены кадров (свечение лампы, положение выключателя)
		if item.type == "bulb" and item.powered:
			coords.y = 1 # Кадр включенной лампы ниже в атласе
		elif item.type == "switch":
			coords.x = 1 if item.is_closed else 2 # Пример разных кадров
			
		layer.set_cell(pos, 0, coords)

# 6. СОХРАНЕНИЕ И ЗАГРУЗКА (lv 0)
func save_data():
	var file = FileAccess.open("user://save_world.dat", FileAccess.WRITE)
	if file:
		# Преобразуем Vector2i в строку, так как JSON не ест векторы напрямую
		var save_dict = {}
		for pos in grid_data:
			save_dict[var_to_str(pos)] = grid_data[pos]
		file.store_string(JSON.stringify(save_dict))
		print("💾 Игра сохранена")

func load_data():
	if not FileAccess.file_exists("user://save_world.dat"): return
	
	var file = FileAccess.open("user://save_world.dat", FileAccess.READ)
	var json_data = JSON.parse_string(file.get_as_text())
	
	if json_data:
		grid_data.clear()
		for pos_str in json_data:
			var pos = str_to_var(pos_str)
			grid_data[pos] = json_data[pos_str]
		update_circuit()
		print("📂 Сохранение загружено")

func _check_victory_conditions():
	for pos in grid_data:
		if grid_data[pos].type == "bulb" and grid_data[pos].powered:
			print("🏆 ПОБЕДА!")
			emit_signal("level_complete")
