extends CharacterBody2D
class_name Satellite

## Represents a satellite, can be spawned by the user and orbits celestial bodies


@export var mass : int = 100

var type : int = 0
var placed : bool = false
var last_placed_trail_point : Vector2 = Vector2.ZERO
var destroyed : bool = false

@onready var sprite : AnimatedSprite2D = $Sprite
@onready var trail_line : Line2D = $Node/Line2D
@onready var collision_shape : CollisionShape2D = $CollisionShape2D

signal spawned_debris(debris : Debris)
signal finished_spawning_debris


# PROCESS
# -------------------------------------------------

func _ready() -> void:
	sprite.frame = randi_range(0, 13)
	sprite.rotation_degrees = randi_range(0, 360)
	
	# Random trail color
	var random_r : float = randf()
	var random_g : float = randf()
	var random_b : float = randf()
	trail_line.gradient.set_color(0, Color(random_r, random_g, random_b, 0.0))
	trail_line.gradient.set_color(1, Color(random_r, random_g, random_b, 1.0))

func process_gravity(delta : float, bodyList : Array):
	# Applies combined gravitational forces from all the bodies in "bodyList"
	# Destroys satellite if a collision is detected with another satellite or a piece of debris
	
	if not placed:
		return
	for body in bodyList:
		var gravity_dir = (body.global_position - global_position).normalized()
		var force = Global.gravitational_constant * mass * body.mass / (global_position.distance_squared_to(body.global_position))
		var acceleration = force / mass
		velocity += gravity_dir * acceleration * delta
		
	if move_and_slide():
		var collision = get_last_slide_collision()
		var collider = collision.get_collider()
		if (collider is Satellite and collider.placed):
			destroy(true)
			collider.destroy(true)
		elif collider is Debris:
			destroy(true)

func process_trail() -> void:
	# Handles the visual trail left behind by the satellite as it orbits
	
	if not placed:
		return
		
	# Point count of the line2D trail varies depending on FPS
	if trail_line.get_point_count() > remap(Engine.get_frames_per_second(), 30, 3000, 100, 400):
		trail_line.remove_point(0)
	if global_position.distance_to(last_placed_trail_point) > 5:
		trail_line.add_point(global_position)
		last_placed_trail_point = global_position

func process_atmospheric_drag(atmosphere_density : float, delta : float) -> void:
	velocity = lerp(velocity, Vector2(0, 0), atmosphere_density * delta * 0.08)

# UTILS
# -------------------------------------------------

func place() -> void:
	placed = true
	collision_shape.set_deferred("disabled", false)

func spawn_debris(amount: int = 10, spread: float = 50.0, cell_size: float = 4.0) -> void:
	# Once destroyed, this method spawns a specific amount of debris spread over the area of the satellite
	
	var positions: Array = []
	var num_cells = int(spread * 2 / cell_size)
	var half_spread = spread
	
	# Generate random spread of positions
	for x in range(num_cells):
		for y in range(num_cells):
			var offset = Vector2(
				x * cell_size - half_spread + cell_size/2,
				y * cell_size - half_spread + cell_size/2
			)
			if offset.length() <= spread:
				positions.append(offset)

	positions.shuffle()
	
	# Spawn pieces of debris and apply the positions
	for i in range(min(amount, positions.size())):
		var debris : Debris = Global.debris_scene.instantiate()
		debris.global_position = global_position + positions[i]
		debris.rotation = randf() * TAU
		debris.velocity = velocity
		
		var rand_angle = deg_to_rad(randi_range(0, 360))
		debris.velocity += Vector2(cos(rand_angle), sin(rand_angle)) * randi_range(20, 50)
		
		emit_signal("spawned_debris", debris)

func destroy(with_debris : bool = false) -> void:
	# Destroys the satellite with an option to spawn debris
	
	if destroyed:
		return
	destroyed = true
	if with_debris:
		spawn_debris(randi_range(3, 8), 20, 4)
	queue_free()

func clear_trail() -> void:
	trail_line.clear_points()
