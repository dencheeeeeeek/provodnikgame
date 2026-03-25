# Бесконечное поле с подгрузкой чанков
extends TileMapLayer

const CHUNK_SIZE := 16  # Размер чанка в тайлах
const LOAD_DISTANCE := 3 # Дистанция подгрузки чанков

var loaded_chunks := {}
var camera: Camera2D

func _ready():
	camera = get_viewport().get_camera_2d()
	# Загружаем начальные чанки
	_update_chunks()

func _process(delta):
	if camera:
		_update_chunks()

func _update_chunks():
	if not camera:
		return
	
	# Определяем чанк, в котором находится камера
	var camera_chunk = _world_to_chunk(camera.position)
	
	# Загружаем чанки вокруг камеры
	for x in range(camera_chunk.x - LOAD_DISTANCE, camera_chunk.x + LOAD_DISTANCE + 1):
		for y in range(camera_chunk.y - LOAD_DISTANCE, camera_chunk.y + LOAD_DISTANCE + 1):
			var chunk_pos = Vector2i(x, y)
			if not loaded_chunks.has(chunk_pos):
				_load_chunk(chunk_pos)
	
	# Выгружаем дальние чанки (опционально)
	_unload_distant_chunks(camera_chunk)

func _world_to_chunk(world_pos: Vector2) -> Vector2i:
	return Vector2i(
		floori(world_pos.x / (CHUNK_SIZE * tile_set.tile_size.x)),
		floori(world_pos.y / (CHUNK_SIZE * tile_set.tile_size.y))
	)

func _load_chunk(chunk_pos: Vector2i):
	loaded_chunks[chunk_pos] = true
	
	# Вычисляем мировые координаты чанка
	var chunk_origin = Vector2i(
		chunk_pos.x * CHUNK_SIZE,
		chunk_pos.y * CHUNK_SIZE
	)
	
	# Генерируем тайлы в чанке
	for x in range(CHUNK_SIZE):
		for y in range(CHUNK_SIZE):
			var tile_pos = chunk_origin + Vector2i(x, y)
			# Здесь ваша логика генерации тайлов
			# Например, случайная генерация:
			if _should_have_tile(tile_pos):
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
	# Вычисляем границы чанка
	var chunk_origin = Vector2i(
		chunk_pos.x * CHUNK_SIZE,
		chunk_pos.y * CHUNK_SIZE
	)
	
	# Очищаем тайлы в чанке
	for x in range(CHUNK_SIZE):
		for y in range(CHUNK_SIZE):
			var tile_pos = chunk_origin + Vector2i(x, y)
			erase_cell(tile_pos)
	
	loaded_chunks.erase(chunk_pos)
	print("Выгружен чанк: ", chunk_pos)

func _should_have_tile(tile_pos: Vector2i) -> bool:
	# Пример простой генерации: шум Перлина или случайность
	# Используйте noise или другую логику
	return (tile_pos.x + tile_pos.y) % 3 != 0  # Простой паттерн
