# Original source: https://github.com/SelinaDev/Godot-Roguelike-Tutorial
# Author: SelinaDev
class_name MapData
extends RefCounted

const TILE_TYPES = {
	"floor": preload("res://assets/definitions/tiles/floor.tres"),
	"wall": preload("res://assets/definitions/tiles/wall.tres"),
	"door": preload("res://assets/definitions/tiles/door.tres"),
	"evergreen_tree": preload("res://assets/definitions/tiles/evergreen_tree.tres"),
	"oak_tree": preload("res://assets/definitions/tiles/oak_tree.tres"),
	"water": preload("res://assets/definitions/tiles/water.tres"),
	"grass": preload("res://assets/definitions/tiles/grass.tres"),
	"flower": preload("res://assets/definitions/tiles/flower.tres"),
	"dirt": preload("res://assets/definitions/tiles/dirt.tres"),
	"fossil": preload("res://assets/definitions/tiles/fossil.tres"),
	"boulders": preload("res://assets/definitions/tiles/boulders.tres"),
	"scorpion": preload("res://assets/definitions/tiles/scorpion.tres"),
	"snow": preload("res://assets/definitions/tiles/snow.tres"),
}

var width: int
var height: int
var tiles: Array[Tile]


func _init(map_width: int, map_height: int) -> void:
	width = map_width
	height = map_height
	_setup_tiles()


func _setup_tiles() -> void:
	tiles = []
	for y in height:
		for x in width:
			var tile_position := Vector2i(x, y)
			var tile := Tile.new(tile_position, TILE_TYPES.wall)
			tiles.append(tile)


func get_tile(grid_position: Vector2i) -> Tile:
	var tile_index: int = grid_to_index(grid_position)
	if tile_index == -1:
		return null
	return tiles[tile_index]


func grid_to_index(grid_position: Vector2i) -> int:
	if not is_in_bounds(grid_position):
		return -1
	return grid_position.y * width + grid_position.x


func is_in_bounds(coordinate: Vector2i) -> bool:
	return 0 <= coordinate.x and coordinate.x < width and 0 <= coordinate.y and coordinate.y < height


func is_inside(coordinate: Vector2i) -> bool:
	return 0 < coordinate.x and coordinate.x < width - 1 and 0 < coordinate.y and coordinate.y < height - 1
