extends Control

@export var new_game_scene: String = "res://scene/NewGameMenu.tscn"
@export var import_game_scene: String = "res://scene/ImportGameMenu.tscn"

# === ПЕРЕМЕННЫЕ ДЛЯ ТАЧ-УПРАВЛЕНИЯ ===
var touch_points = {}
var last_touch_distance = 0.0

func _ready():
	# Подключаем кнопки (работает и для мыши, и для тача)
	_setup_buttons()
	
	# Настройка для мобильных устройств
	if OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios"):
		_setup_mobile_ui()
		print("📱 Обнаружено мобильное устройство! Включена поддержка тач-управления.")
	else:
		print("💻 Режим ПК - используются кнопки мыши")

func _setup_buttons():
	# Находим кнопки и подключаем сигналы
	var new_game_btn = get_node_or_null("ButtonNewGame")
	var import_btn = get_node_or_null("ButtonImportGame")
	var quit_btn = get_node_or_null("ButtonQuit")
	
	if new_game_btn:
		new_game_btn.pressed.connect(_on_new_game_pressed)
		# Увеличиваем зону касания для мобильных
		if OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios"):
			new_game_btn.custom_minimum_size = Vector2(200, 60)
			new_game_btn.add_theme_font_size_override("font_size", 18)
	else:
		print("Ошибка: кнопка ButtonNewGame не найдена!")
	
	if import_btn:
		import_btn.pressed.connect(_on_import_game_pressed)
		if OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios"):
			import_btn.custom_minimum_size = Vector2(200, 60)
			import_btn.add_theme_font_size_override("font_size", 18)
	else:
		print("Ошибка: кнопка ButtonImportGame не найдена!")
	
	if quit_btn:
		quit_btn.pressed.connect(_on_quit_pressed)
		if OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios"):
			quit_btn.custom_minimum_size = Vector2(200, 60)
			quit_btn.add_theme_font_size_override("font_size", 18)
	else:
		print("Ошибка: кнопка ButtonQuit не найдена!")

func _setup_mobile_ui():
	# Увеличиваем все кнопки для удобного нажатия пальцем
	var buttons = get_tree().get_nodes_in_group("menu_buttons")
	for btn in buttons:
		if btn is Button:
			btn.custom_minimum_size = Vector2(200, 60)
			btn.add_theme_font_size_override("font_size", 18)

func _input(event):
	# Обработка тач-экранов (дополнительная)
	if event is InputEventScreenTouch and event.pressed:
		# Можно добавить визуальную обратную связь при касании
		_show_touch_feedback(event.position)

func _show_touch_feedback(position: Vector2):
	# Визуальная обратная связь при касании (опционально)
	var feedback = Sprite2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 20
	feedback.position = position
	feedback.modulate = Color(1, 1, 1, 0.5)
	add_child(feedback)
	
	var tween = create_tween()
	tween.tween_property(feedback, "modulate", Color(1, 1, 1, 0), 0.3)
	await tween.finished
	feedback.queue_free()

func _on_new_game_pressed():
	print("🆕 Нажата кнопка Новая игра")
	get_tree().change_scene_to_file(new_game_scene)

func _on_import_game_pressed():
	print("📥 Нажата кнопка Импорт игры")
	get_tree().change_scene_to_file(import_game_scene)

func _on_quit_pressed():
	print("🚪 Выход из игры")
	get_tree().quit()
