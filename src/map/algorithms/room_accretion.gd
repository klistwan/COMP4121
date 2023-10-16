class_name RoomAccretion
extends Node

signal finished

@export_category("Map Dimensions")
@export var map_width: int = 45
@export var map_height: int = 45


func generate_dungeon(tile_map: TileMap) -> MapData:
	var dungeon := MapData.new(map_width, map_height)
	tile_map.update(dungeon)
	finished.emit()
	return dungeon
