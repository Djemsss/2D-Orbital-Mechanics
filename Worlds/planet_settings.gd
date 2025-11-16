extends Panel
class_name PlanetSettings

# Handles the Planet Settings UI, where placed bodies can have their characteristics modified


var selected_body : GravityBody

@onready var size_slider : HSlider = $VBox/HBoxSize/SizeSlider
@onready var mass_slider : HSlider = $VBox/HBoxMass/MassSlider

signal body_mass_changed


# UTILS
# -------------------------------------------------

func toggle(toggle_on : bool, body : GravityBody = null) -> void:
	if toggle_on and body:
		selected_body = body
		size_slider.value = body.size
		mass_slider.value = body.mass
		show()
	else:
		hide()


# SIGNAL CALLBACKS
# -------------------------------------------------

func _on_size_slider_value_changed(value: float) -> void:
	selected_body.resize(value)

func _on_mass_slider_value_changed(value: float) -> void:
	selected_body.mass = value
	emit_signal("body_mass_changed")
	
