extends Node2D

# Ссылки на узлы
@onready var games_container = $Control/GamesContainer
@onready var import_button = $Control/ButtonImport
@onready var back_button = $Control/ButtonToMainScene
@onready var new_game_button = $Control/ButtonNewGame

# Пути (используем user_games вместо user://games)
var games_list_path = "res://user_games/imported_games.json"
var games_folder = "res://user_games/"
var template_scene_path = "res://scene/createScene.tscn"  # Шаблонная сцена (создашь потом)

func _ready():
	create_games_folder()
	
	if import_button:
		import_button.pressed.connect(_on_import_pressed)
	
	if back_button:
		back_button.pressed.connect(_on_back_pressed)
	
	if new_game_button:
		new_game_button.pressed.connect(_on_new_game_pressed)
	
	load_games_list()

func create_games_folder():
	var dir = DirAccess.open("res://")
	if dir and not dir.dir_exists("user_games"):
		dir.make_dir("user_games")

func _on_new_game_pressed():
	show_name_dialog()

func show_name_dialog():
	var dialog = AcceptDialog.new()
	dialog.title = "Создание новой игры"
	dialog.dialog_text = "Введите название новой игры:"
	dialog.ok_button_text = "Создать"
	
	var line_edit = LineEdit.new()
	line_edit.placeholder_text = "Название игры"
	line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dialog.add_child(line_edit)
	
	dialog.size = Vector2(300, 150)
	dialog.confirmed.connect(_on_create_game_confirmed.bind(line_edit))
	
	add_child(dialog)
	dialog.popup_centered()

func _on_create_game_confirmed(line_edit: LineEdit):
	var game_name = line_edit.text.strip_edges()
	
	if game_name.is_empty():
		return
	
	var invalid_chars = ["/", "\\", ":", "*", "?", "\"", "<", ">", "|"]
	for char in invalid_chars:
		if game_name.contains(char):
			return
	
	create_new_game(game_name)

func create_new_game(game_name: String):
	var file_name = game_name + ".tscn"
	var dest_path = games_folder + file_name
	
	if FileAccess.file_exists(dest_path):
		return
	
	if not FileAccess.file_exists(template_scene_path):
		return
	
	var template_file = FileAccess.open(template_scene_path, FileAccess.READ)
	if template_file:
		var data = template_file.get_buffer(template_file.get_length())
		template_file.close()
		
		var dest_file = FileAccess.open(dest_path, FileAccess.WRITE)
		if dest_file:
			dest_file.store_buffer(data)
			dest_file.close()
			save_game_to_list(file_name, game_name)
			load_games_list()

func save_game_to_list(file_name: String, game_name: String):
	var games = []
	
	if FileAccess.file_exists(games_list_path):
		var file = FileAccess.open(games_list_path, FileAccess.READ)
		var content = file.get_as_text()
		file.close()
		games = JSON.parse_string(content)
	
	if games == null:
		games = []
	
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

func load_games_list():
	if not games_container:
		return
	
	for child in games_container.get_children():
		child.queue_free()
	
	var games = []
	if FileAccess.file_exists(games_list_path):
		var file = FileAccess.open(games_list_path, FileAccess.READ)
		var content = file.get_as_text()
		file.close()
		games = JSON.parse_string(content)
	
	if games == null or games.is_empty():
		return
	
	var center_container = CenterContainer.new()
	center_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	var vertical_container = VBoxContainer.new()
	vertical_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vertical_container.alignment = BoxContainer.ALIGNMENT_CENTER
	
	for game in games:
		add_game_item(vertical_container, game)
	
	center_container.add_child(vertical_container)
	games_container.add_child(center_container)

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
	var scene_path = games_folder + game_file
	
	if FileAccess.file_exists(scene_path):
		var scene = load(scene_path)
		if scene:
			get_tree().change_scene_to_packed(scene)

func _on_delete_game(game_file: String, game_name: String):
	var scene_path = games_folder + game_file
	if FileAccess.file_exists(scene_path):
		DirAccess.remove_absolute(scene_path)
	
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
	
	load_games_list()

func _on_import_pressed():
	get_tree().change_scene_to_file("res://ImportGameMenu.tscn")

func _on_back_pressed():
	get_tree().change_scene_to_file("res://scene/mainscene.tscn")
