extends Camera2D

var dragging : bool = false
var locked : bool = false

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				dragging = true
			else:
				dragging = false
	if event is InputEventMouseMotion and not locked:
		if dragging:
			global_position -= event.relative
