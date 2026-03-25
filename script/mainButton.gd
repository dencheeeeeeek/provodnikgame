extends Control

@export var new_game_scene: String = "res://scene/NewGameMenu.tscn"
@export var import_game_scene: String = "res://scene/ImportGameMenu.tscn"

func _ready():
	# Проверяем, что кнопки существуют, и подключаем сигналы
	if has_node("ButtonNewGame"):
		$ButtonNewGame.pressed.connect(_on_new_game_pressed)
	else:
		print("Ошибка: кнопка ButtonNewGame не найдена!")
	
	if has_node("ButtonImportGame"):
		$ButtonImportGame.pressed.connect(_on_import_game_pressed)
	else:
		print("Ошибка: кнопка ButtonImportGame не найдена!")
	
	if has_node("ButtonQuit"):
		$ButtonQuit.pressed.connect(_on_quit_pressed)
	else:
		print("Ошибка: кнопка ButtonQuit не найдена!")

func _on_new_game_pressed():
	print("Нажата кнопка Новая игра")
	get_tree().change_scene_to_file(new_game_scene)

func _on_import_game_pressed():
	print("Нажата кнопка Импорт игры")
	get_tree().change_scene_to_file(import_game_scene)

func _on_quit_pressed():
	print("Выход из игры")
	get_tree().quit()
