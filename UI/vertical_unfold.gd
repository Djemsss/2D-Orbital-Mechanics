extends Control
class_name VerticalUnfold

@export var fold_animation_time : float = 0.2
@export var element_names : Array[String] = []

const BASE_HEIGHT : int = 80

var folded : bool = true

@onready var tween : Tween
@onready var panel : Panel = $Panel
@onready var deploy_button : Panel = $Panel/DeployButton
@onready var vbox : VBoxContainer = $Panel/VBox

signal unfolded(vertical_unfold : VerticalUnfold)
signal pressed_button(idx : int)

func _ready() -> void:
	grow_vertical = Control.GROW_DIRECTION_BOTH
	deploy_button.gui_input.connect(Callable(fold_button_input))
	
	for button : Panel in vbox.get_children():
		button.mouse_entered.connect(Callable(element_button_mouse_in).bind(button.get_index()))
		button.mouse_exited.connect(Callable(element_button_mouse_out).bind(button.get_index()))
		button.gui_input.connect(Callable(element_button_input).bind(button.get_index()))


# SIGNAL CALLBACKS
# -------------------------------------------------

func fold_button_input(event : InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			toggle_fold()
			emit_signal("unfolded", self)

func element_button_input(event : InputEvent, button_idx : int) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			emit_signal("pressed_button", button_idx)
			toggle_fold()

func element_button_mouse_in(idx : int) -> void:
	$HintLabel.text = element_names[idx]
	$HintLabel.global_position.x = vbox.get_child(idx).global_position.x + BASE_HEIGHT + 10
	$HintLabel.global_position.y = vbox.get_child(idx).global_position.y + BASE_HEIGHT / 2 - $HintLabel.custom_minimum_size.y / 2
	$HintLabel.show()

func element_button_mouse_out(idx : int) -> void:
	$HintLabel.hide()

# UI
# -------------------------------------------------

func toggle_fold():
	var vbox_child_count = vbox.get_child_count()
	var new_height = (BASE_HEIGHT + BASE_HEIGHT * vbox_child_count + 2 * vbox_child_count) if folded else BASE_HEIGHT
	deploy_button.get_child(folded).show()
	deploy_button.get_child(!folded).hide()
	folded = !folded
	var delta = new_height - panel.size.y
	
	if tween and tween.is_running():
		tween.kill()
	tween = create_tween()
	
	tween.tween_property(panel, "position:y", panel.position.y - delta, fold_animation_time).set_trans(Tween.TRANS_BOUNCE)
	tween.parallel().tween_property(panel, "size:y", new_height, fold_animation_time).set_trans(Tween.TRANS_BOUNCE)
	
