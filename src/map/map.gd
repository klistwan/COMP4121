# Original source: https://github.com/SelinaDev/Godot-Roguelike-Tutorial
# Author: SelinaDev
class_name Map
extends Node2D

signal generation_finished

var map_data: MapData

@onready var dungeon_generator: DungeonGenerator = $DungeonGenerator
@onready var tile_map: TileMap = $TileMap


func _ready() -> void:
	dungeon_generator.finished.connect(_on_generation_finished)


func generate() -> void:
	tile_map.clear()
	dungeon_generator.generate_dungeon(tile_map)


func _on_generation_finished():
	generation_finished.emit()
