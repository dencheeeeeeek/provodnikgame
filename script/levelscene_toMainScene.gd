extends Control

@export var target_scene: String = "res://scene/mainscene.tscn"


func _ready():
	if OS.has_feature("aurora") or OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios"):
		_setup_mobile()
	else:
		_setup_pc()
	
	var button = get_node_or_null("BackButton")
	if button:
		button.pressed.connect(_on_back_pressed)
	else:
		print("Ошибка: кнопка BackButton не найдена внутри Control")

func _setup_mobile():
	var button = get_node_or_null("BackButton")
	if button:
		button.custom_minimum_size = Vector2(200, 60)
		button.add_theme_font_size_override("font_size", 18)
	
	if OS.has_feature("aurora"):
		var stylebox = StyleBoxFlat.new()
		stylebox.set_corner_radius_all(10)
		if button:
			button.add_theme_stylebox_override("normal", stylebox)

func _setup_pc():
	var button = get_node_or_null("BackButton")
	if button:
		button.custom_minimum_size = Vector2(150, 40)
		button.add_theme_font_size_override("font_size", 14)
		
		var stylebox = StyleBoxFlat.new()
		stylebox.set_corner_radius_all(5)
		stylebox.bg_color = Color(0.2, 0.2, 0.3)
		button.add_theme_stylebox_override("normal", stylebox)
		
		var hover_stylebox = StyleBoxFlat.new()
		hover_stylebox.set_corner_radius_all(5)
		hover_stylebox.bg_color = Color(0.3, 0.3, 0.4)
		button.add_theme_stylebox_override("hover", hover_stylebox)

func _on_back_pressed():
	print("🔙 Возврат назад")
	if target_scene != "":
		get_tree().change_scene_to_file(target_scene)
	else:
		get_tree().change_scene_to_file("res://scene/mainscene.tscn")
