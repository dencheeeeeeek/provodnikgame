extends Button # Или TextureButton, если используешь свои PNG

# Эти переменные появятся в инспекторе справа
@export_file("*.tscn") var scene_to_load # Путь к сцене уровня
@export var level_id: int = 1            # Номер уровня

func _ready():
	# Соединяем сигнал нажатия на саму себя с функцией
	self.pressed.connect(_on_level_button_pressed)

func _on_level_button_pressed():
	if scene_to_load != "":
		# Сохраняем номер уровня в глобальный GameState, чтобы игра знала, что загружать
		GameState.current_level = level_id
		
		# Загружаем сцену
		get_tree().change_scene_to_file(scene_to_load)
		print("Загрузка уровня: ", level_id)
	else:
		print("Ошибка: Путь к сцене не задан в инспекторе!")
