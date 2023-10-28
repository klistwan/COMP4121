# Original source: https://github.com/SelinaDev/Godot-Roguelike-Tutorial
# Author: SelinaDev
class_name Map
extends Node2D

signal generation_finished

var dungeon_generator: Node
var map_data: MapData

@onready var tile_map: TileMap = $TileMap


func generate(algorithm_path: String, params: Dictionary) -> void:
	dungeon_generator = load(algorithm_path).new()
	if "noise_type" in params:
		dungeon_generator.set_noise_type(params["noise_type"])
	if "iteration_count" in params:
		dungeon_generator.set_iteration_count(params["iteration_count"])
	add_child(dungeon_generator)
	dungeon_generator.finished.connect(_on_generation_finished)
	tile_map.clear()
	dungeon_generator.generate_dungeon(tile_map)


func _on_generation_finished():
	generation_finished.emit()
