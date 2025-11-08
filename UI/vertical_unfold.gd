extends Control
class_name VerticalUnfold

@export var fold_time = 0.2

var folded = true
@onready var tween : Tween

signal pressed_button(idx)

func _ready() -> void:
	grow_vertical = Control.GROW_DIRECTION_BOTH
	$Panel/DeployButton.gui_input.connect(Callable(fold_button_input))
	
	for button : Panel in $Panel/VBox.get_children():
		button.gui_input.connect(Callable(element_button_input).bind(button.get_index()))

func fold_button_input(event : InputEvent):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			resize()

func element_button_input(event : InputEvent, button_idx):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			emit_signal("pressed_button", button_idx)
			resize()

func resize():
	var vbox_child_count = $Panel/VBox.get_child_count()
	var new_height = (120 + 120 * vbox_child_count + 2 * vbox_child_count) if folded else 120
	$Panel/DeployButton.get_child(folded).show()
	$Panel/DeployButton.get_child(!folded).hide()
	folded = !folded
	var delta = new_height - $Panel.size.y
	
	# Check if tween is already running, if so kill it
	if tween and tween.is_running():
		tween.kill()
	tween = create_tween()
	
	tween.tween_property($Panel, "position:y", $Panel.position.y - delta, fold_time).set_trans(Tween.TRANS_BOUNCE)
	tween.parallel().tween_property($Panel, "size:y", new_height, fold_time).set_trans(Tween.TRANS_BOUNCE)
	
