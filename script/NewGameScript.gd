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

# === ПЕРЕМЕННЫЕ ДЛЯ МОБИЛЬНЫХ УСТРОЙСТВ ===
var is_touch_mode = false

func _ready():
	create_games_folder()
	
	# Настройка для мобильных устройств
	if OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios"):
		is_touch_mode = true
		_setup_mobile_ui()
		print("📱 Обнаружено мобильное устройство! Включена поддержка тач-управления.")
	
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

func _setup_mobile_ui():
	if import_button:
		import_button.custom_minimum_size = Vector2(200, 60)
		import_button.add_theme_font_size_override("font_size", 18)
	
	if back_button:
		back_button.custom_minimum_size = Vector2(200, 60)
		back_button.add_theme_font_size_override("font_size", 18)
	
	if new_game_button:
		new_game_button.custom_minimum_size = Vector2(200, 60)
		new_game_button.add_theme_font_size_override("font_size", 18)
	
	if games_container:
		games_container.custom_minimum_size = Vector2(350, 400)

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
	dialog.title = ""
	dialog.size = Vector2(500, 600)
	dialog.exclusive = true
	dialog.transient = true
	dialog.popup_centered()
	
	# Убираем рамку
	dialog.unresizable = true
	dialog.borderless = true
	
	# Основной фон
	var main_panel = Panel.new()
	main_panel.size = Vector2(480, 580)
	main_panel.position = Vector2(10, 10)
	
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.08, 0.12, 0.98)
	panel_style.set_border_width_all(2)
	panel_style.border_color = Color(0.5, 0.7, 1, 1)
	panel_style.set_corner_radius_all(20)
	panel_style.shadow_size = 10
	panel_style.shadow_color = Color(0, 0, 0, 0.5)
	main_panel.add_theme_stylebox_override("panel", panel_style)
	dialog.add_child(main_panel)
	
	# Заголовок
	var title_panel = Panel.new()
	title_panel.size = Vector2(480, 55)
	title_panel.position = Vector2(0, 0)
	var title_style = StyleBoxFlat.new()
	title_style.bg_color = Color(0.15, 0.15, 0.25, 1)
	title_style.corner_radius_top_left = 20
	title_style.corner_radius_top_right = 20
	title_style.corner_radius_bottom_left = 0
	title_style.corner_radius_bottom_right = 0
	title_panel.add_theme_stylebox_override("panel", title_style)
	main_panel.add_child(title_panel)
	
	var title_label = Label.new()
	title_label.text = "✨ СОЗДАНИЕ НОВОЙ ИГРЫ ✨"
	title_label.anchor_left = 0.5
	title_label.anchor_right = 0.5
	title_label.position = Vector2(240, 15)
	title_label.size = Vector2(300, 30)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 18)
	title_label.add_theme_color_override("font_color", Color(1, 0.9, 0.5, 1))
	title_panel.add_child(title_label)
	
	# Кнопка закрытия
	var close_btn = Button.new()
	close_btn.text = "✕"
	close_btn.anchor_left = 1.0
	close_btn.position = Vector2(445, 12)
	close_btn.size = Vector2(30, 30)
	close_btn.add_theme_font_size_override("font_size", 20)
	close_btn.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	
	var close_normal_style = StyleBoxFlat.new()
	close_normal_style.bg_color = Color(0.6, 0.2, 0.2, 1)
	close_normal_style.set_corner_radius_all(15)
	close_normal_style.set_border_width_all(1)
	close_normal_style.border_color = Color(0.9, 0.3, 0.3, 1)
	close_btn.add_theme_stylebox_override("normal", close_normal_style)
	
	var close_hover_style = StyleBoxFlat.new()
	close_hover_style.bg_color = Color(0.8, 0.3, 0.3, 1)
	close_hover_style.set_corner_radius_all(15)
	close_hover_style.set_border_width_all(1)
	close_hover_style.border_color = Color(1, 0.4, 0.4, 1)
	close_btn.add_theme_stylebox_override("hover", close_hover_style)
	
	var close_pressed_style = StyleBoxFlat.new()
	close_pressed_style.bg_color = Color(0.4, 0.15, 0.15, 1)
	close_pressed_style.set_corner_radius_all(15)
	close_btn.add_theme_stylebox_override("pressed", close_pressed_style)
	
	close_btn.pressed.connect(func():
		dialog.queue_free()
	)
	title_panel.add_child(close_btn)
	
	# ScrollContainer для прокрутки
	var scroll = ScrollContainer.new()
	scroll.size = Vector2(480, 520)
	scroll.position = Vector2(0, 55)
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_panel.add_child(scroll)
	
	# Основной контейнер
	var main_container = VBoxContainer.new()
	main_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_container.add_theme_constant_override("separation", 20)
	scroll.add_child(main_container)
	
	# Отступ сверху
	var top_spacer = Control.new()
	top_spacer.custom_minimum_size = Vector2(0, 15)
	main_container.add_child(top_spacer)
	
	# === СЕКЦИЯ РУЧНОГО ВВОДА ===
	var manual_frame = Panel.new()
	manual_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	manual_frame.custom_minimum_size = Vector2(0, 160)
	var frame_style = StyleBoxFlat.new()
	frame_style.bg_color = Color(0.12, 0.12, 0.18, 1)
	frame_style.set_border_width_all(1)
	frame_style.border_color = Color(0.4, 0.6, 0.9, 0.5)
	frame_style.set_corner_radius_all(12)
	manual_frame.add_theme_stylebox_override("panel", frame_style)
	main_container.add_child(manual_frame)
	
	var manual_vbox = VBoxContainer.new()
	manual_vbox.position = Vector2(15, 15)
	manual_vbox.size = Vector2(430, 130)
	manual_vbox.add_theme_constant_override("separation", 12)
	manual_frame.add_child(manual_vbox)
	
	var manual_label = Label.new()
	manual_label.text = "📝 РУЧНОЙ ВВОД"
	manual_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	manual_label.add_theme_font_size_override("font_size", 14)
	manual_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.9, 1))
	manual_vbox.add_child(manual_label)
	
	# Поле ввода
	var line_edit = LineEdit.new()
	line_edit.placeholder_text = "Введите название игры..."
	line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line_edit.custom_minimum_size = Vector2(400, 45)
	line_edit.add_theme_font_size_override("font_size", 16)
	line_edit.virtual_keyboard_enabled = true
	line_edit.focus_entered.connect(_force_show_keyboard)
	manual_vbox.add_child(line_edit)
	
	# Кнопка создания
	var create_btn = Button.new()
	create_btn.text = "✅ СОЗДАТЬ"
	create_btn.custom_minimum_size = Vector2(180, 45)
	create_btn.add_theme_font_size_override("font_size", 15)
	
	var create_normal_style = StyleBoxFlat.new()
	create_normal_style.bg_color = Color(0.2, 0.5, 0.2, 1)
	create_normal_style.set_corner_radius_all(10)
	create_normal_style.set_border_width_all(1)
	create_normal_style.border_color = Color(0.3, 0.7, 0.3, 1)
	create_btn.add_theme_stylebox_override("normal", create_normal_style)
	
	var create_hover_style = StyleBoxFlat.new()
	create_hover_style.bg_color = Color(0.3, 0.6, 0.3, 1)
	create_hover_style.set_corner_radius_all(10)
	create_hover_style.set_border_width_all(1)
	create_hover_style.border_color = Color(0.4, 0.8, 0.4, 1)
	create_btn.add_theme_stylebox_override("hover", create_hover_style)
	
	var create_btn_center = CenterContainer.new()
	create_btn_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	create_btn_center.add_child(create_btn)
	manual_vbox.add_child(create_btn_center)
	
	# Разделитель
	var separator = HSeparator.new()
	separator.custom_minimum_size = Vector2(400, 15)
	separator.add_theme_color_override("color", Color(0.4, 0.6, 0.9, 0.5))
	var sep_center = CenterContainer.new()
	sep_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sep_center.add_child(separator)
	main_container.add_child(sep_center)
	
	# === СЕКЦИЯ ГОТОВЫХ ИМЁН ===
	var preset_frame = Panel.new()
	preset_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preset_frame.custom_minimum_size = Vector2(0, 280)
	frame_style = StyleBoxFlat.new()
	frame_style.bg_color = Color(0.12, 0.12, 0.18, 1)
	frame_style.set_border_width_all(1)
	frame_style.border_color = Color(0.4, 0.6, 0.9, 0.5)
	frame_style.set_corner_radius_all(12)
	preset_frame.add_theme_stylebox_override("panel", frame_style)
	main_container.add_child(preset_frame)
	
	var preset_vbox = VBoxContainer.new()
	preset_vbox.position = Vector2(15, 15)
	preset_vbox.size = Vector2(430, 250)
	preset_vbox.add_theme_constant_override("separation", 10)
	preset_frame.add_child(preset_vbox)
	
	var preset_label = Label.new()
	preset_label.text = "🎲 ВЫБЕРИТЕ ИЗ СПИСКА"
	preset_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preset_label.add_theme_font_size_override("font_size", 14)
	preset_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.9, 1))
	preset_vbox.add_child(preset_label)
	
	# Scroll для списка
	var preset_scroll = ScrollContainer.new()
	preset_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preset_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	preset_scroll.custom_minimum_size = Vector2(0, 180)
	preset_vbox.add_child(preset_scroll)
	
	var preset_grid = VBoxContainer.new()
	preset_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preset_grid.add_theme_constant_override("separation", 8)
	preset_scroll.add_child(preset_grid)
	
	var preset_names = [
		"🔋 Моя первая цепь",
		"💡 Схема с лампочкой",
		"🔌 Параллельное соединение",
		"📏 Последовательная цепь",
		"🎛️ Сложная схема",
		"🏭 Электрическая сеть",
		"🔬 Лабораторная работа",
		"📚 Учебный проект",
		"⭐ Звёздная схема",
		"🌀 Смешанное соединение"
	]
	
	for name in preset_names:
		var name_btn = Button.new()
		name_btn.text = name
		name_btn.custom_minimum_size = Vector2(400, 40)
		name_btn.add_theme_font_size_override("font_size", 14)
		name_btn.add_theme_constant_override("h_separation", 15)
		
		var btn_normal_style = StyleBoxFlat.new()
		btn_normal_style.bg_color = Color(0.12, 0.12, 0.18, 1)
		btn_normal_style.set_corner_radius_all(8)
		btn_normal_style.set_border_width_all(1)
		btn_normal_style.border_color = Color(0.3, 0.5, 0.8, 1)
		name_btn.add_theme_stylebox_override("normal", btn_normal_style)
		
		var btn_hover_style = StyleBoxFlat.new()
		btn_hover_style.bg_color = Color(0.18, 0.18, 0.25, 1)
		btn_hover_style.set_corner_radius_all(8)
		btn_hover_style.set_border_width_all(1)
		btn_hover_style.border_color = Color(0.5, 0.7, 1, 1)
		name_btn.add_theme_stylebox_override("hover", btn_hover_style)
		
		var btn_center = CenterContainer.new()
		btn_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn_center.add_child(name_btn)
		preset_grid.add_child(btn_center)
		
		name_btn.pressed.connect(_on_preset_name_selected.bind(name, dialog))
	
	# Отступ снизу
	var bottom_spacer = Control.new()
	bottom_spacer.custom_minimum_size = Vector2(0, 20)
	main_container.add_child(bottom_spacer)
	
	# Подключаем сигнал кнопки создания
	create_btn.pressed.connect(func():
		var game_name = line_edit.text.strip_edges()
		if game_name.is_empty():
			_show_error_message("Введите название игры или выберите из списка!")
			return
		create_new_game(game_name)
		dialog.queue_free()
	)
	
	line_edit.text_submitted.connect(func(text):
		var game_name = line_edit.text.strip_edges()
		if game_name.is_empty():
			_show_error_message("Введите название игры!")
			return
		create_new_game(game_name)
		dialog.queue_free()
	)
	
	add_child(dialog)
	dialog.popup_centered()
	
	# Автофокус на поле ввода
	await get_tree().process_frame
	line_edit.grab_focus()

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
	var dialog = Window.new()
	dialog.title = ""
	dialog.size = Vector2(400, 180)
	dialog.exclusive = true
	dialog.transient = true
	dialog.unresizable = true
	dialog.borderless = true
	dialog.popup_centered()
	
	var main_panel = Panel.new()
	main_panel.size = Vector2(380, 160)
	main_panel.position = Vector2(10, 10)
	
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.08, 0.12, 0.98)
	panel_style.set_border_width_all(2)
	panel_style.border_color = Color(0.8, 0.3, 0.3, 1)
	panel_style.set_corner_radius_all(20)
	main_panel.add_theme_stylebox_override("panel", panel_style)
	dialog.add_child(main_panel)
	
	var vbox = VBoxContainer.new()
	vbox.position = Vector2(20, 20)
	vbox.size = Vector2(340, 120)
	vbox.add_theme_constant_override("separation", 15)
	main_panel.add_child(vbox)
	
	var icon_label = Label.new()
	icon_label.text = "❌"
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.add_theme_font_size_override("font_size", 40)
	vbox.add_child(icon_label)
	
	var text_label = Label.new()
	text_label.text = message
	text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text_label.add_theme_font_size_override("font_size", 16)
	text_label.add_theme_color_override("font_color", Color(0.8, 0.3, 0.3, 1))
	vbox.add_child(text_label)
	
	var ok_btn = Button.new()
	ok_btn.text = "OK"
	ok_btn.custom_minimum_size = Vector2(100, 35)
	ok_btn.add_theme_font_size_override("font_size", 14)
	
	var ok_style = StyleBoxFlat.new()
	ok_style.bg_color = Color(0.5, 0.2, 0.2, 1)
	ok_style.set_corner_radius_all(8)
	ok_btn.add_theme_stylebox_override("normal", ok_style)
	
	var close_btn_container = CenterContainer.new()
	close_btn_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	close_btn_container.add_child(ok_btn)
	vbox.add_child(close_btn_container)
	
	ok_btn.pressed.connect(func():
		dialog.queue_free()
	)
	
	add_child(dialog)
	dialog.popup_centered()

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
	var dialog = Window.new()
	dialog.title = ""
	dialog.size = Vector2(400, 180)
	dialog.exclusive = true
	dialog.transient = true
	dialog.unresizable = true
	dialog.borderless = true
	dialog.popup_centered()
	
	var main_panel = Panel.new()
	main_panel.size = Vector2(380, 160)
	main_panel.position = Vector2(10, 10)
	
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.08, 0.12, 0.98)
	panel_style.set_border_width_all(2)
	panel_style.border_color = Color(0.3, 0.8, 0.3, 1)
	panel_style.set_corner_radius_all(20)
	main_panel.add_theme_stylebox_override("panel", panel_style)
	dialog.add_child(main_panel)
	
	var vbox = VBoxContainer.new()
	vbox.position = Vector2(20, 20)
	vbox.size = Vector2(340, 120)
	vbox.add_theme_constant_override("separation", 15)
	main_panel.add_child(vbox)
	
	var icon_label = Label.new()
	icon_label.text = "✅"
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.add_theme_font_size_override("font_size", 40)
	vbox.add_child(icon_label)
	
	var text_label = Label.new()
	text_label.text = message
	text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text_label.add_theme_font_size_override("font_size", 16)
	text_label.add_theme_color_override("font_color", Color(0.3, 0.8, 0.3, 1))
	vbox.add_child(text_label)
	
	var ok_btn = Button.new()
	ok_btn.text = "OK"
	ok_btn.custom_minimum_size = Vector2(100, 35)
	ok_btn.add_theme_font_size_override("font_size", 14)
	
	var ok_style = StyleBoxFlat.new()
	ok_style.bg_color = Color(0.2, 0.5, 0.2, 1)
	ok_style.set_corner_radius_all(8)
	ok_btn.add_theme_stylebox_override("normal", ok_style)
	
	var close_btn_container = CenterContainer.new()
	close_btn_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	close_btn_container.add_child(ok_btn)
	vbox.add_child(close_btn_container)
	
	ok_btn.pressed.connect(func():
		dialog.queue_free()
	)
	
	add_child(dialog)
	dialog.popup_centered()

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
	print("🎮 Запуск свободного режима: ", scene_path)
	
	if FileAccess.file_exists(scene_path):
		if has_node("/root/GameState"):
			get_node("/root/GameState").current_level = 0
			print("Установлен режим: Свободный мир (0)")
		else:
			print("⚠️ ОШИБКА: GameState не найден в Autoload!")

		var scene = load(scene_path)
		if scene:
			get_tree().change_scene_to_packed(scene)
		else:
			_show_error_message("Не удалось загрузить игру")
	else:
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

# === ФУНКЦИИ ДЛЯ МОБИЛЬНЫХ УСТРОЙСТВ ===
func _force_show_keyboard():
	if OS.has_feature("android") or OS.has_feature("mobile"):
		DisplayServer.virtual_keyboard_show("", Rect2())
		print("⌨️ Клавиатура принудительно вызвана")

func _on_preset_name_selected(name: String, dialog: Window):
	var clean_name = name
	var emojis = ["🔋 ", "💡 ", "🔌 ", "📏 ", "🎛️ ", "🏭 ", "🔬 ", "📚 ", "⭐ ", "🌀 "]
	for emoji in emojis:
		if clean_name.begins_with(emoji):
			clean_name = clean_name.replace(emoji, "")
			break
	create_new_game(clean_name)
	dialog.queue_free()
