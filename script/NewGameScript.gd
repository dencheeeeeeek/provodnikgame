extends Node2D

# Ссылки на узлы
@onready var games_container = $Control/GamesContainer
@onready var import_button = $Control/ButtonImport
@onready var back_button = $Control/ButtonToMainScene
@onready var new_game_button = $Control/ButtonNewGame

# Пути
var games_list_path = "res://user_games/imported_games.json"
var games_folder = "res://user_games/"
var template_scene_path = "res://scene/createScene.tscn"

# Загружаем шрифт
var custom_font = preload("res://fonts/Jovanny Lemonad - Bender-Bold.otf")

func _ready():
	create_games_folder()
	
	# ВРЕМЕННО: исправляем старые игры (потом удали эту строку)
	fix_existing_games()
	
	if import_button:
		import_button.pressed.connect(_on_import_pressed)
	
	if back_button:
		back_button.pressed.connect(_on_back_pressed)
	
	if new_game_button:
		new_game_button.pressed.connect(_on_new_game_pressed)
	
	load_games_list()
	
	# Диагностика
	print("=== ДИАГНОСТИКА НОВЫХ ИГР ===")
	print("Папка игр: ", games_folder)
	print("Файл списка: ", games_list_path)
	print("Файл шаблона: ", template_scene_path)
	print("Шаблон существует: ", FileAccess.file_exists(template_scene_path))

func create_games_folder():
	var dir = DirAccess.open("res://")
	if dir and not dir.dir_exists("user_games"):
		dir.make_dir("user_games")
		print("📁 Папка user_games создана")
	else:
		print("📁 Папка user_games уже существует")

func _on_new_game_pressed():
	print("Нажата кнопка Новая игра")
	show_name_dialog()

func show_name_dialog():
	var dialog = Window.new()
	dialog.title = "Создание новой игры"
	dialog.size = Vector2(400, 200)
	dialog.exclusive = true
	dialog.transient = true
	
	var main_container = VBoxContainer.new()
	main_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_container.add_theme_constant_override("separation", 15)
	
	var label = Label.new()
	label.text = "Введите название новой игры:"
	if custom_font:
		label.add_theme_font_override("font", custom_font)
		label.add_theme_font_size_override("font_size", 16)
	label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	var line_edit = LineEdit.new()
	line_edit.placeholder_text = "Название игры"
	line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line_edit.custom_minimum_size = Vector2(300, 40)
	if custom_font:
		line_edit.add_theme_font_override("font", custom_font)
		line_edit.add_theme_font_size_override("font_size", 18)
	
	var buttons_container = HBoxContainer.new()
	buttons_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	buttons_container.add_theme_constant_override("separation", 20)
	
	var create_btn = Button.new()
	create_btn.text = "Создать"
	create_btn.custom_minimum_size = Vector2(120, 40)
	if custom_font:
		create_btn.add_theme_font_override("font", custom_font)
		create_btn.add_theme_font_size_override("font_size", 16)
	
	var cancel_btn = Button.new()
	cancel_btn.text = "Отмена"
	cancel_btn.custom_minimum_size = Vector2(120, 40)
	if custom_font:
		cancel_btn.add_theme_font_override("font", custom_font)
		cancel_btn.add_theme_font_size_override("font_size", 16)
	
	buttons_container.add_child(create_btn)
	buttons_container.add_child(cancel_btn)
	
	var margin_container = MarginContainer.new()
	margin_container.add_theme_constant_override("margin_left", 20)
	margin_container.add_theme_constant_override("margin_right", 20)
	margin_container.add_theme_constant_override("margin_top", 20)
	margin_container.add_theme_constant_override("margin_bottom", 20)
	
	main_container.add_child(label)
	main_container.add_child(line_edit)
	main_container.add_child(buttons_container)
	
	margin_container.add_child(main_container)
	dialog.add_child(margin_container)
	
	create_btn.pressed.connect(func():
		_on_create_game_confirmed(line_edit)
		dialog.queue_free()
	)
	
	cancel_btn.pressed.connect(func():
		dialog.queue_free()
	)
	
	line_edit.text_submitted.connect(func(text):
		_on_create_game_confirmed(line_edit)
		dialog.queue_free()
	)
	
	add_child(dialog)
	dialog.popup_centered()

func _on_create_game_confirmed(line_edit: LineEdit):
	var game_name = line_edit.text.strip_edges()
	
	if game_name.is_empty():
		_show_error_message("Название не может быть пустым!")
		return
	
	var invalid_chars = ["/", "\\", ":", "*", "?", "\"", "<", ">", "|"]
	for char in invalid_chars:
		if game_name.contains(char):
			_show_error_message("Название содержит недопустимые символы!")
			return
	
	create_new_game(game_name)

func _show_error_message(message: String):
	var error_dialog = Window.new()
	error_dialog.title = "Ошибка"
	error_dialog.size = Vector2(350, 150)
	error_dialog.exclusive = true
	error_dialog.transient = true
	
	var container = VBoxContainer.new()
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	var label = Label.new()
	label.text = message
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if custom_font:
		label.add_theme_font_override("font", custom_font)
		label.add_theme_font_size_override("font_size", 14)
	
	var ok_button = Button.new()
	ok_button.text = "OK"
	ok_button.custom_minimum_size = Vector2(100, 35)
	if custom_font:
		ok_button.add_theme_font_override("font", custom_font)
		ok_button.add_theme_font_size_override("font_size", 16)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_all", 20)
	
	container.add_child(label)
	container.add_child(ok_button)
	margin.add_child(container)
	error_dialog.add_child(margin)
	
	ok_button.pressed.connect(func():
		error_dialog.queue_free()
	)
	
	add_child(error_dialog)
	error_dialog.popup_centered()

func create_new_game(game_name: String):
	var file_name = game_name + ".tscn"
	var dest_path = games_folder + file_name
	
	print("🆕 Создание новой игры: ", game_name)
	print("Путь назначения: ", dest_path)
	
	if FileAccess.file_exists(dest_path):
		_show_error_message("Игра с таким названием уже существует!")
		return
	
	if not FileAccess.file_exists(template_scene_path):
		_show_error_message("Файл шаблона не найден: " + template_scene_path)
		return
	
	var template_scene = load(template_scene_path)
	if template_scene:
		var instance = template_scene.instantiate()
		var packed_scene = PackedScene.new()
		var error = packed_scene.pack(instance)
		
		if error == OK:
			error = ResourceSaver.save(packed_scene, dest_path)
			if error == OK:
				print("✅ Игра успешно создана: ", dest_path)
				save_game_to_list(file_name, game_name)
				load_games_list()
				_show_success_message("Игра '" + game_name + "' успешно создана!")
			else:
				print("❌ Ошибка сохранения: ", error)
				_show_error_message("Ошибка сохранения игры!")
		else:
			print("❌ Ошибка упаковки сцены: ", error)
			_show_error_message("Ошибка обработки шаблона!")
		
		instance.queue_free()
	else:
		print("❌ Не удалось загрузить шаблон: ", template_scene_path)
		_show_error_message("Не удалось загрузить шаблон сцены!")

func _show_success_message(message: String):
	var success_dialog = Window.new()
	success_dialog.title = "Успех"
	success_dialog.size = Vector2(350, 150)
	success_dialog.exclusive = true
	success_dialog.transient = true
	
	var container = VBoxContainer.new()
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	var label = Label.new()
	label.text = message
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if custom_font:
		label.add_theme_font_override("font", custom_font)
		label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color.GREEN)
	
	var ok_button = Button.new()
	ok_button.text = "OK"
	ok_button.custom_minimum_size = Vector2(100, 35)
	if custom_font:
		ok_button.add_theme_font_override("font", custom_font)
		ok_button.add_theme_font_size_override("font_size", 16)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_all", 20)
	
	container.add_child(label)
	container.add_child(ok_button)
	margin.add_child(container)
	success_dialog.add_child(margin)
	
	ok_button.pressed.connect(func():
		success_dialog.queue_free()
	)
	
	add_child(success_dialog)
	success_dialog.popup_centered()

func save_game_to_list(file_name: String, game_name: String):
	var games = []
	
	if FileAccess.file_exists(games_list_path):
		var file = FileAccess.open(games_list_path, FileAccess.READ)
		var content = file.get_as_text()
		file.close()
		
		if content != "":
			var parsed = JSON.parse_string(content)
			if parsed != null:
				games = parsed
			else:
				games = []
		else:
			games = []
	
	var exists = false
	for game in games:
		if game["file"] == file_name:
			exists = true
			break
	
	if not exists:
		games.append({
			"name": game_name,
			"file": file_name,
			"type": "created",
			"created_at": Time.get_datetime_string_from_system()
		})
		
		var save = FileAccess.open(games_list_path, FileAccess.WRITE)
		var json_string = JSON.stringify(games, "\t")
		save.store_string(json_string)
		save.close()
		print("✅ Игра добавлена в список как 'created': ", game_name)

func load_games_list():
	if not games_container:
		print("❌ GamesContainer не найден!")
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
		print("📋 Загружено всего игр: ", games.size() if games else 0)
	
	if games == null or games.is_empty():
		_show_empty_message()
		return
	
	# ФИЛЬТРУЕМ: показываем только созданные игры (type == "created")
	var created_games = []
	for game in games:
		if game.get("type") == "created":
			created_games.append(game)
	
	print("🎮 Показываем только созданные игры: ", created_games.size())
	
	if created_games.is_empty():
		_show_empty_message()
		return
	
	var scroll_container = ScrollContainer.new()
	scroll_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	var center_container = CenterContainer.new()
	center_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var vertical_container = VBoxContainer.new()
	vertical_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vertical_container.alignment = BoxContainer.ALIGNMENT_CENTER
	vertical_container.add_theme_constant_override("separation", 10)
	
	print("🎨 Начинаем отрисовку ", created_games.size(), " созданных игр")
	
	for game in created_games:
		print("➕ Добавляем игру в список: ", game["name"])
		add_game_item(vertical_container, game)
	
	center_container.add_child(vertical_container)
	scroll_container.add_child(center_container)
	games_container.add_child(scroll_container)
	
	print("✅ Отрисовка завершена")

func _show_empty_message():
	var label = Label.new()
	label.text = "Нет созданных игр\nНажмите 'Новая игра' чтобы создать"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	if custom_font:
		label.add_theme_font_override("font", custom_font)
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
	
	if custom_font:
		game_button.add_theme_font_override("font", custom_font)
		game_button.add_theme_font_size_override("font_size", 24)
	
	game_button.add_theme_color_override("font_color", Color.WHITE)
	game_button.add_theme_color_override("font_hover_color", Color.YELLOW)
	game_button.custom_minimum_size = Vector2(250, 50)
	game_button.pressed.connect(_on_game_selected.bind(game["file"]))
	
	var delete_button = Button.new()
	delete_button.text = "🗑️"
	
	if custom_font:
		delete_button.add_theme_font_override("font", custom_font)
		delete_button.add_theme_font_size_override("font_size", 24)
	
	delete_button.add_theme_color_override("font_color", Color.RED)
	delete_button.add_theme_color_override("font_hover_color", Color.WHITE)
	delete_button.custom_minimum_size = Vector2(60, 50)
	delete_button.pressed.connect(_on_delete_game.bind(game["file"], game["name"]))
	
	item_container.add_child(game_button)
	item_container.add_child(delete_button)
	parent.add_child(item_container)
	
	var separator = HSeparator.new()
	separator.custom_minimum_size = Vector2(350, 2)
	parent.add_child(separator)

func _on_game_selected(game_file: String):
	var scene_path = games_folder + game_file
	print("🎮 Запуск игры: ", scene_path)
	
	if FileAccess.file_exists(scene_path):
		var scene = load(scene_path)
		if scene:
			get_tree().change_scene_to_packed(scene)
		else:
			print("❌ Ошибка загрузки сцены")
			_show_error_message("Не удалось загрузить игру")
	else:
		print("❌ Файл не найден: ", scene_path)
		_show_error_message("Файл игры не найден")

func _on_delete_game(game_file: String, game_name: String):
	var scene_path = games_folder + game_file
	if FileAccess.file_exists(scene_path):
		DirAccess.remove_absolute(scene_path)
		print("🗑️ Удалён файл: ", scene_path)
	
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
		save.store_string(JSON.stringify(games, "\t"))
		save.close()
		print("✅ Игра удалена из списка")
	
	load_games_list()

func _on_import_pressed():
	get_tree().change_scene_to_file("res://scene/ImportGameMenu.tscn")

func _on_back_pressed():
	get_tree().change_scene_to_file("res://scene/mainscene.tscn")

# ВРЕМЕННАЯ ФУНКЦИЯ ДЛЯ ИСПРАВЛЕНИЯ СТАРЫХ ИГР (ПОТОМ УДАЛИТЬ)
func fix_existing_games():
	var games = []
	if FileAccess.file_exists(games_list_path):
		var file = FileAccess.open(games_list_path, FileAccess.READ)
		var content = file.get_as_text()
		file.close()
		games = JSON.parse_string(content)
	
	var updated = false
	for i in range(games.size()):
		if games[i].get("type") == null:
			if games[i]["file"] == "createScene.tscn":
				games[i]["type"] = "template"
			else:
				if games[i].has("created_at"):
					games[i]["type"] = "created"
				else:
					games[i]["type"] = "imported"
			updated = true
	
	if updated:
		var save = FileAccess.open(games_list_path, FileAccess.WRITE)
		save.store_string(JSON.stringify(games, "\t"))
		save.close()
		print("✅ Список игр обновлён с типами")
	else:
		print("Список уже в правильном формате")
