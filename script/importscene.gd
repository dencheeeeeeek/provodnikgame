extends Node2D

# Ссылки на узлы
@onready var games_container = $Control/GamesContainer
@onready var import_button = $Control/ButtonImport
@onready var back_button = $Control/ButtonToMainScene

var games_list_path = "res://user_games/imported_games.json"
var games_folder = "res://user_games/"

func _ready():
	create_games_folder()
	
	if import_button:
		import_button.pressed.connect(_on_import_pressed)
	
	if back_button:
		back_button.pressed.connect(_on_back_pressed)
	
	load_games_list()
	
	# Диагностика - показываем содержимое папки
	diagnose_folder()

func diagnose_folder():
	print("=== ДИАГНОСТИКА ===")
	print("Путь к папке игр: ", games_folder)
	print("Путь к JSON: ", games_list_path)
	
	var dir = DirAccess.open("res://")
	if dir:
		if dir.dir_exists("user_games"):
			print("Папка user_games существует")
			
			dir.open("res://user_games")
			dir.list_dir_begin()
			var file_name = dir.get_next()
			while file_name != "":
				print("Найдено в папке: ", file_name)
				file_name = dir.get_next()
			dir.list_dir_end()
		else:
			print("Папка user_games НЕ существует")
	
	if FileAccess.file_exists(games_list_path):
		var file = FileAccess.open(games_list_path, FileAccess.READ)
		var content = file.get_as_text()
		file.close()
		print("Содержимое JSON: ", content)
		
		var parsed = JSON.parse_string(content)
		print("Распарсенный JSON: ", parsed)
	else:
		print("JSON файл не существует")
	print("=== КОНЕЦ ДИАГНОСТИКИ ===")

func create_games_folder():
	var dir = DirAccess.open("res://")
	if dir and not dir.dir_exists("user_games"):
		dir.make_dir("user_games")
		print("Папка user_games создана в res://")

func _on_import_pressed():
	var file_dialog = FileDialog.new()
	file_dialog.title = "Выберите сцену игры (.tscn)"
	file_dialog.add_filter("*.tscn", "Godot Scene")
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	
	file_dialog.current_dir = "res://"
	
	file_dialog.file_selected.connect(_on_file_selected)
	add_child(file_dialog)
	file_dialog.popup_centered()

func _on_file_selected(path: String):
	print("Выбран файл: ", path)
	
	var file_name = path.get_file()
	var dest_path = games_folder + file_name
	
	if FileAccess.file_exists(dest_path):
		print("Файл уже существует в папке: ", dest_path)
		show_error("Игра с таким именем уже существует в папке!")
		return
	
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		var data = file.get_buffer(file.get_length())
		file.close()
		
		var dest_file = FileAccess.open(dest_path, FileAccess.WRITE)
		if dest_file:
			dest_file.store_buffer(data)
			dest_file.close()
			print("Файл скопирован: ", dest_path)
			
			save_game_to_list(file_name)
			load_games_list()
			show_success("Игра успешно импортирована!")
		else:
			print("Ошибка сохранения файла")
			show_error("Не удалось сохранить файл")
	else:
		print("Ошибка открытия файла")
		show_error("Не удалось открыть файл")

func save_game_to_list(file_name: String):
	var games = []
	
	if FileAccess.file_exists(games_list_path):
		var file = FileAccess.open(games_list_path, FileAccess.READ)
		var content = file.get_as_text()
		file.close()
		
		if content and not content.is_empty():
			var parsed = JSON.parse_string(content)
			if parsed != null:
				games = parsed
			else:
				games = []
		else:
			games = []
	
	var game_name = file_name.replace(".tscn", "")
	
	var exists = false
	for game in games:
		if game.get("file") == file_name:
			exists = true
			print("Игра уже есть в списке: ", game)
			break
	
	if not exists:
		games.append({
			"name": game_name,
			"file": file_name,
			"type": "imported",
			"imported_at": Time.get_datetime_string_from_system()
		})
		
		var save = FileAccess.open(games_list_path, FileAccess.WRITE)
		var json_string = JSON.stringify(games, "\t")
		save.store_string(json_string)
		save.close()
		print("✅ Импортированная игра добавлена в список: ", game_name)
	else:
		print("⚠️ Игра уже существует в списке, пропускаем добавление")

func load_games_list():
	if not games_container:
		print("Ошибка: GamesContainer не найден")
		return
	
	for child in games_container.get_children():
		child.queue_free()
	
	var games = []
	if FileAccess.file_exists(games_list_path):
		var file = FileAccess.open(games_list_path, FileAccess.READ)
		var content = file.get_as_text()
		file.close()
		
		if content and not content.is_empty():
			var parsed = JSON.parse_string(content)
			if parsed != null and typeof(parsed) == TYPE_ARRAY:
				games = parsed
			else:
				games = []
		else:
			games = []
	
	# ФИЛЬТРУЕМ: показываем только импортированные игры (type == "imported")
	var imported_games = []
	for game in games:
		if game.get("type") == "imported":
			imported_games.append(game)
	
	print("📦 Показываем только импортированные игры: ", imported_games.size())
	
	if imported_games.is_empty():
		show_empty_message()
		return
	
	var vertical_container = VBoxContainer.new()
	vertical_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vertical_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vertical_container.alignment = BoxContainer.ALIGNMENT_CENTER
	
	for game in imported_games:
		add_game_item(vertical_container, game)
	
	games_container.add_child(vertical_container)

func show_empty_message():
	var label = Label.new()
	label.text = "Нет импортированных игр\nНажмите 'Импорт' чтобы добавить"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color.GRAY)
	
	var center = CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center.add_child(label)
	
	games_container.add_child(center)

func add_game_item(parent: VBoxContainer, game: Dictionary):
	var item_container = HBoxContainer.new()
	item_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	item_container.add_theme_constant_override("separation", 15)
	
	var game_button = Button.new()
	game_button.text = game["name"]
	game_button.add_theme_font_size_override("font_size", 24)
	game_button.add_theme_color_override("font_color", Color.WHITE)
	game_button.add_theme_color_override("font_hover_color", Color.YELLOW)
	game_button.custom_minimum_size = Vector2(250, 50)
	game_button.pressed.connect(_on_game_selected.bind(game["file"]))
	
	var delete_button = Button.new()
	delete_button.text = "🗑️"
	delete_button.add_theme_font_size_override("font_size", 24)
	delete_button.add_theme_color_override("font_color", Color.RED)
	delete_button.add_theme_color_override("font_hover_color", Color.WHITE)
	delete_button.custom_minimum_size = Vector2(60, 50)
	delete_button.pressed.connect(_on_delete_game.bind(game["file"], game["name"]))
	
	item_container.add_child(game_button)
	item_container.add_child(delete_button)
	parent.add_child(item_container)
	
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
	var scene_path = games_folder + game_file
	if FileAccess.file_exists(scene_path):
		var dir = DirAccess.open(games_folder)
		if dir:
			dir.remove(game_file)
			print("Удален файл: ", scene_path)
	
	var games = []
	if FileAccess.file_exists(games_list_path):
		var file = FileAccess.open(games_list_path, FileAccess.READ)
		var content = file.get_as_text()
		file.close()
		
		if content and not content.is_empty():
			var parsed = JSON.parse_string(content)
			if parsed != null:
				games = parsed
	
	if games:
		for i in range(games.size() - 1, -1, -1):
			if games[i].get("file") == game_file:
				games.remove_at(i)
				break
		
		var save = FileAccess.open(games_list_path, FileAccess.WRITE)
		save.store_string(JSON.stringify(games, "\t"))
		save.close()
		print("Игра удалена из списка")
	
	load_games_list()

func _on_back_pressed():
	get_tree().change_scene_to_file("res://scene/mainscene.tscn")

func show_error(message: String):
	print("Ошибка: ", message)
	var label = Label.new()
	label.text = message
	label.add_theme_color_override("font_color", Color.RED)
	label.add_theme_font_size_override("font_size", 16)
	label.position = Vector2(100, 100)
	add_child(label)
	await get_tree().create_timer(2).timeout
	label.queue_free()

func show_success(message: String):
	print("Успех: ", message)
	var label = Label.new()
	label.text = message
	label.add_theme_color_override("font_color", Color.GREEN)
	label.add_theme_font_size_override("font_size", 16)
	label.position = Vector2(100, 100)
	add_child(label)
	await get_tree().create_timer(2).timeout
	label.queue_free()
