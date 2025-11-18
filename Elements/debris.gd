extends CharacterBody2D
class_name Debris

## Represents a piece of debris created when a satellite gets destroyed by a collision


const colors : Array[Color] = [Color("4483a2"), Color("e19e3d"), Color("ffffff")]

var mass : int = 1

@onready var polygon : Polygon2D = $Polygon


# PROCESS
# -------------------------------------------------

func _ready() -> void:
	polygon.color = colors.pick_random()
	randomize_size()

func process_gravity(delta : float, bodyList : Array) -> void:
	# Applies combined gravitational forces from all the bodies in "bodyList"
	# Checks for collisions and blends velocities to simulate elastic interactions
	
	for body in bodyList:
		var gravity_dir = (body.global_position - global_position).normalized()
		var force = Global.gravitational_constant * mass * body.mass / (global_position.distance_squared_to(body.global_position))
		var acceleration = force / mass
		velocity += gravity_dir * acceleration * delta
		
	move_and_slide()
	
	for i in range(get_slide_collision_count()):
		var col = get_slide_collision(i)
		var other = col.get_collider()
		if other is Debris and other != self:
			# Vel blending
			var combined = (velocity * mass + other.velocity * other.mass) / (mass + other.mass)
			
			velocity = lerp(velocity, combined, 0.2)
			other.velocity = lerp(other.velocity, combined, 0.2)

func process_atmospheric_drag(atmosphere_density : float, delta : float) -> void:
	velocity = lerp(velocity, Vector2(0, 0), atmosphere_density * delta * 0.08)

# SETUP
# -------------------------------------------------

func randomize_size() -> void:
	var poly = polygon.polygon
	for pt in range(poly.size()):
		poly.set(pt, poly.get(pt) + Vector2(randf() * 2, randf() * 2))
	polygon.polygon = poly
