extends Node2D
class_name Satellite

@export var mass : int = 100

var velocity : Vector2 = Vector2(0, 0)
var placed = false

func _ready() -> void:
	$Sprite.frame = randi_range(0, 4)

func process_gravity(delta : float, bodyList : Array):
	for body in bodyList:
		var gravity_dir = (body.global_position - global_position).normalized()
		var gravity_force = (Global.gravitational_constant * mass * body.mass) / (global_position.distance_to(body.global_position) * (global_position.distance_to(body.global_position))) 
		velocity += gravity_dir * gravity_force * delta
		
	global_position += velocity * delta
