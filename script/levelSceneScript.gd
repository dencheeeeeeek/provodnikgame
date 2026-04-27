extends GridContainer

@export var level1_scene: String = "res://scene/level_1.tscn"
@export var level2_scene: String = "res://scene/level_2.tscn"
@export var level3_scene: String = "res://scene/level_3.tscn"
@export var level4_scene: String = "res://scene/level_4.tscn"
@export var level5_scene: String = "res://scene/level_5.tscn"

var touch_points = {}
var last_touch_distance = 0.0

func _ready():
	_setup_buttons()
	
	if OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios") or OS.has_feature("aurora"):
		_setup_mobile_ui()
		print("📱 Обнаружено мобильное устройство или ОС Аврора! Включена поддержка тач-управления.")
	else:
		_setup_pc_ui()
		print("💻 Режим ПК - используются кнопки мыши")

func _setup_buttons():
	var level1_btn = get_node_or_null("ButtonLevel1")
	var level2_btn = get_node_or_null("ButtonLevel2")
	var level3_btn = get_node_or_null("ButtonLevel3")
	var level4_btn = get_node_or_null("ButtonLevel4")
	var level5_btn = get_node_or_null("ButtonLevel5")
	
	if level1_btn:
		level1_btn.pressed.connect(_on_level1_pressed)
		if _is_mobile_platform():
			level1_btn.custom_minimum_size = Vector2(200, 60)
			level1_btn.add_theme_font_size_override("font_size", 18)
	else:
		print("Ошибка: кнопка ButtonLevel1 не найдена!")
	
	if level2_btn:
		level2_btn.pressed.connect(_on_level2_pressed)
		if _is_mobile_platform():
			level2_btn.custom_minimum_size = Vector2(200, 60)
			level2_btn.add_theme_font_size_override("font_size", 18)
	else:
		print("Ошибка: кнопка ButtonLevel2 не найдена!")
	
	if level3_btn:
		level3_btn.pressed.connect(_on_level3_pressed)
		if _is_mobile_platform():
			level3_btn.custom_minimum_size = Vector2(200, 60)
			level3_btn.add_theme_font_size_override("font_size", 18)
	else:
		print("Ошибка: кнопка ButtonLevel3 не найдена!")
	
	if level4_btn:
		level4_btn.pressed.connect(_on_level4_pressed)
		if _is_mobile_platform():
			level4_btn.custom_minimum_size = Vector2(200, 60)
			level4_btn.add_theme_font_size_override("font_size", 18)
	else:
		print("Ошибка: кнопка ButtonLevel4 не найдена!")
	
	if level5_btn:
		level5_btn.pressed.connect(_on_level5_pressed)
		if _is_mobile_platform():
			level5_btn.custom_minimum_size = Vector2(200, 60)
			level5_btn.add_theme_font_size_override("font_size", 18)
	else:
		print("Ошибка: кнопка ButtonLevel5 не найдена!")

func _is_mobile_platform() -> bool:
	return OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios") or OS.has_feature("aurora")

func _setup_mobile_ui():
	var buttons = get_tree().get_nodes_in_group("menu_buttons")
	for btn in buttons:
		if btn is Button:
			btn.custom_minimum_size = Vector2(200, 60)
			btn.add_theme_font_size_override("font_size", 18)
	
	if OS.has_feature("aurora"):
		print("🔵 Дополнительная оптимизация для ОС Аврора")
		_optimize_for_aurora()

func _setup_pc_ui():
	var buttons = get_tree().get_nodes_in_group("menu_buttons")
	for btn in buttons:
		if btn is Button:
			btn.custom_minimum_size = Vector2(150, 40)
			btn.add_theme_font_size_override("font_size", 14)
	
	var stylebox = StyleBoxFlat.new()
	stylebox.set_corner_radius_all(5)
	stylebox.bg_color = Color(0.2, 0.2, 0.3)
	
	for btn in buttons:
		if btn is Button:
			btn.add_theme_stylebox_override("normal", stylebox)
			btn.add_theme_stylebox_override("hover", stylebox)
			
			var hover_stylebox = StyleBoxFlat.new()
			hover_stylebox.set_corner_radius_all(5)
			hover_stylebox.bg_color = Color(0.3, 0.3, 0.4)
			btn.add_theme_stylebox_override("hover", hover_stylebox)

func _optimize_for_aurora():
	var stylebox = StyleBoxFlat.new()
	stylebox.set_corner_radius_all(10)
	
	var buttons = get_tree().get_nodes_in_group("menu_buttons")
	for btn in buttons:
		if btn is Button:
			btn.add_theme_stylebox_override("normal", stylebox)

func _input(event):
	if event is InputEventScreenTouch and event.pressed:
		_show_touch_feedback(event.position)

func _show_touch_feedback(position: Vector2):
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

func _on_level1_pressed():
	print("🎮 Загрузка уровня 1")
	get_tree().change_scene_to_file(level1_scene)

func _on_level2_pressed():
	print("🎮 Загрузка уровня 2")
	get_tree().change_scene_to_file(level2_scene)

func _on_level3_pressed():
	print("🎮 Загрузка уровня 3")
	get_tree().change_scene_to_file(level3_scene)

func _on_level4_pressed():
	print("🎮 Загрузка уровня 4")
	get_tree().change_scene_to_file(level4_scene)

func _on_level5_pressed():
	print("🎮 Загрузка уровня 5")
	get_tree().change_scene_to_file(level5_scene)
