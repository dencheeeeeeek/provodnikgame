extends Node2D

@onready var import_button = $Control/ButtonImport
@onready var back_button = $Control/ButtonToMainScene

var games_list_path = "user://imported_games.json"
var games_folder = "user://games/"
var games_container: Control

var is_touch_mode = false

func _ready():
	_create_games_container()
	create_games_folder()
	
	if OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios") or OS.has_feature("aurora"):
		is_touch_mode = true
		_setup_mobile_ui()
	
	if import_button:
		import_button.pressed.connect(_on_import_pressed)
	
	if back_button:
		back_button.pressed.connect(_on_back_pressed)
	
	load_games_list()
	diagnose_folder()

func _create_games_container():
	var control = get_node_or_null("Control")
	if control:
		games_container = Control.new()
		games_container.name = "GamesContainerCode"
		games_container.position = Vector2(50, 170)
		games_container.size = Vector2(get_viewport().size.x - 100, get_viewport().size.y - 250)
		control.add_child(games_container)
		
		get_viewport().size_changed.connect(_on_resize)

func _on_resize():
	if games_container:
		games_container.position = Vector2(50, 170)
		games_container.size = Vector2(get_viewport().size.x - 100, get_viewport().size.y - 250)

func _setup_mobile_ui():
	if import_button:
		import_button.custom_minimum_size = Vector2(200, 60)
		import_button.add_theme_font_size_override("font_size", 18)
	if back_button:
		back_button.custom_minimum_size = Vector2(200, 60)
		back_button.add_theme_font_size_override("font_size", 18)

func diagnose_folder():
	print("=== ДИАГНОСТИКА ===")
	print("Путь к папке игр: ", games_folder)
	print("Путь к JSON: ", games_list_path)
	
	var dir = DirAccess.open("user://")
	if dir:
		if dir.dir_exists("games"):
			print("Папка games существует")
			dir.open("user://games")
			dir.list_dir_begin()
			var file_name = dir.get_next()
			while file_name != "":
				print("Найдено в папке: ", file_name)
				file_name = dir.get_next()
			dir.list_dir_end()
		else:
			print("Папка games НЕ существует")
	
	if FileAccess.file_exists(games_list_path):
		var file = FileAccess.open(games_list_path, FileAccess.READ)
		var content = file.get_as_text()
		file.close()
		print("Содержимое JSON: ", content)
	else:
		print("JSON файл не существует")
	print("=== КОНЕЦ ДИАГНОСТИКИ ===")

func create_games_folder():
	var dir = DirAccess.open("user://")
	if dir and not dir.dir_exists("games"):
		dir.make_dir("games")
		print("Папка games создана в user://")

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
		show_error("Игра с таким именем уже существует!")
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
			show_success("Игра импортирована!")
		else:
			show_error("Не удалось сохранить файл")
	else:
		show_error("Не удалось открыть файл")

func save_game_to_list(file_name: String):
	var games = []
	
	if FileAccess.file_exists(games_list_path):
		var file = FileAccess.open(games_list_path, FileAccess.READ)
		var content = file.get_as_text()
		file.close()
		if content != "" and content != "[]":
			var parsed = JSON.parse_string(content)
			if parsed != null:
				games = parsed
	
	var game_name = file_name.replace(".tscn", "")
	
	var exists = false
	for game in games:
		if game.get("file") == file_name:
			exists = true
			break
	
	if not exists:
		games.append({
			"name": game_name,
			"file": file_name,
			"type": "imported"
		})
		
		var save = FileAccess.open(games_list_path, FileAccess.WRITE)
		save.store_string(JSON.stringify(games, "\t"))
		save.close()
		print("✅ Игра добавлена в список, теперь игр: ", games.size())

func load_games_list():
	if not games_container:
		print("GamesContainer не найден!")
		return
	
	for child in games_container.get_children():
		child.queue_free()
	
	var games = []
	if FileAccess.file_exists(games_list_path):
		var file = FileAccess.open(games_list_path, FileAccess.READ)
		var content = file.get_as_text()
		file.close()
		if content != "" and content != "[]":
			var parsed = JSON.parse_string(content)
			if parsed != null and typeof(parsed) == TYPE_ARRAY:
				games = parsed
	
	var imported_games = []
	for game in games:
		if game.get("type") == "imported":
			imported_games.append(game)
	
	print("Найдено импортированных игр: ", imported_games.size())
	
	if imported_games.is_empty():
		show_empty_message()
		return
	
	var panel = Panel.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.1, 0.15, 0.95)
	panel_style.set_border_width_all(2)
	panel_style.border_color = Color(0.4, 0.6, 0.9, 1)
	panel_style.set_corner_radius_all(15)
	panel.add_theme_stylebox_override("panel", panel_style)
	
	var margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)
	
	var scroll = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 10)
	
	for game in imported_games:
		add_game_item(vbox, game)
	
	scroll.add_child(vbox)
	margin.add_child(scroll)
	games_container.add_child(panel)
	print("Список отображён, элементов: ", imported_games.size())

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
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 15)
	
	var game_btn = Button.new()
	game_btn.text = game["name"]
	game_btn.add_theme_font_size_override("font_size", 24)
	game_btn.add_theme_color_override("font_color", Color.WHITE)
	game_btn.add_theme_color_override("font_hover_color", Color.YELLOW)
	game_btn.custom_minimum_size = Vector2(250, 50)
	game_btn.pressed.connect(_on_game_selected.bind(game["file"]))
	
	var del_btn = Button.new()
	del_btn.text = "🗑️"
	del_btn.add_theme_font_size_override("font_size", 24)
	del_btn.add_theme_color_override("font_color", Color.RED)
	del_btn.custom_minimum_size = Vector2(60, 50)
	del_btn.pressed.connect(_on_delete_game.bind(game["file"], game["name"]))
	
	hbox.add_child(game_btn)
	hbox.add_child(del_btn)
	parent.add_child(hbox)

func _on_game_selected(game_file: String):
	var scene_path = games_folder + game_file
	if FileAccess.file_exists(scene_path):
		var scene = load(scene_path)
		if scene:
			get_tree().change_scene_to_packed(scene)
		else:
			show_error("Не удалось загрузить игру")
	else:
		show_error("Файл игры не найден")

func _on_delete_game(game_file: String, game_name: String):
	var scene_path = games_folder + game_file
	if FileAccess.file_exists(scene_path):
		var dir = DirAccess.open(games_folder)
		if dir:
			dir.remove(game_file)
	
	var games = []
	if FileAccess.file_exists(games_list_path):
		var file = FileAccess.open(games_list_path, FileAccess.READ)
		var content = file.get_as_text()
		file.close()
		if content != "" and content != "[]":
			var parsed = JSON.parse_string(content)
			if parsed != null:
				games = parsed
	
	for i in range(games.size() - 1, -1, -1):
		if games[i].get("file") == game_file:
			games.remove_at(i)
			break
	
	var save = FileAccess.open(games_list_path, FileAccess.WRITE)
	save.store_string(JSON.stringify(games, "\t"))
	save.close()
	
	load_games_list()

func _on_back_pressed():
	get_tree().change_scene_to_file("res://scene/mainscene.tscn")

func show_error(message: String):
	var label = Label.new()
	label.text = message
	label.add_theme_color_override("font_color", Color.RED)
	label.add_theme_font_size_override("font_size", 16)
	label.position = Vector2(get_viewport().size.x / 2 - 150, get_viewport().size.y - 100)
	label.size = Vector2(300, 50)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.7)
	style.set_corner_radius_all(10)
	label.add_theme_stylebox_override("normal", style)
	
	add_child(label)
	await get_tree().create_timer(2).timeout
	label.queue_free()

func show_success(message: String):
	var label = Label.new()
	label.text = message
	label.add_theme_color_override("font_color", Color.GREEN)
	label.add_theme_font_size_override("font_size", 16)
	label.position = Vector2(get_viewport().size.x / 2 - 150, get_viewport().size.y - 100)
	label.size = Vector2(300, 50)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.7)
	style.set_corner_radius_all(10)
	label.add_theme_stylebox_override("normal", style)
	
	add_child(label)
	await get_tree().create_timer(2).timeout
	label.queue_free()
