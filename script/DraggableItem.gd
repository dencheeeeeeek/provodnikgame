extends TextureRect

signal item_dropped(world_position: Vector2, item_data: Dictionary)

var item_data: Dictionary = {}
var is_dragging := false

func _ready():
	mouse_filter = Control.MOUSE_FILTER_PASS

func _get_drag_data(at_position: Vector2):
	is_dragging = true
	
	var preview = TextureRect.new()
	preview.texture = texture
	preview.size = size
	
	set_drag_preview(preview)
	
	return {"type": "drag_item", "item_data": item_data}

func _can_drop_data(position: Vector2, data):
	return false

func _drop_data(position: Vector2, data):
	pass

func _input(event: InputEvent):
	if is_dragging and event is InputEventMouseButton and not event.pressed:
		is_dragging = false
		var world_position = get_global_mouse_position()
		var gameworld = get_tree().current_scene.get_node_or_null("GameWorld")
		
		
		
		if gameworld:
			emit_signal("item_dropped", world_position, item_data)
			queue_free()
