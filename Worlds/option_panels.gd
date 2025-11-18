extends Control
class_name OptionPanels

## Handles the option panels UI


@export var world : World

@onready var trails_toggle : CheckButton = $General/VBox/TrailsToggle
@onready var auto_orbits_toggle : CheckButton = $SatLaunch/VBox/AutoOrbitsToggle
@onready var orbit_direction_toggle : CheckButton = $SatLaunch/VBox/OrbitDirectionToggle
@onready var continuous_placement_toggle : CheckButton = $General/VBox/ContinuousPlacementToggle
@onready var timewarp_toggle : Button = $General/VBox/TimeWarpToggle

signal trails_changed(enabled : bool)
signal gravity_grid_changed(visible : bool)
signal timewarp_changed(value : float)
signal clear_all()
signal continuous_placement_changed(enabled : bool)
signal auto_orbits_changed(enabled : bool)
signal orbit_direction_changed(enabled : bool)
signal lighting_changed(enabled : bool)


# SIGNAL CALLBACKS
# -------------------------------------------------

func _on_trails_toggle_toggled(toggled_on: bool) -> void:
	emit_signal("trails_changed", toggled_on)

func _on_gravity_grid_toggle_toggled(toggled_on: bool) -> void:
	emit_signal("gravity_grid_changed", toggled_on)

func _on_time_warp_toggle_pressed() -> void:
	var tw_index = world.TimewarpOptions.find(world.current_timewarp)
	var new_tw = world.TimewarpOptions[wrap(tw_index + 1, 0, world.TimewarpOptions.size())]
	emit_signal("timewarp_changed", new_tw)

func _on_clear_all_button_pressed() -> void:
	emit_signal("clear_all")

func _on_continuous_placement_toggle_toggled(toggled_on: bool) -> void:
	emit_signal("continuous_placement_changed", toggled_on)

func _on_auto_orbits_toggle_toggled(toggled_on: bool) -> void:
	emit_signal("auto_orbits_changed", toggled_on)

func _on_orbit_direction_toggle_toggled(toggled_on: bool) -> void:
	emit_signal("orbit_direction_changed", toggled_on)

func _on_lighting_toggle_toggled(toggled_on: bool) -> void:
	emit_signal("lighting_changed", toggled_on)
