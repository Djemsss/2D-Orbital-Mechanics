extends GravityBody

var STAR_TYPES : Dictionary = {
	0:  {"name": "Yellow Dwarf"},
	1:  {"name": "Orange Dwarf"},
	2:  {"name": "Red Dwarf"},
	3 : {"name": "Blue Giant"}
}

var type : int

signal selected_body(GravityBody)
signal body_deleted(GravityBody)
signal body_move(GravityBody)

func set_type(newType : int):
	type = STAR_TYPES.size() - 1 - newType
	$Sprite.frame = type
	var newScale = (type + 2 + randf_range(-0.2, 0.2))
	$Sprite.scale = Vector2(newScale, newScale)
	$Area2D/CollisionShape2D.shape.radius = sprite_base_size.x * newScale
	
	$EditTools.size = sprite_base_size * newScale + Vector2(70, 70)
	$EditTools.position = Vector2(-$EditTools.size.x / 2, -$EditTools.size.y / 2)
	$EditTools/BodyName.text = STAR_TYPES[type].name

func select():
	$EditTools.show()

func unselect():
	$EditTools.hide()

func _on_area_2d_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if not placed:
		return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			emit_signal("selected_body", self)

func _on_edit_tools_pressed_delete() -> void:
	emit_signal("body_deleted", self)
	queue_free()

func _on_edit_tools_pressed_move() -> void:
	emit_signal("body_move", self)
