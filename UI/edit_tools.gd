extends Control
class_name EditTools

## UI control for editing placed bodies
## Displays the body's name and has move and delete buttons


@onready var body_name : Label = $BodyName
@onready var move_button : TextureRect = $HBox/MoveButton
@onready var trash_button : TextureRect = $HBox/TrashButton

signal pressed_move
signal pressed_delete


# UTILS
# -------------------------------------------------

func set_body_name(new_name : String) -> void:
	body_name.text = new_name


# SIGNAL CALLBACKS
# -------------------------------------------------

func _on_move_button_mouse_entered() -> void:
	move_button.modulate = Color.GREEN

func _on_move_button_mouse_exited() -> void:
	move_button.modulate = Color.WHITE

func _on_move_button_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			emit_signal("pressed_move")

func _on_trash_button_mouse_entered() -> void:
	trash_button.modulate = Color.RED

func _on_trash_button_mouse_exited() -> void:
	trash_button.modulate = Color.WHITE

func _on_trash_button_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			emit_signal("pressed_delete")
