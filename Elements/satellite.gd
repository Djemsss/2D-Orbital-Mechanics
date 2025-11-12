extends CharacterBody2D
class_name Satellite

@export var mass : int = 100

var type : int = 0
var placed : bool = false
var last_placed_trail_point : Vector2 = Vector2.ZERO
var destroyed : bool = false

signal spawned_debris(debris : Debris)
signal finished_spawning_debris

func _ready() -> void:
	$Sprite.frame = randi_range(0, 4)
	
	# Random trail color
	$Node/Line2D.gradient.set_color(0, Color(randf(), randf(), randf(), 0.0))
	$Node/Line2D.gradient.set_color(1, Color(randf(), randf(), randf(), 1.0))

func process_trail() -> void:
	if $Node/Line2D.get_point_count() > remap(Engine.get_frames_per_second(), 30, 3000, 100, 200):
		$Node/Line2D.remove_point(0)
	if global_position.distance_to(last_placed_trail_point) > 10:
		$Node/Line2D.add_point(global_position)
		last_placed_trail_point = global_position

func place():
	placed = true
	$CollisionShape2D.set_deferred("disabled", false)

func spawn_debris(amount: int = 10, spread: float = 50.0, cell_size: float = 4.0):
	var positions: Array = []
	var num_cells = int(spread * 2 / cell_size)
	var half_spread = spread

	# Generate grid positions
	for x in range(num_cells):
		for y in range(num_cells):
			var offset = Vector2(
				x * cell_size - half_spread + cell_size/2,
				y * cell_size - half_spread + cell_size/2
			)
			if offset.length() <= spread: # optional: constrain to circle
				positions.append(offset)

	# Shuffle positions randomly
	positions.shuffle()

	# Take the first 'amount' positions
	for i in range(min(amount, positions.size())):
		var debris : Debris = Global.debris_scene.instantiate() as Node2D
		debris.global_position = global_position + positions[i]
		debris.rotation = randf() * TAU
		debris.velocity = velocity
		emit_signal("spawned_debris", debris)
	#emit_signal("finished_spawning_debris")

func destroy(with_debris : bool = false) -> void:
	if destroyed:
		return
	destroyed = true
	if with_debris:
		spawn_debris(10, 30, 5)
		#await finished_spawning_debris
	queue_free()
