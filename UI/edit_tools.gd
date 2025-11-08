extends Control

signal pressed_move
signal pressed_delete

func _on_move_button_mouse_entered() -> void:
	$HBox/MoveButton.modulate = Color.GREEN

func _on_move_button_mouse_exited() -> void:
	$HBox/MoveButton.modulate = Color.WHITE

func _on_move_button_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			emit_signal("pressed_move")

func _on_trash_button_mouse_entered() -> void:
	$HBox/TrashButton.modulate = Color.RED

func _on_trash_button_mouse_exited() -> void:
	$HBox/TrashButton.modulate = Color.WHITE

func _on_trash_button_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			emit_signal("pressed_delete")
