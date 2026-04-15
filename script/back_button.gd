extends TextureButton # Проверь, чтобы тут было TextureButton, как на скриншоте!

func _pressed():
	# Эта команда выгружает текущую сцену и загружает главное меню
	# Проверь путь: если главное меню лежит в папке scene, добавь её в путь
	get_tree().change_scene_to_file("res://scene/mainscene.tscn")
