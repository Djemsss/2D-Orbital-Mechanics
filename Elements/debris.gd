extends CharacterBody2D
class_name Debris

var mass : int = 1

var colors : Array[String] = ["4483a2", "e19e3d", "ffffff"]

func _ready() -> void:
	$Polygon.color = Color(colors.pick_random())
	randomize_size()

func randomize_size() -> void:
	var poly = $Polygon.polygon
	for pt in range(poly.size()):
		poly.set(pt, poly.get(pt) + Vector2(randf() * 2, randf() * 2))
	$Polygon.polygon = poly
