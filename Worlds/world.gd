extends Node2D

const star_scene = preload("res://Elements/star.tscn")
const satellite_scene = preload("res://Elements/satellite.tscn")

@export var placing_mode_time = 0.2

var placing : Node2D = null
var tween : Tween = null
var selected_body : GravityBody = null
var started_drag : Vector2 = Vector2.ZERO

@onready var drag_line = $DragLine

func _process(delta: float) -> void:
	var bodies = $Elements/Stars.get_children()
	for sat : Satellite in $Elements/Satellites.get_children():
		if sat.placed:
			sat.process_gravity(delta, bodies)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if placing:
			placing.queue_free()
			placing = null
			end_placing_mode()
		clear_selection()
		return
		
	if placing and event is InputEventMouseMotion:
		if started_drag == Vector2.ZERO:
			placing.global_position = event.position
		else:
			update_drag_line(event.position)
		
	if event is InputEventMouseButton:
		handle_mouse_button(event)


# SIGNAL CALLBACKS
# -------------------------------------------------

func _on_satellite_unfold_pressed_button(idx: Variant) -> void:
	clear_selection()
	start_placing_mode()
	var newSatellite = satellite_scene.instantiate()
	$Elements/Satellites.add_child(newSatellite)
	placing = newSatellite

func _on_star_unfold_pressed_button(idx: Variant) -> void:
	clear_selection()
	start_placing_mode()
	var newStar = star_scene.instantiate()
	newStar.set_type(idx)
	newStar.global_position = get_global_mouse_position()
	$Elements/Stars.add_child(newStar)
	placing = newStar


# INPUT HANDLING & GAME LOGIC
# -------------------------------------------------

func handle_mouse_button(event : InputEvent):
	if event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if placing:
				if placing is GravityBody:
					placing.selected_body.connect(Callable(clicked_body))
					placing.body_deleted.connect(Callable(body_deleted))
					placing.body_move.connect(Callable(body_move))
					placing.placed = true
					placing = null
					end_placing_mode()
				elif placing is Satellite:
					started_drag = get_global_mouse_position()
					update_drag_line(started_drag)
		elif not event.pressed:
			if placing is Satellite and started_drag != Vector2.ZERO:
				var drag_length = started_drag.distance_to(get_global_mouse_position())
				var drag_direction = get_global_mouse_position().direction_to(started_drag)
				placing.velocity = drag_length * drag_direction
				placing.placed = true
				placing = null
				end_placing_mode()
				started_drag = Vector2.ZERO
				drag_line.clear_points()

func clicked_body(body : GravityBody) -> void:
	clear_selection()
	selected_body = body
	selected_body.select()

func body_deleted(body):
	selected_body = null

func body_move(body):
	start_placing_mode()
	body.unselect()
	body.selected_body.disconnect(Callable(clicked_body))
	body.body_deleted.disconnect(Callable(body_deleted))
	body.body_move.disconnect(Callable(body_move))
	placing = body


# UI
# -------------------------------------------------

func start_placing_mode() -> void:
	move_action_bar(120)

func end_placing_mode() -> void:
	move_action_bar(-120)

func move_action_bar(offset: float) -> void:
	if tween and tween.is_running():
		tween.kill()
	tween = create_tween()
	tween.tween_property($CanvasLayer/Control/ActionBar, "position:y",
		$CanvasLayer/Control/ActionBar.position.y + offset, placing_mode_time)

func clear_selection() -> void:
	if selected_body:
		selected_body.unselect()
		selected_body = null

func update_drag_line(pos: Vector2) -> void:
	if drag_line.points.size() < 2:
		drag_line.add_point(pos)
	else:
		drag_line.set_point_position(1, pos)
