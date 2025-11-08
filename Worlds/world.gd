extends Node2D

@export var placing_mode_time = 0.2

const star_scene = preload("res://Elements/star.tscn")

var placing = null
var tween : Tween

var selected_body = null

func _on_star_unfold_pressed_button(idx: Variant) -> void:
	if selected_body:
		selected_body.unselect()
		selected_body = null
	start_placing_mode()
	var newStar = star_scene.instantiate()
	newStar.set_type(idx)
	newStar.global_position = get_global_mouse_position()
	$Elements/Stars.add_child(newStar)
	placing = newStar

func clicked_body(body : GravityBody):
	if selected_body:
		selected_body.unselect()
	selected_body = body
	selected_body.select()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if placing:
			placing.queue_free()
			placing = null
			end_placing_mode()
		elif selected_body:
			selected_body.unselect()
			selected_body = null
	if placing and event is InputEventMouseMotion:
		placing.global_position = event.position
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if placing:
				placing.selected_body.connect(Callable(clicked_body))
				placing.body_deleted.connect(Callable(body_deleted))
				placing.body_move.connect(Callable(body_move))
				placing.placed = true
				placing = null
				end_placing_mode()

func body_deleted(body):
	selected_body = null

func body_move(body):
	start_placing_mode()
	body.unselect()
	body.selected_body.disconnect(Callable(clicked_body))
	body.body_deleted.disconnect(Callable(body_deleted))
	body.body_move.disconnect(Callable(body_move))
	placing = body

func start_placing_mode():
	if tween and tween.is_running():
		tween.kill()
	tween = create_tween()
	tween.tween_property($CanvasLayer/Control/ActionBar, "position:y", $CanvasLayer/Control/ActionBar.position.y + 120, placing_mode_time)

func end_placing_mode():
	if tween and tween.is_running():
		tween.kill()
	tween = create_tween()
	tween.tween_property($CanvasLayer/Control/ActionBar, "position:y", $CanvasLayer/Control/ActionBar.position.y - 120, placing_mode_time)
