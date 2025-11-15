extends Node

const debris_scene = preload("res://Elements/debris.tscn")

var gravitational_constant = 9.8


# GENERAL UTILS
# -------------------------------------------------

func find_nodes_of_class(root: Node, class_nm: StringName, result: Array = []) -> Array:
	if root.is_class(class_nm):
		result.append(root)

	for child in root.get_children():
		find_nodes_of_class(child, class_nm, result)

	return result
