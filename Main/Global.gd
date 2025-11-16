extends Node

## Global singleton with constants, preloads and some global utilities


const debris_scene = preload("res://Elements/debris.tscn")

const gravitational_constant = 9.8


# GENERAL UTILS
# -------------------------------------------------

func find_nodes_of_class(root: Node, class_type: StringName, result: Array = []) -> Array:
	# Recursively searches a node tree and returns all nodes of a given class
	
	if root.is_class(class_type):
		result.append(root)

	for child in root.get_children():
		find_nodes_of_class(child, class_type, result)

	return result
