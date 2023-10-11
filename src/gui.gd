extends Control

signal generate_button_pressed(algorithm_path)

var selected_item_index: int = -1
var algorithms := {
	0: "res://src/map/grid_based_room_placement.gd",
	1: "res://src/map/dungeon_generator.gd",
}

@onready var generate_button: Button = $CenterContainer/VBoxContainer/Generate


func _on_generate_pressed() -> void:
	generate_button_pressed.emit(algorithms[selected_item_index])
	generate_button.disabled = true


func _on_algorithm_options_item_selected(index: int) -> void:
	generate_button.disabled = false
	selected_item_index = index


func enable_generate_button() -> void:
	generate_button.disabled = false
