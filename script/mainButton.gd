extends Control

@export var new_game_scene: String = "res://scene/NewGameMenu.tscn"
@export var import_game_scene: String = "res://scene/ImportGameMenu.tscn" 

func _ready():
	$ButtonNewGane.pressed.connect(_on_new_game_pressed)
	$ButtonImportGame.pressed.connect(_on_import_game_pressed)
	$ButtonQuit.pressed.connect(_on_quit_pressed)

func _on_new_game_pressed():
	get_tree().change_scene_to_file(new_game_scene)

func _on_import_game_pressed():
	get_tree().change_scene_to_file(import_game_scene)

func _on_quit_pressed():
	get_tree().quit()
