extends Node

var current_level: int = 1
# Тут можно будет хранить, какие уровни открыты:
var unlocked_levels: int = 1
# Автозагружаемый скрипт для глобального состояния
static var current_tool := "select"
static var is_drawing_wire := false

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
