extends Node

# Сигналы для уведомления UI и других систем
signal level_complete
signal circuit_updated # Вызывается при любом изменении в цепи

# Главная база данных: Vector2i (координата) -> Dictionary (данные предмета)
var grid_data = {}

# 1. ДОБАВЛЕНИЕ ПРЕДМЕТА
func add_to_grid(pos: Vector2i, data: Dictionary):
	# Клонируем данные, чтобы изменения одного предмета не влияли на другие
	grid_data[pos] = data.duplicate()
	# Добавляем базовые свойства, если их нет
	if not grid_data[pos].has("powered"): grid_data[pos]["powered"] = false
	if not grid_data[pos].has("is_closed"): grid_data[pos]["is_closed"] = true # Для выключателей
	
	update_circuit()

# 2. УДАЛЕНИЕ ПРЕДМЕТА
func remove_from_grid(pos: Vector2i):
	if grid_data.has(pos):
		grid_data.erase(pos)
		update_circuit()

# 3. ПЕРЕКЛЮЧЕНИЕ ВЫКЛЮЧАТЕЛЯ
# Вызывай эту функцию, если игрок кликнул на уже стоящий выключатель
func toggle_switch(pos: Vector2i):
	if grid_data.has(pos) and grid_data[pos].type == "switch":
		grid_data[pos].is_closed = !grid_data[pos].is_closed
		update_circuit()

# 4. ГЛАВНЫЙ ЦИКЛ РАСЧЕТА ТОКА
func update_circuit():
	# Шаг A: Сбрасываем энергию у всех приборов
	_reset_power_states()
	
	# Шаг B: Ищем все батарейки (источники)
	var sources = []
	for pos in grid_data:
		if grid_data[pos].type == "battery":
			sources.append(pos)
	
	# Шаг C: Распространяем ток от каждой батарейки
	for s_pos in sources:
		_propagate_power(s_pos)
	
	# Шаг D: Обновляем картинки на поле
	_sync_visuals_with_logic()
	
	# Шаг E: Проверяем, пройден ли уровень
	_check_victory_conditions()
	
	emit_signal("circuit_updated")

# Внутренняя функция: поиск пути тока (BFS алгоритм)
func _propagate_power(start_pos: Vector2i):
	var queue = [start_pos]
	var visited = []
	
	while queue.size() > 0:
		var current = queue.pop_front()
		if current in visited: continue
		visited.append(current)
		
		# Если мы попали сюда — значит в этой клетке есть ток
		grid_data[current]["powered"] = true
		
		# ОСОБАЯ ЛОГИКА: Если это разомкнутый выключатель — ток дальше не идет
		if grid_data[current].type == "switch" and not grid_data[current].is_closed:
			continue
			
		# Проверяем соседей (куда ток может течь дальше)
		var directions = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
		for dir in directions:
			var neighbor_pos = current + dir
			if grid_data.has(neighbor_pos):
				queue.append(neighbor_pos)

# Сброс всех состояний перед новым расчетом
func _reset_power_states():
	for pos in grid_data:
		grid_data[pos]["powered"] = false

# Синхронизация: меняем тайлы в зависимости от наличия тока
func _sync_visuals_with_logic():
	# Ищем наш основной слой TileMap в текущей сцене
	var main_scene = get_tree().current_scene
	var tilemap_layer = main_scene.find_child("createpole", true) # Ищем по имени скрипта/узла
	
	if not tilemap_layer: return

	for pos in grid_data:
		var item = grid_data[pos]
		var atlas_coords = item.atlas_coords
		
		# Если прибор запитан — меняем его вид (сдвигаем на 1 клетку вниз в атласе)
		if item.powered:
			if item.type == "bulb" or item.type == "amperemeter" or item.type == "voltmeter":
				atlas_coords.y += 1 # Включаем "свечение" или "стрелку"
		
		# Если это выключатель, его вид зависит от is_closed
		if item.type == "switch":
			if not item.is_closed:
				atlas_coords.x += 1 # Допустим, разомкнутый выключатель справа от замкнутого
		
		# Применяем изменения на TileMap (Слой 1 — предметы)
		tilemap_layer.set_cell(pos, 1, atlas_coords)

# Проверка победы (для Уровня 1: должна гореть хотя бы одна лампа)
func _check_victory_conditions():
	var bulbs_on = 0
	for pos in grid_data:
		if grid_data[pos].type == "bulb" and grid_data[pos].powered:
			bulbs_on += 1
	
	if bulbs_on > 0:
		print("--- СИСТЕМА: ЦЕПЬ ЗАМКНУТА, ПОБЕДА! ---")
		emit_signal("level_complete")
