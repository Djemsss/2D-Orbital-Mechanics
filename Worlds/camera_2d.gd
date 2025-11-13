extends Camera2D

var dragging : bool = false
var locked : bool = false

var bg_tween : Tween

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
			var current_bg_offset = $StarBG.material.get_shader_parameter("world_offset")
			current_bg_offset -= event.relative * 0.002
			$StarBG.material.set_shader_parameter("world_offset", current_bg_offset)
