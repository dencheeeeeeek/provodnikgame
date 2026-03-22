extends Node2D

# Ссылки на узлы
@onready var games_container = $Control/GamesContainer
@onready var import_button = $Control/ButtonImport
@onready var back_button = $Control/ButtonToMainScene

var games_list_path = "user://imported_games.json"
var games_folder = "user://games/"

func _ready():
	create_games_folder()
	
	if import_button:
		import_button.pressed.connect(_on_import_pressed)
	
	if back_button:
		back_button.pressed.connect(_on_back_pressed)
	
	load_games_list()

func create_games_folder():
	var dir = DirAccess.open("user://")
	if dir and not dir.dir_exists("games"):
		dir.make_dir("games")
		print("Папка для игр создана")

func _on_import_pressed():
	var file_dialog = FileDialog.new()
	file_dialog.title = "Выберите сцену игры (.tscn)"
	file_dialog.add_filter("*.tscn", "Godot Scene")
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	
	file_dialog.file_selected.connect(_on_file_selected)
	add_child(file_dialog)
	file_dialog.popup_centered()

func _on_file_selected(path: String):
	print("Выбран файл: ", path)
	
	var file_name = path.get_file()
	var dest_path = games_folder + file_name
	
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		var data = file.get_buffer(file.get_length())
		file.close()
		
		var dest_file = FileAccess.open(dest_path, FileAccess.WRITE)
		if dest_file:
			dest_file.store_buffer(data)
			dest_file.close()
			print("Игра импортирована: ", file_name)
			
			save_game_to_list(file_name)
			load_games_list()
		else:
			print("Ошибка сохранения файла")
	else:
		print("Ошибка открытия файла")

func save_game_to_list(file_name: String):
	var games = []
	
	if FileAccess.file_exists(games_list_path):
		var file = FileAccess.open(games_list_path, FileAccess.READ)
		var content = file.get_as_text()
		file.close()
		games = JSON.parse_string(content)
	
	if games == null:
		games = []
	
	var game_name = file_name.replace(".tscn", "")
	var exists = false
	for game in games:
		if game["file"] == file_name:
			exists = true
			break
	
	if not exists:
		games.append({
			"name": game_name,
			"file": file_name
		})
		
		var save = FileAccess.open(games_list_path, FileAccess.WRITE)
		save.store_string(JSON.stringify(games))
		save.close()
		print("Игра добавлена в список")

func load_games_list():
	if not games_container:
		print("Ошибка: GamesContainer не найден")
		return
	
	# Очищаем контейнер
	for child in games_container.get_children():
		child.queue_free()
	
	# Загружаем список игр
	var games = []
	if FileAccess.file_exists(games_list_path):
		var file = FileAccess.open(games_list_path, FileAccess.READ)
		var content = file.get_as_text()
		file.close()
		games = JSON.parse_string(content)
	
	if games == null or games.is_empty():
		# Если игр нет - ничего не показываем
		return
	
	# Создаем вертикальный контейнер для списка
	var vertical_container = VBoxContainer.new()
	vertical_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER  # Центрируем
	vertical_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vertical_container.alignment = BoxContainer.ALIGNMENT_CENTER  # Центрируем содержимое
	
	# Добавляем каждую игру
	for game in games:
		add_game_item(vertical_container, game)
	
	games_container.add_child(vertical_container)

func add_game_item(parent: VBoxContainer, game: Dictionary):
	# Создаем горизонтальный контейнер
	var item_container = HBoxContainer.new()
	item_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER  # Центрируем
	item_container.add_theme_constant_override("separation", 15)  # Отступ между кнопками
	
	# Стилизуем кнопку игры
	var game_button = Button.new()
	game_button.text = game["name"]
	game_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	# Настройка стиля кнопки
	game_button.add_theme_font_size_override("font_size", 24)  # Размер шрифта
	game_button.add_theme_color_override("font_color", Color.WHITE)
	game_button.add_theme_color_override("font_hover_color", Color.YELLOW)
	game_button.add_theme_color_override("font_pressed_color", Color.ORANGE)
	
	# Настройка размера кнопки
	game_button.custom_minimum_size = Vector2(250, 50)  # Минимальный размер
	game_button.pressed.connect(_on_game_selected.bind(game["file"]))
	
	# Стилизуем кнопку удаления
	var delete_button = Button.new()
	delete_button.text = "🗑️"  # Иконка корзины
	delete_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	# Настройка стиля кнопки удаления
	delete_button.add_theme_font_size_override("font_size", 24)
	delete_button.add_theme_color_override("font_color", Color.RED)
	delete_button.add_theme_color_override("font_hover_color", Color.WHITE)
	delete_button.custom_minimum_size = Vector2(60, 50)
	delete_button.pressed.connect(_on_delete_game.bind(game["file"], game["name"]))
	
	# Добавляем кнопки в контейнер
	item_container.add_child(game_button)
	item_container.add_child(delete_button)
	
	# Добавляем контейнер в вертикальный список
	parent.add_child(item_container)
	
	# Добавляем разделитель между играми
	if parent.get_child_count() > 0:
		var separator = HSeparator.new()
		separator.custom_minimum_size = Vector2(300, 2)
		parent.add_child(separator)

func _on_game_selected(game_file: String):
	print("Запуск игры: ", game_file)
	var scene_path = games_folder + game_file
	
	if FileAccess.file_exists(scene_path):
		var scene = load(scene_path)
		if scene:
			get_tree().change_scene_to_packed(scene)
		else:
			print("Ошибка загрузки сцены")
			show_error("Не удалось загрузить игру")
	else:
		print("Файл не найден: ", scene_path)
		show_error("Файл игры не найден")

func _on_delete_game(game_file: String, game_name: String):
	# Удаляем файл игры
	var scene_path = games_folder + game_file
	if FileAccess.file_exists(scene_path):
		DirAccess.remove_absolute(scene_path)
		print("Удален файл: ", scene_path)
	
	# Удаляем из списка
	var games = []
	if FileAccess.file_exists(games_list_path):
		var file = FileAccess.open(games_list_path, FileAccess.READ)
		var content = file.get_as_text()
		file.close()
		games = JSON.parse_string(content)
	
	if games:
		for i in range(games.size() - 1, -1, -1):
			if games[i]["file"] == game_file:
				games.remove_at(i)
				break
		
		var save = FileAccess.open(games_list_path, FileAccess.WRITE)
		save.store_string(JSON.stringify(games))
		save.close()
	
	# Обновляем список
	load_games_list()

func _on_back_pressed():
	get_tree().change_scene_to_file("res://scene/mainscene.tscn")

func show_error(message: String):
	print("Ошибка: ", message)
	var error_label = Label.new()
	error_label.text = message
	error_label.add_theme_color_override("font_color", Color.RED)
	add_child(error_label)
	await get_tree().create_timer(2).timeout
	error_label.queue_free()
