extends TileMapLayer

const CHUNK_SIZE = 16
const LOAD_DISTANCE = 2
var loaded_chunks = {}

@onready var camera = get_viewport().get_camera_2d()
var CircuitManager

func _ready():
	var manager_script = load("res://script/CircuitManager.gd")
	if manager_script:
		CircuitManager = manager_script.new()
		add_child(CircuitManager)
	
	setup_current_level()

func setup_current_level():
	if not CircuitManager: return
	var lv = GameState.current_level
	
	if lv == 0:
		CircuitManager.load_data()
	else:
		# ВАЖНО: Сканируем то, что ты нарисовал в сцене руками!
		CircuitManager.scan_tilemap(self)

func _process(_delta):
	if camera and GameState.current_level == 0:
		_update_chunks()

# ... (остальные функции чанков из твоего кода без изменений)
# --- 3. ЛОГИКА СИСТЕМЫ ЧАНКОВ (Полная версия) ---

func _update_chunks():
	if not camera: return
	
	# Определяем текущий чанк камеры
	var camera_chunk = _world_to_chunk(camera.position)
	
	# Загружаем чанки в радиусе видимости
	for x in range(camera_chunk.x - LOAD_DISTANCE, camera_chunk.x + LOAD_DISTANCE + 1):
		for y in range(camera_chunk.y - LOAD_DISTANCE, camera_chunk.y + LOAD_DISTANCE + 1):
			var chunk_pos = Vector2i(x, y)
			if not loaded_chunks.has(chunk_pos):
				_load_chunk(chunk_pos)
	
	# Выгружаем то, что слишком далеко
	_unload_distant_chunks(camera_chunk)

func _world_to_chunk(world_pos: Vector2) -> Vector2i:
	if not tile_set: return Vector2i.ZERO
	# Переводим мировые пиксели в координаты чанков
	return Vector2i(
		floori(world_pos.x / (CHUNK_SIZE * tile_set.tile_size.x)),
		floori(world_pos.y / (CHUNK_SIZE * tile_set.tile_size.y))
	)

func _load_chunk(chunk_pos: Vector2i):
	loaded_chunks[chunk_pos] = true
	
	# Генерируем фоновую плитку ТОЛЬКО в свободном режиме
	if GameState.current_level == 0:
		var chunk_origin = chunk_pos * CHUNK_SIZE
		for x in range(CHUNK_SIZE):
			for y in range(CHUNK_SIZE):
				var tile_pos = chunk_origin + Vector2i(x, y)
				if _should_have_tile(tile_pos):
					# Ставим фоновый тайл (0,0) из твоего TileSet
					set_cell(tile_pos, 0, Vector2i(0, 0))
	
	print("Загружен чанк: ", chunk_pos)

func _unload_distant_chunks(camera_chunk: Vector2i):
	var to_unload := []
	for chunk_pos in loaded_chunks.keys():
		var distance = abs(chunk_pos.x - camera_chunk.x) + abs(chunk_pos.y - camera_chunk.y)
		if distance > LOAD_DISTANCE + 1:
			to_unload.append(chunk_pos)
	
	for chunk_pos in to_unload:
		_unload_chunk(chunk_pos)

func _unload_chunk(chunk_pos: Vector2i):
	# Очищаем ячейки в памяти чанка (только для свободного режима)
	if GameState.current_level == 0:
		var chunk_origin = chunk_pos * CHUNK_SIZE
		for x in range(CHUNK_SIZE):
			for y in range(CHUNK_SIZE):
				var tile_pos = chunk_origin + Vector2i(x, y)
				erase_cell(tile_pos)
	
	loaded_chunks.erase(chunk_pos)

func _should_have_tile(tile_pos: Vector2i) -> bool:
	# Простой алгоритм для создания "узора" на фоне
	return (tile_pos.x + tile_pos.y) % 3 != 0
