extends PanelContainer
class_name PlanetSettings

# Handles the Planet Settings UI, where placed bodies can have their characteristics modified


var selected_body : GravityBody

@onready var size_slider : HSlider = $VBox/HBoxSize/SizeSlider
@onready var mass_slider : HSlider = $VBox/HBoxMass/MassSlider
@onready var atmo_size_slider : HSlider = $VBox/HBoxAtmoSize/AtmoSizeSlider
@onready var atmo_density_slider : HSlider = $VBox/HBoxAtmoDensity/AtmoDensitySlider
@onready var atmosphere_options : Array[Control] = [$VBox/Atmosphere, $VBox/HBoxAtmoDensity, $VBox/HBoxAtmoSize]

signal body_mass_changed


# UTILS
# -------------------------------------------------

func toggle(toggle_on : bool, body : GravityBody = null) -> void:
	if toggle_on and body:
		selected_body = body
		size_slider.value = body.size
		mass_slider.value = body.mass
		if body is Planet:
			atmo_size_slider.value = body.atmosphere_height_fraction
			atmo_density_slider.value = body.atmosphere_density
			toggle_atmosphere_options(true)
		else:
			toggle_atmosphere_options(false)
		show()
	else:
		hide()

func toggle_atmosphere_options(toggled_on : bool) -> void:
	for node in atmosphere_options:
		node.visible = toggled_on

# SIGNAL CALLBACKS
# -------------------------------------------------

func _on_size_slider_value_changed(value: float) -> void:
	selected_body.resize(value)

func _on_mass_slider_value_changed(value: float) -> void:
	selected_body.mass = value
	emit_signal("body_mass_changed")

func _on_atmo_size_slider_value_changed(value: float) -> void:
	selected_body.atmosphere_height_fraction = value
	selected_body.resize(selected_body.size)

func _on_atmo_density_slider_value_changed(value: float) -> void:
	selected_body.atmosphere_density = value
	selected_body.resize(selected_body.size)
