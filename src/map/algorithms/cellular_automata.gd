class_name CellularAutomata
extends Node

signal finished

const STEP_PAUSE_INTERVAL := .15

@export_category("Map Dimensions")
@export var map_width: int = 45
@export var map_height: int = 45

@export_category("Algorithm Parameters")
@export var initial_alive_percentage: float = 0.50
@export var max_generations: int = 15

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	print_debug("_rng.seed=", _rng.seed)


func generate_dungeon(tile_map: TileMap) -> MapData:
	var dungeon := MapData.new(map_width, map_height)
	tile_map.update(dungeon)

	# Randomly initialize 50% of cells as alive.
	for x in range(1, map_width - 1):
		for y in range(1, map_height - 1):
			if _rng.randf() < initial_alive_percentage:
				dungeon.get_tile(Vector2i(x, y)).set_tile_type(dungeon.TILE_TYPES.floor)

	# Apply rules for each generation.
	for g in range(max_generations):
		var position_to_next_state := {}
		for x in range(1, map_width - 1):
			for y in range(1, map_height - 1):
				var count: int = count_live_neighbours(Vector2i(x, y), dungeon)
				# Apply rule B4678/S35678 (Anneal).
				if !dungeon.get_tile(Vector2i(x, y)).is_walkable():
					if count in [4, 6, 7, 8]:
						position_to_next_state[Vector2i(x, y)] = 1
					else:
						position_to_next_state[Vector2i(x, y)] = 0
				else:
					if count in [3, 5, 6, 7, 8]:
						position_to_next_state[Vector2i(x, y)] = 1
					else:
						position_to_next_state[Vector2i(x, y)] = 0

		# Update MapData and TileMap.
		for position in position_to_next_state:
			if position_to_next_state[position] == 1:
				dungeon.get_tile(position).set_tile_type(dungeon.TILE_TYPES.floor)
			else:
				dungeon.get_tile(position).set_tile_type(dungeon.TILE_TYPES.wall)
		tile_map.update(dungeon)
		await get_tree().create_timer(STEP_PAUSE_INTERVAL).timeout

	finished.emit()
	return dungeon


func count_live_neighbours(pos: Vector2i, dungeon: MapData) -> int:
	var count: int = 0
	for x in [-1, 0, 1]:
		for y in [-1, 0, 1]:
			if x == 0 and y == 0:
				continue
			if dungeon.get_tile(pos + Vector2i(x, y)).is_walkable():
				count += 1
	return count


func _carve_tile(dungeon: MapData, position: Vector2i) -> void:
	var tile: Tile = dungeon.get_tile(position)
	tile.set_tile_type(dungeon.TILE_TYPES.floor)
