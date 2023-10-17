class_name RandomWalk
extends Node

signal finished

const STEP_PAUSE_INTERVAL := .025

@export_category("Map Dimensions")
@export var map_width: int = 45
@export var map_height: int = 45

@export_category("Algorithm Parameters")
@export var threshold: int = 675
@export var max_lifetime: int = 225

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	print_debug("_rng.seed=", _rng.seed)


func generate_dungeon(tile_map: TileMap) -> MapData:
	var dungeon := MapData.new(map_width, map_height)
	tile_map.update(dungeon)

	# Choose a random starting point and convert it to a floor tile.
	var starting_pos := Vector2i(_rng.randi_range(15, map_width - 15), _rng.randi_range(15, map_height - 15))
	var current_pos := starting_pos
	var current_lifetime := 0
	var floor_tile_count := 0
	_carve_tile(dungeon, current_pos)
	tile_map.update(dungeon)

	while floor_tile_count < threshold:
		# Choose random direction.
		var dir: Vector2i = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN].pick_random()
		current_pos += dir

		# If out of bounds, return back to the starting point.
		if current_pos.x <= 0 or current_pos.x >= (map_width - 1):
			current_pos = starting_pos
			continue
		if current_pos.y <= 0 or current_pos.y >= (map_height - 1):
			current_pos = starting_pos
			continue

		# If it's a floor tile, keep going.
		if dungeon.get_tile(current_pos).is_walkable():
			continue

		# If it's a wall tile, convert it to a floor tile.
		_carve_tile(dungeon, current_pos)
		tile_map.update(dungeon)
		await get_tree().create_timer(STEP_PAUSE_INTERVAL).timeout
		floor_tile_count += 1
		current_lifetime += 1

		# If lifetime exceeded, return walker back to starting point.
		if current_lifetime > max_lifetime:
			current_pos = starting_pos
			current_lifetime = 0

	finished.emit()
	return dungeon


func _carve_tile(dungeon: MapData, position: Vector2i) -> void:
	var tile: Tile = dungeon.get_tile(position)
	tile.set_tile_type(dungeon.TILE_TYPES.floor)
