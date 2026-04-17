extends Node

var current_level: int = 1
var unlocked_levels: int = 1

# Состояние инструментов (выбор предмета в меню)
var current_tool := "select"
var is_drawing_wire := false

# Ссылка на UI (CanvasLayer), чтобы менеджер мог найти кнопки
var canvas_menu: CanvasLayer = null

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
