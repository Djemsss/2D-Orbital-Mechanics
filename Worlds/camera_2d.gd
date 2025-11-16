extends Camera2D

@export var horizontal_limit : int = 1500
@export var vertical_limit : int = 1900
@export var parallax_strength : float = 0.002

var dragging : bool = false
var locked : bool = false

@onready var star_bg : TextureRect = $StarBG


# INPUT
# -------------------------------------------------

func _input(event: InputEvent) -> void:
	# Handles camera dragging and background parallax
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				dragging = true
			else:
				dragging = false
	if event is InputEventMouseMotion and not locked:
		if dragging:
			var newPos = global_position - event.relative 
			newPos.x = clamp(newPos.x, -horizontal_limit, horizontal_limit)
			newPos.y = clamp(newPos.y, -vertical_limit, vertical_limit)
			global_position = newPos
			
			var current_bg_offset = star_bg.material.get_shader_parameter("world_offset")
			current_bg_offset -= event.relative * parallax_strength
			star_bg.material.set_shader_parameter("world_offset", current_bg_offset)
