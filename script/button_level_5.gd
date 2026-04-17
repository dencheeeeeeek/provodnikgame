extends Button

# Путь к сцене первого уровня. Убедись, что имя файла совпадает!
@export var level_path : String = "res://scene/level_5.tscn"

func _pressed():
	# Сообщаем глобальному скрипту, что мы на уровне 1
	GameState.current_level = 1
	
	# Переходим на сцену
	var error = get_tree().change_scene_to_file(level_path)
	
	if error != OK:
		print("Ошибка: Не удалось загрузить сцену по пути: ", level_path)
