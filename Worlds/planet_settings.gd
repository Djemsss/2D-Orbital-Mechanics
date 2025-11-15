extends Panel

var selected_body : GravityBody

signal body_mass_changed 


func toggle(toggle_on : bool, body : GravityBody = null) -> void:
	if toggle_on and body:
		selected_body = body
		$VBox/HBoxSize/SizeSlider.value = body.size
		$VBox/HBoxMass/MassSlider.value = body.mass
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
	
