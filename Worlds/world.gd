extends Node2D
class_name World

## Main game scene


const planet_scene = preload("res://Elements/planet.tscn")
const star_scene = preload("res://Elements/star.tscn")
const satellite_scene = preload("res://Elements/satellite.tscn")

@export var placing_mode_time := 0.2

enum PlacementState { NONE, PLACING_PLANET, PLACING_STAR, PLACING_SATELLITE}
var placement_state : PlacementState = PlacementState.NONE

var TimewarpOptions : Array[float] = [0, 1, 2, 5]
var current_timewarp : float = 1.0
const STANDARD_DELTA = 1.0 / 60.0

var placing: Node2D = null
var placing_type : int = 0
var tween: Tween = null
var selected_body : GravityBody = null
var started_drag : Vector2 = Vector2.ZERO
var base_actionbar_y : float = 0.0

var trails_enabled : bool = true
var continuous_placement_enabled : bool = false
var auto_orbits_enabled : bool = false
var orbit_direction_reversed : bool = false
var lighting_enabled : bool = true

var celestial_bodies : Array[GravityBody] = []

@onready var drag_line : Line2D = $DragLine
@onready var orbit_preview : Line2D = $OrbitPreview
@onready var camera : Camera2D = $Camera2D
@onready var canvas_modulate : CanvasModulate = $CanvasModulate

@onready var option_panels : OptionPanels = $CanvasLayer/Control/OptionPanels
@onready var debug_panel : DebugPanel = $CanvasLayer/Control/DebugPanel
@onready var planet_settings : PlanetSettings = $CanvasLayer/Control/PlanetSettings 
@onready var action_bar : Panel = $CanvasLayer/Control/ActionBar

@onready var planet_holder : Node2D = $Elements/Planets
@onready var star_holder : Node2D = $Elements/Stars
@onready var satellite_holder : Node2D = $Elements/Satellites
@onready var debris_holder : Node2D = $Elements/Debris

@onready var gravity_grid : Sprite2D = $Gravity_Grid

@onready var click_SFX : AudioStreamPlayer = $SFX/Click
@onready var star_placement_SFX : AudioStreamPlayer = $SFX/StarPlacement
@onready var satellite_placement_SFX : AudioStreamPlayer = $SFX/SatellitePlacement
@onready var vanish_SFX : AudioStreamPlayer = $SFX/Vanish


# PROCESS
# -------------------------------------------------

func _ready() -> void:
	base_actionbar_y = action_bar.position.y
	
	# Connect buttons to click SFX
	var buttons : Array[Button] = []
	Global.find_nodes_of_class(get_tree().root, "Button", buttons)
	for button : Button in buttons:
		button.pressed.connect(Callable(click_SFX, "play"))
	
	# Connect option panel signals
	option_panels.trails_changed.connect(Callable(trails_changed))
	option_panels.gravity_grid_changed.connect(Callable(gravity_grid_changed))
	option_panels.timewarp_changed.connect(Callable(timewarp_changed))
	option_panels.clear_all.connect(Callable(clear_all))
	option_panels.continuous_placement_changed.connect(Callable(continuous_placement_changed))
	option_panels.auto_orbits_changed.connect(Callable(auto_orbits_changed))
	option_panels.orbit_direction_changed.connect(Callable(orbit_direction_changed))
	option_panels.lighting_changed.connect(Callable(lighting_changed))

func _physics_process(delta: float) -> void:
	simulate_orbits(delta)

func simulate_orbits(delta) -> void:
	# Simulates the orbits of all satellites and debris around celestial bodies and updates trails if needed
	# Handles timewarp by simulating multiple steps per physics frame if necessary 
	
	var steps_to_run = roundi(current_timewarp)
	for i in range(steps_to_run):
		for sat: Satellite in satellite_holder.get_children():
			sat.process_gravity(delta, celestial_bodies)
			if trails_enabled:
				sat.process_trail()
		
		for debris : Debris in debris_holder.get_children():
			debris.process_gravity(delta, celestial_bodies)

func predict_orbit_path(start_pos: Vector2, start_vel: Vector2, bodies: Array, duration := 5.0, step := 0.1) -> PackedVector2Array:
	# Orbit prediction to be displayed with the "orbit_preview" node
	
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

func update_orbit_preview(mouse_pos: Vector2) -> void:
	# Updates the orbit path preview when the player is dragging to launch a satellite
	
	if not is_instance_valid(placing):
		return
	if started_drag == Vector2.ZERO:
		orbit_preview.clear_points()
		return

	var end_pos = mouse_pos
	var drag_length = started_drag.distance_to(end_pos)
	var drag_dir = end_pos.direction_to(started_drag)
	var launch_velocity = drag_length * drag_dir

	var start_pos = placing.global_position
	var bodies = celestial_bodies #(star_holder.get_children() + planet_holder.get_children()).filter(func(b): return b.placed)
	var predicted_points = predict_orbit_path(start_pos, launch_velocity, bodies, 5.0, 0.02)
	
	orbit_preview.clear_points()
	orbit_preview.points = predicted_points

func add_gravity_body(body: GravityBody) -> void:
	celestial_bodies.append(body)
	update_gravity_grid(celestial_bodies)

func update_gravity_grid(bodies : Array[GravityBody]) -> void:
	# Updates the gravity grid shader to visualize gravitational fields
	
	var mat := gravity_grid.material as ShaderMaterial
	var count = min(bodies.size(), 16)
	mat.set_shader_parameter("point_count", count)
	
	var points_array = []
	var masses_array = []
	
	for i in range(16):
		if i < count:
			points_array.append(bodies[i].global_position)
			masses_array.append(bodies[i].mass / 1000)
		else:
			# Clear unused elements
			points_array.append(Vector2.ZERO)
			masses_array.append(0.0)
			
	mat.set_shader_parameter("points", points_array)
	mat.set_shader_parameter("masses", masses_array)


# INPUT HANDLING
# -------------------------------------------------

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed):
		if placing:
			placing.queue_free()
			end_placing_mode(true)
		clear_selection()
		return
	if placement_state != PlacementState.NONE:
		if get_viewport().gui_get_hovered_control() and get_viewport().gui_get_hovered_control().mouse_filter == Control.MOUSE_FILTER_STOP:
			return
	if placement_state != PlacementState.NONE:
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
		PlacementState.PLACING_PLANET:
			handle_planet_placing(event)
		PlacementState.PLACING_STAR:
			handle_star_placing(event)
		PlacementState.PLACING_SATELLITE:
			handle_satellite_launch(event)

func handle_planet_placing(event: InputEventMouseButton) -> void:
	if not is_instance_valid(placing):
		return
	if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var body : Planet = placing
		if body:
			body.selected_body.connect(Callable(clicked_body))
			body.body_deleted.connect(Callable(body_deleted))
			body.body_move.connect(Callable(body_move))
			body.place()
			star_placement_SFX.play()
			finalize_placing()

func handle_star_placing(event: InputEventMouseButton) -> void:
	if not is_instance_valid(placing):
		return
	if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var body : Star = placing
		if body:
			body.selected_body.connect(Callable(clicked_body))
			body.body_deleted.connect(Callable(body_deleted))
			body.body_move.connect(Callable(body_move))
			body.place()
			star_placement_SFX.play()
			finalize_placing()

func handle_satellite_launch(event: InputEventMouseButton) -> void:
	if not is_instance_valid(placing):
		return
	if event.button_index != MOUSE_BUTTON_LEFT:
		return
	if event.pressed:
		if option_panels.auto_orbits_toggle.button_pressed:
			# Auto circular orbit launch
			var mouse_pos = get_global_mouse_position()
			var closest = find_closest_body(mouse_pos)
			var vel = calculate_launch_velocity(mouse_pos, closest.global_position, closest.mass) if closest != null else Vector2.ZERO
			placing.velocity = vel
			placing.spawned_debris.connect(Callable(debris_spawned))
			satellite_placement_SFX.play()
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
			satellite_placement_SFX.play()
			finalize_placing()


# UTILS
# -------------------------------------------------

func start_entity_placement(idx : int, placementState : PlacementState, scene : PackedScene ,holder : Node2D) -> void:
	clear_selection()
	option_panels.show()
	start_placing_mode(placementState)
	var new_entity = scene.instantiate()
	new_entity.global_position = get_global_mouse_position()
	holder.add_child(new_entity)
	if new_entity.has_method("set_type"):
		new_entity.set_type(idx)
	if new_entity.has_method("toggle_lighting"):
		new_entity.toggle_lighting(lighting_enabled)
	placing_type = idx
	placing = new_entity

func calculate_launch_velocity(satellite_pos: Vector2, planet_pos: Vector2, planet_mass: float) -> Vector2:
	# Calculates the launch velocity required for a satellite to enter a circular orbit when "auto_orbits" is toggled on
	
	var gravity_direction = (planet_pos - satellite_pos).normalized()
	var distance = satellite_pos.distance_to(planet_pos)
	var launch_speed = sqrt(Global.gravitational_constant * planet_mass / distance)

	var rotated_dir = Vector2.ZERO
	if orbit_direction_reversed:
		rotated_dir = Vector2(-gravity_direction.y, gravity_direction.x)
	else:
		rotated_dir = Vector2(gravity_direction.y, -gravity_direction.x)

	return launch_speed * rotated_dir

func find_closest_body(pos: Vector2) -> GravityBody:
	# Fimds the closest celestial body to a position
	
	var closest: GravityBody = null
	var min_dist := INF
	for body: GravityBody in celestial_bodies:
		var dist = body.global_position.distance_to(pos)
		if dist < min_dist:
			min_dist = dist
			closest = body
	return closest

func finalize_placing() -> void:
	# Runs when an entity has been placed, clears all placement related elements
	
	if not is_instance_valid(placing):
		return
	placing.place()
	started_drag = Vector2.ZERO
	drag_line.clear_points()
	orbit_preview.clear_points()
	
	if placing is GravityBody:
		add_gravity_body(placing)
	
	end_placing_mode()

func clear_selection() -> void:
	if selected_body:
		planet_settings.toggle(false)
		selected_body.unselect()
		selected_body = null

func clicked_body(body: GravityBody) -> void:
	if placing:
		return
	clear_selection()
	selected_body = body
	selected_body.select()
	
	toggle_celestial_body_panel(true, body)

func body_deleted(body) -> void:
	vanish_SFX.play()
	clear_selection()
	if body in celestial_bodies:
		celestial_bodies.erase(body)
	update_gravity_grid(celestial_bodies)

func body_move(body) -> void:
	# Puts the celestian body back into "placing mode"
	var new_state = PlacementState.PLACING_PLANET if body is Planet else PlacementState.PLACING_STAR
	start_placing_mode(new_state)
	body.unselect()
	if body in celestial_bodies:
		celestial_bodies.erase(body)
	body.selected_body.disconnect(Callable(clicked_body))
	body.body_deleted.disconnect(Callable(body_deleted))
	body.body_move.disconnect(Callable(body_move))
	placing = body

func toggle_celestial_body_panel(toggle_on : bool, body : GravityBody) -> void:
	planet_settings.toggle(toggle_on, body)

func trails_changed(enabled : bool) -> void:
	trails_enabled = enabled
	if enabled:
		pass
	else:
		for sat : Satellite in satellite_holder.get_children():
			sat.clear_trail()

func gravity_grid_changed(enabled : bool) -> void:
	gravity_grid.visible = enabled

func timewarp_changed(factor : int) -> void:
	current_timewarp = factor
	option_panels.timewarp_toggle.text = "x" + str(int(current_timewarp))

func clear_all() -> void:
	clear_selection()
	var deletables : Array = planet_holder.get_children() + star_holder.get_children() + satellite_holder.get_children() + debris_holder.get_children()
	
	for body in deletables:
		if body == placing:
			continue
		body.queue_free()
	celestial_bodies.clear()
	update_gravity_grid(celestial_bodies)

func continuous_placement_changed(enabled : bool) -> void:
	continuous_placement_enabled = enabled

func auto_orbits_changed(enabled : bool) -> void:
	auto_orbits_enabled = enabled

func orbit_direction_changed(enabled : bool) -> void:
	orbit_direction_reversed = enabled

func lighting_changed(enabled : bool) -> void:
	lighting_enabled = enabled
	canvas_modulate.visible = enabled
	for star : Star in star_holder.get_children():
		star.toggle_lighting(enabled)

# PLACEMENT STATE MANAGEMENT
# -------------------------------------------------

func start_placing_mode(type: PlacementState) -> void:
	if placement_state == type:
		return
	placement_state = type
	show_action_bar(false)

func end_placing_mode(force := false) -> void:
	if force or not continuous_placement_enabled:
		placement_state = PlacementState.NONE
		placing = null
		show_action_bar(true)
	else:
		match placement_state:
			PlacementState.PLACING_PLANET:
				_on_planet_unfold_pressed_button(placing_type)
			PlacementState.PLACING_STAR:
				_on_star_unfold_pressed_button(placing_type)
			PlacementState.PLACING_SATELLITE:
				_on_satellite_unfold_pressed_button(placing_type)
	update_gravity_grid(celestial_bodies)

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

func _on_planet_unfold_pressed_button(idx: int) -> void:
	click_SFX.play()
	start_entity_placement(idx, PlacementState.PLACING_PLANET, planet_scene, planet_holder)

func _on_star_unfold_pressed_button(idx: Variant) -> void:
	click_SFX.play()
	start_entity_placement(idx, PlacementState.PLACING_STAR, star_scene, star_holder)

func _on_satellite_unfold_pressed_button(idx: Variant) -> void:
	click_SFX.play()
	start_entity_placement(idx, PlacementState.PLACING_SATELLITE, satellite_scene, satellite_holder)

func debris_spawned(debris : Debris) -> void:
	debris_holder.call_deferred("add_child", debris)

func vertical_unfolder_unfolded(unfolder: VerticalUnfold) -> void:
	click_SFX.play()
	option_panels.hide()
	for v_unfold: VerticalUnfold in action_bar.get_node("HBox").get_children():
		if not v_unfold.folded and v_unfold != unfolder:
			v_unfold.toggle_fold()
	
	var all_folded : bool = true
	for v_unfold: VerticalUnfold in action_bar.get_node("HBox").get_children():
		if not v_unfold.folded:
			all_folded = false
	if all_folded:
		option_panels.show()

func _on_planet_settings_body_mass_changed() -> void:
	update_gravity_grid(celestial_bodies)
