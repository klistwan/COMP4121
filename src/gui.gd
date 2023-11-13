extends Control

signal generate_button_pressed(algorithm_path, params)

var selected_item_index: int = -1
var algorithms := {
	0: "res://src/map/algorithms/grid_based_room_placement.gd",
	1: "res://src/map/algorithms/random_room_placement.gd",
	2: "res://src/map/algorithms/room_accretion.gd",
	3: "res://src/map/algorithms/random_walk.gd",
	4: "res://src/map/algorithms/cellular_automata.gd",
	5: "res://src/map/algorithms/cellular_automata.gd",
	6: "res://src/map/algorithms/cellular_automata.gd",
	7: "res://src/map/algorithms/fast_noise.gd",
	8: "res://src/map/algorithms/fast_noise.gd",
	9: "res://src/map/algorithms/voronoi_relaxation.gd",
	10: "res://src/map/algorithms/voronoi_relaxation.gd",
}

@onready var generate_button: Button = $CenterContainer/VBoxContainer/Generate


func _on_generate_pressed() -> void:
	generate_button.disabled = true
	var params := {}
	match selected_item_index:
		4:  # Anneal
			params["born"] = [4, 6, 7, 8]
			params["survive"] = [3, 5, 6, 7, 8]
		5:  # Assimilation
			params["born"] = [4, 5, 6, 7]
			params["survive"] = [3, 4, 5]
		6:  # Diamoeba
			params["born"] = [5, 6, 7, 8]
			params["survive"] = [3, 5, 6, 7, 8]
		7:
			params["noise_type"] = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
		8:
			params["noise_type"] = FastNoiseLite.TYPE_PERLIN
		9:
			params["iteration_count"] = 1
		10:
			params["iteration_count"] = 5
	generate_button_pressed.emit(algorithms[selected_item_index], params)


func _on_algorithm_options_item_selected(index: int) -> void:
	# Only enable the button if nothing has been selected yet.
	if selected_item_index == -1:
		enable_generate_button()
	selected_item_index = index


func enable_generate_button() -> void:
	generate_button.disabled = false
