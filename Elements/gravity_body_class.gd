extends Node2D
class_name GravityBody

## Parent class for all celestial bodies that have a gravitational effect


@export var mass : int = 10000 # Mass in arbitrary units
@export var radius : int = 200 # Radius in pixels
@export var sprite_base_size : Vector2 = Vector2(32, 32)  # Base size for sprite scaling

var placed : bool = false
