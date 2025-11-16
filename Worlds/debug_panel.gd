extends Panel
class_name DebugPanel

## Handles the debug panel showing FPS and entity counts


@export var satellite_holder : Node2D
@export var debris_holder : Node2D

@onready var fps_debug : Label = $HBox/FPS_VBox/Value
@onready var sat_count_debug : Label = $HBox/Sats_VBox/Value
@onready var debris_count_debug : Label = $HBox/Debris_VBox/Value


# PROCESS 
# -------------------------------------------------

func _physics_process(delta: float) -> void:
	update_debug_panel()


# UTILS
# -------------------------------------------------

func update_debug_panel():
	set_fps_debug(Engine.get_frames_per_second())
	set_sat_count_debug(satellite_holder.get_child_count())
	set_debris_count_debug(debris_holder.get_child_count())

func set_fps_debug(fps : int):
	fps_debug.text = str(fps)

func set_sat_count_debug(count : int):
	sat_count_debug.text = str(count)

func set_debris_count_debug(count : int):
	debris_count_debug.text = str(count)
