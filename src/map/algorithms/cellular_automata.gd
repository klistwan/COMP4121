class_name CellularAutomata
extends Node

signal finished

const GENERATION_INTERVAL := .2
const RANDOM_WALK_INTERVAL := .1

@export_category("Map Dimensions")
@export var map_width: int = 45
@export var map_height: int = 45

@export_category("Algorithm Parameters")
@export var initial_alive_percentage: float = 0.50
@export var max_generations: int = 15
@export var min_cave_size: int = 20
@export var random_walk_probability: float = 0.50
@export var async_probability: float = 0.90

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
		await get_tree().create_timer(GENERATION_INTERVAL).timeout

	# Find all the disconnected caverns.
	var caverns: Array[Set] = []
	for x in range(1, map_width - 1):
		for y in range(1, map_height - 1):
			var pos := Vector2i(x, y)
			if !dungeon.get_tile(pos).is_walkable():
				continue
			# Check if it belongs to any existing caverns.
			var seen = false
			for cavern in caverns:
				if cavern.contains(pos):
					seen = true
					break
			if seen:
				continue
			# Otherwise, this is the start of a new cavern.
			var cave: Set = get_reachable_cells(pos, dungeon)
			# Keep if it's larger than 1% of the available grid space.
			if cave.size() > min_cave_size:
				caverns.append(cave)
			# Otherwise, fill it with wall tiles.
			else:
				await fill_cave(cave, dungeon, tile_map)
	print_debug(caverns.size(), "caves found")

	# If only a single cave, we're don.
	if caverns.size() == 1:
		finished.emit()
		return dungeon

	# Otherwise, find the smallest cave.
	var smallest_cave: Set = caverns[0]
	for cave in caverns:
		if cave.size() < smallest_cave.size():
			smallest_cave = cave
	print_debug("Smallest cave size=", smallest_cave.size())

	# Perform a partial random walk from a random point in the smallest cave to the others.
	var new_floor_tiles := Set.new()
	for _walk_count in range(2):
		var starting_point: Vector2i = smallest_cave.to_list().pick_random()
		for cave in caverns:
			var floor_tiles = await random_walk(starting_point, cave, dungeon, tile_map)
			new_floor_tiles = new_floor_tiles.union(floor_tiles)

	# Widen the tunnels by applying async cellular automata to only the new floor tiles.
	print_debug("Tiles whose neighbours are receiving CA update:", new_floor_tiles)
	for g in range(20):
		var position_to_next_state := {}
		for tunnel_pos in new_floor_tiles.to_list():
			if _rng.randf() > async_probability:
				continue
			for delta in [Vector2i.DOWN, Vector2i.UP, Vector2i.RIGHT, Vector2i.LEFT]:
				var pos = tunnel_pos + delta
				var count: int = count_live_neighbours(pos, dungeon)
				# Apply rule B3/S012345678 (Life without Death).
				if !dungeon.get_tile(pos).is_walkable():
					if count in [3]:
						position_to_next_state[pos] = 1
					else:
						position_to_next_state[pos] = 0
				else:
					if count in [1, 2, 3, 4, 5, 6, 7, 8]:
						position_to_next_state[pos] = 1
					else:
						position_to_next_state[pos] = 0
		# Update MapData and TileMap.
		for position in position_to_next_state:
			if position_to_next_state[position] == 1:
				dungeon.get_tile(position).set_tile_type(dungeon.TILE_TYPES.floor)
			else:
				dungeon.get_tile(position).set_tile_type(dungeon.TILE_TYPES.wall)
		tile_map.update(dungeon)
		await get_tree().create_timer(GENERATION_INTERVAL).timeout

	# Remove any wall islands (wall tiles with 7+ floor neighbours).
	for x in range(1, map_width - 1):
		for y in range(1, map_height - 1):
			if !dungeon.get_tile(Vector2i(x, y)).is_walkable() and count_live_neighbours(Vector2i(x, y), dungeon) >= 7:
				dungeon.get_tile(Vector2i(x, y)).set_tile_type(dungeon.TILE_TYPES.floor)
	tile_map.update(dungeon)
	await get_tree().create_timer(GENERATION_INTERVAL).timeout

	finished.emit()
	return dungeon


func random_walk(starting_point: Vector2i, cave: Set, dungeon: MapData, tile_map: TileMap) -> Set:
	"""Walks from a starting point to a cave and returns any new floor tiles created."""
	print_debug("Randomly walking from", starting_point, "to cave of size=", cave.size())
	var current_point := starting_point
	var new_floor_tiles: Set = Set.new()
	var target = cave.to_list().pick_random()
	while !cave.contains(current_point):
		if !dungeon.get_tile(current_point).is_walkable():
			_carve_tile(dungeon, current_point)
			new_floor_tiles.add(current_point)
		tile_map.update(dungeon)
		await get_tree().create_timer(RANDOM_WALK_INTERVAL).timeout
		var next_point: Vector2i = current_point
		if _rng.randf() < random_walk_probability:
			next_point += [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT].pick_random()
		else:
			# Move one step closer.
			var direction: Vector2i = target - current_point
			if abs(direction.x) > abs(direction.y):
				# Horizontal component is greater, snap to east or west.
				next_point += Vector2i(sign(direction.x), 0)
			else:
				# Vertical component is greater, snap to north or south.
				next_point += Vector2i(0, sign(direction.y))
		if dungeon.is_inside(next_point):
			current_point = next_point
	return new_floor_tiles


func get_reachable_cells(pos: Vector2i, dungeon: MapData) -> Set:
	"""Returns all reachable cells from a given position."""
	var to_visit: Array[Vector2i] = [pos]
	var visited = Set.new()
	while to_visit:
		var current = to_visit.pop_back()
		visited.add(current)
		for x in [-1, 0, 1]:
			for y in [-1, 0, 1]:
				var neighbour = current + Vector2i(x, y)
				if !dungeon.get_tile(neighbour).is_walkable():
					continue
				if visited.contains(neighbour):
					continue
				to_visit.append(neighbour)
	return visited


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


func fill_cave(cave: Set, dungeon: MapData, tile_map: TileMap) -> void:
	for position in cave.to_list():
		dungeon.get_tile(position).set_tile_type(dungeon.TILE_TYPES.wall)
	tile_map.update(dungeon)
	await get_tree().create_timer(GENERATION_INTERVAL).timeout
