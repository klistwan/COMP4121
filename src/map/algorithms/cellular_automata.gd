class_name CellularAutomata
extends Node

signal finished
enum Biome { WOODLAND, FOREST }

const GENERATION_INTERVAL := 0.100
const RANDOM_WALK_INTERVAL := 0.050
const CONTOUR_BOMB_INTERVAL := 0.010

@export_category("Map Dimensions")
@export var map_width: int = 45
@export var map_height: int = 45

@export_category("Algorithm Parameters")
@export var initial_alive_percentage: float = 0.50
@export var max_generations: int = 10
@export var min_cave_size: int = 20
@export var async_probability: float = 0.90

var born: Array = []
var survive: Array = []

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	print_debug("_rng.seed=", _rng.seed)


func set_rule(p_born: Array, p_survive: Array) -> void:
	born = p_born
	survive = p_survive


func get_tile_type(biome: Biome, dungeon: MapData) -> Resource:
	match biome:
		Biome.WOODLAND:
			return [dungeon.TILE_TYPES.grass, dungeon.TILE_TYPES.flower].pick_random()
		Biome.FOREST:
			return [dungeon.TILE_TYPES.oak_tree, dungeon.TILE_TYPES.evergreen_tree].pick_random()
		_:
			push_error("Unknown biome:", biome)
			return


func generate_dungeon(tile_map: TileMap) -> MapData:
	var dungeon := MapData.new(map_width, map_height)
	for x in range(map_width):
		for y in range(map_height):
			dungeon.get_tile(Vector2i(x, y)).set_tile_type(get_tile_type(Biome.FOREST, dungeon))
	tile_map.update(dungeon)
	await get_tree().create_timer(GENERATION_INTERVAL).timeout

	# Randomly initialize 50% of cells as alive.
	for x in range(1, map_width - 1):
		for y in range(1, map_height - 1):
			if _rng.randf() < initial_alive_percentage:
				dungeon.get_tile(Vector2i(x, y)).set_tile_type(get_tile_type(Biome.WOODLAND, dungeon))

	# Apply rules for each generation.
	for g in range(max_generations):
		var position_to_next_state := {}
		for x in range(1, map_width - 1):
			for y in range(1, map_height - 1):
				var count: int = count_live_neighbours(Vector2i(x, y), dungeon)
				# Apply rule.
				if !dungeon.get_tile(Vector2i(x, y)).is_walkable():
					if count in born:
						position_to_next_state[Vector2i(x, y)] = 1
				else:
					if count not in survive:
						position_to_next_state[Vector2i(x, y)] = 0

		# Update MapData and TileMap.
		for position in position_to_next_state:
			if position_to_next_state[position] == 1:
				dungeon.get_tile(position).set_tile_type(get_tile_type(Biome.WOODLAND, dungeon))
			else:
				dungeon.get_tile(position).set_tile_type(get_tile_type(Biome.FOREST, dungeon))
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

	# If only a single cave, we're done.
	if caverns.size() == 1:
		finished.emit()
		return dungeon

	# Perform a weighted random walk from a random point in one cave to the next.
	var new_floor_tiles := Set.new()
	var prev_cave: Set = caverns.pop_back()
	while caverns:
		var start: Vector2i = prev_cave.to_list().pick_random()
		var next_cave: Set = caverns.pop_back()
		# Perform the walk.
		var floor_tiles = await random_walk(start, next_cave, dungeon, tile_map)
		new_floor_tiles = new_floor_tiles.union(floor_tiles)
		prev_cave = next_cave

	await apply_contour_bombing(new_floor_tiles.to_list(), dungeon, tile_map)

	finished.emit()
	return dungeon


func random_walk(starting_point: Vector2i, cave: Set, dungeon: MapData, tile_map: TileMap) -> Set:
	"""Walks from a starting point to a cave and returns any new floor tiles created.

	Source: https://abitawake.com/news/articles/procedural-generation-with-godot-creating-caves-with-cellular-automata
	"""
	var current_point := starting_point
	var new_floor_tiles: Set = Set.new()
	var target = cave.to_list().pick_random()
	while !cave.contains(current_point):
		if !dungeon.get_tile(current_point).is_walkable():
			dungeon.get_tile(current_point).set_tile_type(get_tile_type(Biome.WOODLAND, dungeon))
			new_floor_tiles.add(current_point)
		tile_map.update(dungeon)
		await get_tree().create_timer(RANDOM_WALK_INTERVAL).timeout

		# Initialize weights in each direction.
		var n := 1.0
		var e := 1.0
		var s := 1.0
		var w := 1.0
		var weight := 5.0

		# Increase weights based on our current location relative to the target.
		if current_point.x < target.x:
			e += weight
		elif current_point.x > target.x:
			w += weight
		elif current_point.y < target.y:
			s += weight
		elif current_point.y > target.y:
			n += weight

		var delta: Vector2i = choose_element_with_probability(
			[Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT],
			[n, e, s, w],
		)
		var next_point: Vector2i = current_point + delta
		if dungeon.is_inside(next_point):
			current_point = next_point
	return new_floor_tiles


func sum(accum, number):
	return accum + number


func choose_element_with_probability(elements: Array[Variant], weights: Array[float]) -> Variant:
	# Ensure that the elements and weights arrays have the same length.
	if elements.size() != weights.size():
		printerr("Error: Elements and weights arrays must have the same length.")
		return null

	# Calculate the total weight.
	var total_weight: float = weights.reduce(sum, 0)

	# Generate a random number within the total weight range.
	var random_value: float = _rng.randf() * total_weight

	# Find the element corresponding to the chosen weight.
	var cumulative_weight = 0.0
	for i in range(elements.size()):
		cumulative_weight += float(weights[i])
		if random_value <= cumulative_weight:
			return elements[i]

	printerr("Error: Could not choose an element.")
	return null


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


func fill_cave(cave: Set, dungeon: MapData, tile_map: TileMap) -> void:
	for position in cave.to_list():
		dungeon.get_tile(position).set_tile_type(get_tile_type(Biome.FOREST, dungeon))
	tile_map.update(dungeon)
	await get_tree().create_timer(GENERATION_INTERVAL).timeout


func apply_contour_bombing(candidates: Array, dungeon: MapData, tile_map: TileMap) -> void:
	"""Generates a cavern along a list of vertices.

	Source: https://www.darkgnosis.com/2018/03/03/contour-bombing-cave-generation-algorithm/
	"""
	candidates.shuffle()

	for k in range(candidates.size() * 1.8):
		var random_offset := 0

		# 1/3 chance that we will use as a bombing point one of the last 15 positions.
		if _rng.randf() < 0.33:
			if candidates.size() < 15:
				random_offset = _rng.randi_range(0, candidates.size() - 1)
			else:
				random_offset = _rng.randi_range(candidates.size() - 1, candidates.size() - 1)
		else:
			# Otherwise, use the first half of the remaining tiles.
			random_offset = _rng.randi_range(0, candidates.size() / 2)

		var t: Vector2i = candidates[random_offset]
		var tx: int = t.x
		var ty: int = t.y

		# We will use radius 1 mostly with a smaller chance (5%) that the radius will be size 2.
		var bomb_radius = 1 if _rng.randf() > 0.05 else 2
		if _rng.randf() < 0.05:
			bomb_radius += 1

		# Bomb
		for x in range(max(0, tx - bomb_radius - 1), min(map_width - 1, tx + bomb_radius)):
			for y in range(max(0, ty - bomb_radius - 1), min(map_height - 1, ty + bomb_radius)):
				# Check if the tile is within the circle
				if (x - tx) ** 2 + (y - ty) ** 2 < bomb_radius ** 2 + bomb_radius:
					# Check if the tile is in bounds.
					if x <= 0 or x >= map_width or y <= 0 or y >= map_height:
						continue
					# Push any new floor tiles to the candidate list.
					if !dungeon.get_tile(Vector2i(x, y)).is_walkable():
						dungeon.get_tile(Vector2i(x, y)).set_tile_type(get_tile_type(Biome.WOODLAND, dungeon))
						candidates.append(Vector2i(x, y))
						tile_map.update(dungeon)
						await get_tree().create_timer(CONTOUR_BOMB_INTERVAL).timeout
