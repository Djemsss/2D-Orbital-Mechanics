extends GravityBody
class_name Star

## Represents an unmoving star which has a gravitational field


const EDIT_TOOL_PADDING: Vector2 = Vector2(70, 70)

var STAR_TYPES : Dictionary = {
	0:  {"name": "Yellow Dwarf"},
	1:  {"name": "Orange Dwarf"},
	2:  {"name": "Red Dwarf"},
	3 : {"name": "Blue Giant"}
}

var type : int = 0
var size : float = 1.0

@onready var sprite : AnimatedSprite2D = $Sprite
@onready var collision_shape_2d : CollisionShape2D = $Area2D/CollisionShape2D
@onready var edit_tools : EditTools = $EditTools

signal selected_body(GravityBody)
signal body_deleted(GravityBody)
signal body_move(GravityBody)


# SETUP & STATE
# -------------------------------------------------

func place():
	placed = true
	collision_shape_2d.set_deferred("disabled", false)

func set_type(newType : int) -> void:
	type = STAR_TYPES.size() - 1 - newType
	sprite.frame = type
	var newScale = type + 2 + randf_range(-0.2, 0.2)
	resize(newScale)
	edit_tools.set_body_name(STAR_TYPES[type].name)

func resize(newScale : float) -> void:
	size = newScale
	sprite.scale = Vector2(newScale, newScale) / 5.5
	collision_shape_2d.shape.radius = sprite_base_size.x * newScale / 2
	
	edit_tools.size = sprite_base_size * newScale + EDIT_TOOL_PADDING
	edit_tools.position = Vector2(-edit_tools.size.x / 2, -edit_tools.size.y / 2)

func select() -> void:
	edit_tools.show()

func unselect() -> void:
	edit_tools.hide()


# SIGNAL CALLBACKS
# -------------------------------------------------

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

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Debris or (body is Satellite and body.placed):
		body.queue_free()
