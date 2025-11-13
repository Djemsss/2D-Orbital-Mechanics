extends Node2D

const star_scene = preload("res://Elements/star.tscn")
const satellite_scene = preload("res://Elements/satellite.tscn")

@export var placing_mode_time := 0.2

enum PlacementState { NONE, PLACING_STAR, PLACING_SATELLITE }
var placement_state: PlacementState = PlacementState.NONE

var placing: Node2D = null
var placing_type : int = 0
var tween: Tween = null
var selected_body: GravityBody = null
var started_drag: Vector2 = Vector2.ZERO
var base_actionbar_y := 0.0

var celestial_bodies : Array[GravityBody] = []

@onready var drag_line: Line2D = $DragLine
@onready var camera: Camera2D = $Camera2D
@onready var action_bar: Control = $CanvasLayer/Control/ActionBar


# PROCESSING
# -------------------------------------------------

func _ready() -> void:
	base_actionbar_y = action_bar.position.y

func _physics_process(delta: float) -> void:
	for sat: Satellite in $Elements/Satellites.get_children():
		if sat.placed:
			process_sat_gravity(sat, delta, celestial_bodies)
			sat.process_trail()
	
	for debris : Debris in $Elements/Debris.get_children():
		process_debris_gravity(debris, delta, celestial_bodies)

func process_sat_gravity(sat : Satellite, delta : float, bodyList : Array):
	for body in bodyList:
		
		var gravity_dir = (body.global_position - sat.global_position).normalized()		
		var force = Global.gravitational_constant * sat.mass * body.mass / (sat.global_position.distance_squared_to(body.global_position))
		var acceleration = force / sat.mass
		sat.velocity += gravity_dir * acceleration * delta
		
	if sat.move_and_slide():
		var collision = sat.get_last_slide_collision()
		var collider = collision.get_collider()
		if (collider is Satellite and collider.placed):
			sat.destroy(true)
			collider.destroy(true)
		elif collider is Debris:
			sat.destroy(true)

func process_debris_gravity(debris : Debris, delta : float, bodyList : Array):
	for body in bodyList:
		var gravity_dir = (body.global_position - debris.global_position).normalized()		
		var force = Global.gravitational_constant * debris.mass * body.mass / (debris.global_position.distance_squared_to(body.global_position))
		var acceleration = force / debris.mass
		debris.velocity += gravity_dir * acceleration * delta
		
	debris.move_and_slide()
	
	for i in range(debris.get_slide_collision_count()):
		var col = debris.get_slide_collision(i)
		var other = col.get_collider()
		if other is Debris and other != debris:
			# Vel blending
			var combined = (debris.velocity * debris.mass + other.velocity * other.mass) / (debris.mass + other.mass)
			
			debris.velocity = lerp(debris.velocity, combined, 0.2)
			other.velocity = lerp(other.velocity, combined, 0.2)

func predict_orbit_path(start_pos: Vector2, start_vel: Vector2, bodies: Array, duration := 5.0, step := 0.1) -> PackedVector2Array:
	var points : PackedVector2Array = [start_pos]
	var pos = start_pos
	var vel = start_vel

	for t in range(int(duration / step)):
		var acc = Vector2.ZERO
		for body in bodies:
			var dir = (body.global_position - pos)
			var dist_sq = dir.length_squared()
			if dist_sq == 0:
				continue
			acc += (Global.gravitational_constant * body.mass / dist_sq) * dir.normalized()
		
		vel += acc * step
		pos += vel * step
		points.append(pos)
	
	return points

func update_orbit_preview(mouse_pos: Vector2):
	if not is_instance_valid(placing):
		return
	if started_drag == Vector2.ZERO:
		$OrbitPreview.clear_points()
		return

	var end_pos = mouse_pos
	var drag_length = started_drag.distance_to(end_pos)
	var drag_dir = end_pos.direction_to(started_drag)
	var launch_velocity = drag_length * drag_dir

	var start_pos = placing.global_position
	var bodies = $Elements/Stars.get_children().filter(func(b): return b.placed)
	var predicted_points = predict_orbit_path(start_pos, launch_velocity, bodies, 5.0, 0.02)
	
	$OrbitPreview.clear_points()
	$OrbitPreview.points = predicted_points

func add_gravity_body(body: GravityBody):
	celestial_bodies.append(body)
	update_gravity_grid(celestial_bodies)

func update_gravity_grid(bodies : Array[GravityBody]):
	var mat := $Gravity_Grid.material as ShaderMaterial
	var count = min(bodies.size(), 16)
	mat.set_shader_parameter("point_count", count)
	
	var points_array = []
	var masses_array = []
	
	for i in range(16):
		if i < count:
			points_array.append(bodies[i].global_position)
			masses_array.append(remap(bodies[i].mass, 1000, 1000000, 0, 800))
		else:
			# Clear unused elements
			points_array.append(Vector2.ZERO)
			masses_array.append(0.0)
			
	mat.set_shader_parameter("points", points_array)
	mat.set_shader_parameter("masses", masses_array)

# INPUT HANDLING
# -------------------------------------------------

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if placing:
			placing.queue_free()
			end_placing_mode(true)
		clear_selection()
		return
		
	if get_viewport().gui_get_hovered_control() and get_viewport().gui_get_hovered_control().mouse_filter == Control.MOUSE_FILTER_STOP:
		return
	if placement_state in [PlacementState.PLACING_STAR, PlacementState.PLACING_SATELLITE]:
		if event is InputEventMouseMotion:
			if started_drag == Vector2.ZERO:
				if is_instance_valid(placing):
					placing.global_position = get_global_mouse_position()
					
					
					if placing is GravityBody:
						var warp_bodies = celestial_bodies.duplicate()
						warp_bodies.append(placing)
						update_gravity_grid(warp_bodies)
			else:
				update_drag_line(get_global_mouse_position())
				update_orbit_preview(get_global_mouse_position())

		elif event is InputEventMouseButton:
			handle_mouse_button(event)

func handle_mouse_button(event: InputEventMouseButton) -> void:
	match placement_state:
		PlacementState.PLACING_STAR:
			handle_star_placing(event)
		PlacementState.PLACING_SATELLITE:
			handle_satellite_launch(event)

func handle_star_placing(event: InputEventMouseButton) -> void:
	if not is_instance_valid(placing):
		return

	if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var body := placing as GravityBody
		if body:
			body.selected_body.connect(Callable(clicked_body))
			body.body_deleted.connect(Callable(body_deleted))
			body.body_move.connect(Callable(body_move))
			body.place()
			finalize_placing()


func handle_satellite_launch(event: InputEventMouseButton) -> void:
	if not is_instance_valid(placing):
		return
	if event.button_index != MOUSE_BUTTON_LEFT:
		return
	if event.pressed:
		if $CanvasLayer/Control/Panel/VBox/AutoOrbitsToggle.button_pressed:
			# Auto circular orbit launch
			var mouse_pos = get_global_mouse_position()
			var closest = find_closest_body(mouse_pos)
			var vel = calculate_launch_velocity(mouse_pos, closest.global_position, closest.mass) if closest != null else Vector2.ZERO
			placing.velocity = vel
			placing.spawned_debris.connect(Callable(debris_spawned))
			finalize_placing()
		else:
			# Begin drag for launch
			started_drag = get_global_mouse_position()
			reset_drag_line(started_drag)
	else:
		if started_drag != Vector2.ZERO:
			# Drag release to set launch velocity
			var end_pos = get_global_mouse_position()
			var drag_length = started_drag.distance_to(end_pos)
			var drag_dir = end_pos.direction_to(started_drag)
			placing.velocity = drag_length * drag_dir
			placing.spawned_debris.connect(Callable(debris_spawned))
			finalize_placing()


# UTILS
# -------------------------------------------------

func calculate_launch_velocity(satellite_pos: Vector2, planet_pos: Vector2, planet_mass: float) -> Vector2:
	var gravity_direction = (planet_pos - satellite_pos).normalized()
	var distance = satellite_pos.distance_to(planet_pos)
	var launch_speed = sqrt(Global.gravitational_constant * planet_mass / distance)

	var rotated_dir = Vector2.ZERO
	if $CanvasLayer/Control/Panel/VBox/OrbitDirectionToggle.button_pressed:
		rotated_dir = Vector2(-gravity_direction.y, gravity_direction.x)
	else:
		rotated_dir = Vector2(gravity_direction.y, -gravity_direction.x)

	return launch_speed * rotated_dir


func find_closest_body(pos: Vector2) -> GravityBody:
	var closest: GravityBody = null
	var min_dist := INF
	for body: GravityBody in $Elements/Stars.get_children():
		var dist = body.global_position.distance_to(pos)
		if dist < min_dist:
			min_dist = dist
			closest = body
	return closest


func finalize_placing() -> void:
	if not is_instance_valid(placing):
		return
	placing.place()
	started_drag = Vector2.ZERO
	drag_line.clear_points()
	$OrbitPreview.clear_points()
	
	if placing is GravityBody:
		print("Placing")
		add_gravity_body(placing)
	
	end_placing_mode()

func clear_selection() -> void:
	if selected_body:
		selected_body.unselect()
		selected_body = null

func clicked_body(body: GravityBody) -> void:
	if placing:
		return
	clear_selection()
	selected_body = body
	selected_body.select()

func body_deleted(body):
	selected_body = null
	if body in celestial_bodies:
		celestial_bodies.erase(body)
	update_gravity_grid(celestial_bodies)

func body_move(body):
	var new_state = PlacementState.PLACING_STAR if body is GravityBody else PlacementState.PLACING_SATELLITE
	start_placing_mode(new_state)
	body.unselect()
	body.selected_body.disconnect(Callable(clicked_body))
	body.body_deleted.disconnect(Callable(body_deleted))
	body.body_move.disconnect(Callable(body_move))
	placing = body


# PLACEMENT STATE MANAGEMENT
# -------------------------------------------------

func start_placing_mode(type: PlacementState) -> void:
	if placement_state == type:
		return
	placement_state = type
	show_action_bar(false)

func end_placing_mode(force := false) -> void:
	var continuous = $CanvasLayer/Control/Panel/VBox/ContinuosPlacementToggle.button_pressed

	if force or not continuous:
		placement_state = PlacementState.NONE
		placing = null
		show_action_bar(true)
	else:
		match placement_state:
			PlacementState.PLACING_STAR:
				_on_star_unfold_pressed_button(placing_type)
			PlacementState.PLACING_SATELLITE:
				_on_satellite_unfold_pressed_button(placing_type)

func show_action_bar(visible: bool) -> void:
	var target_y = base_actionbar_y + (0 if visible else 120)
	if tween and tween.is_running():
		tween.kill()
	tween = create_tween()
	tween.tween_property(action_bar, "position:y", target_y, placing_mode_time)
	tween.finished.connect(func(): tween = null)


# DRAG LINE
# -------------------------------------------------

func reset_drag_line(start_pos: Vector2) -> void:
	drag_line.clear_points()
	drag_line.add_point(start_pos)
	drag_line.add_point(start_pos)

func update_drag_line(pos: Vector2) -> void:
	if drag_line.points.size() < 2:
		drag_line.add_point(pos)
	else:
		drag_line.set_point_position(1, pos)


# SIGNAL CALLBACKS
# -------------------------------------------------

func _on_satellite_unfold_pressed_button(idx: Variant) -> void:
	clear_selection()
	start_placing_mode(PlacementState.PLACING_SATELLITE)
	var new_sat = satellite_scene.instantiate()
	$Elements/Satellites.add_child(new_sat)
	placing_type = idx
	placing = new_sat

func _on_star_unfold_pressed_button(idx: Variant) -> void:
	clear_selection()
	start_placing_mode(PlacementState.PLACING_STAR)
	var new_star = star_scene.instantiate()
	new_star.global_position = get_global_mouse_position()
	$Elements/Stars.add_child(new_star)
	new_star.set_type(idx)
	placing_type = idx
	placing = new_star

func debris_spawned(debris : Debris):
	$Elements/Debris.call_deferred("add_child", debris)

func vertical_unfolder_unfolded(unfolder: VerticalUnfold) -> void:
	for v_unfold: VerticalUnfold in $CanvasLayer/Control/ActionBar/HBox.get_children():
		if not v_unfold.folded and v_unfold != unfolder:
			v_unfold.toggle_fold()
