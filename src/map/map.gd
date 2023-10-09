# Original source: https://github.com/SelinaDev/Godot-Roguelike-Tutorial
# Author: SelinaDev
class_name Map
extends Node2D

var map_data: MapData

@onready var dungeon_generator: DungeonGenerator = $DungeonGenerator
@onready var tile_map: TileMap = $TileMap


func generate() -> void:
	tile_map.clear()
	dungeon_generator.generate_dungeon(tile_map)
