extends Node

# Автозагружаемый скрипт для глобального состояния
static var current_tool := "select"
static var is_drawing_wire := false

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
