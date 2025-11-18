extends GravityBody
class_name Planet

## Represents an unmoving planet which has a gravitational field


const EDIT_TOOL_PADDING: Vector2 = Vector2(70, 70)

var PLANET_TYPES : Dictionary = {
	0:  {"name": "Arid Planet"},
	1:  {"name": "Earth Like Planet"},
	2:  {"name": "Cratered Planet"},
	3 : {"name": "Deserted Planet"},
	4 : {"name": "Frozen Planet"},
	5 : {"name": "Moon"},
	6 : {"name": "Lava Planet"},
	7 : {"name": "Water Planet"},
	8 : {"name": "Wet Planet"},
	9 : {"name": "Barren Planet"}
}

var type : int = 0
var size : float = 1.0

@onready var sprite : AnimatedSprite2D = $Sprite
@onready var atmosphere : Sprite2D = $Atmosphere
@onready var collision_shape_2d : CollisionShape2D = $Area2D/CollisionShape2D
@onready var light_occluder : LightOccluder2D = $LightOccluder2D
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
	type = newType
	sprite.frame = type
	var newScale = 2 + randf_range(-0.5, 0.5)
	resize(newScale)
	edit_tools.set_body_name(PLANET_TYPES[type].name)

func resize(newScale : float) -> void:
	size = newScale
	sprite.scale = Vector2(newScale, newScale) / 5.5
	collision_shape_2d.shape.radius = sprite_base_size.x * newScale / 2 + newScale * 6
	
	atmosphere.scale = Vector2(newScale, newScale) / 12
	light_occluder.scale = Vector2(newScale, newScale) * 2
	
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
