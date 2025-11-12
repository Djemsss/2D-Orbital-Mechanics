extends CharacterBody2D
class_name Debris

var mass : int = 1

func _ready() -> void:
	randomize_size()

func randomize_size() -> void:
	for pt in range($Polygon.polygon.size()):
		$Polygon.polygon.set(pt, $Polygon.polygon.get(pt) + Vector2(randf(), randf()))
