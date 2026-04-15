extends Button

func _pressed():
	# Обязательно проверь, что файл называется именно так в твоей папке!
	get_tree().change_scene_to_file("res://scene/levelScene.tscn")
