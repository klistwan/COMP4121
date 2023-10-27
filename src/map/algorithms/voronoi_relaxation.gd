extends Node

signal finished

enum Biome { TUNDRA, FOREST, WOODLAND, DESERT }
const TILE_MAP_UPDATE_INTERVAL: float = 0.3
const BIOME_COUNT := 4

@export_category("Map Dimensions")
@export var map_width: int = 45
@export var map_height: int = 45

@export_category("Algorithm Parameters")
@export var iteration_count: int = 10

var _rng := RandomNumberGenerator.new()


class VoronoiCell:
	var centroid: Vector2
	var biome: Biome
	var points: Array[Vector2] = []

	func _init(p_centroid: Vector2, p_biome: Biome) -> void:
		centroid = p_centroid
		biome = p_biome

	func update_centroid():
		if self.points.size() == 0:
			self.centroid = Vector2.ZERO
			return
		var sum := Vector2.ZERO
		for point in self.points:
			sum += point
		self.centroid = sum / points.size()


func _ready() -> void:
	_rng.randomize()
	print_debug("_rng.seed=", _rng.seed)


func generate_dungeon(tile_map: TileMap) -> MapData:
	var dungeon := MapData.new(map_width, map_height)
	tile_map.update(dungeon)

	# Initialize the Voronoi cells, one per biome, at a random point on the map.
	var voronoi_cells: Array[VoronoiCell] = []
	for biome in [Biome.TUNDRA, Biome.FOREST, Biome.WOODLAND, Biome.DESERT]:
		voronoi_cells.append(
			VoronoiCell.new(Vector2i(_rng.randi_range(1, map_width - 1), _rng.randi_range(1, map_height - 1)), biome)
		)

	for _i in range(iteration_count):
		# Clear grouping from previous iteration.
		for voronoi_cell in voronoi_cells:
			voronoi_cell.points = []

		# Group each tile to its closest Voronoi cell.
		for x in range(map_width):
			for y in range(map_height):
				var closest_voronoi_cell: VoronoiCell = get_closest_voronoi_cell(x, y, voronoi_cells)
				closest_voronoi_cell.points.append(Vector2(x, y))

		# Update TileMap.
		for voronoi_cell in voronoi_cells:
			for point in voronoi_cell.points:
				dungeon.get_tile(point).set_tile_type(get_tile_type(voronoi_cell.biome, dungeon))
		tile_map.update(dungeon)

		await get_tree().create_timer(TILE_MAP_UPDATE_INTERVAL).timeout

		# Calculate centroid of each Voronoi cell.
		for voronoi_cell in voronoi_cells:
			voronoi_cell.update_centroid()

	finished.emit()
	return dungeon


func get_closest_voronoi_cell(x: int, y: int, cells: Array[VoronoiCell]) -> VoronoiCell:
	var closest: VoronoiCell
	var min_distance: float = map_width * map_height
	for cell in cells:
		var distance := euclidean_distance(Vector2i(x, y), cell.centroid)
		if distance < min_distance:
			closest = cell
			min_distance = distance
	return closest


func euclidean_distance(a: Vector2i, b: Vector2i) -> float:
	return sqrt(pow(b.x - a.x, 2) + pow(b.y - a.y, 2))


func get_tile_type(biome: Biome, dungeon: MapData) -> Resource:
	match biome:
		Biome.WOODLAND:
			return [dungeon.TILE_TYPES.grass, dungeon.TILE_TYPES.flower].pick_random()
		Biome.FOREST:
			return [dungeon.TILE_TYPES.oak_tree, dungeon.TILE_TYPES.evergreen_tree].pick_random()
		Biome.DESERT:
			return (
				[
					dungeon.TILE_TYPES.dirt,
					dungeon.TILE_TYPES.fossil,
					dungeon.TILE_TYPES.boulders,
					dungeon.TILE_TYPES.scorpion
				]
				. pick_random()
			)
		Biome.TUNDRA:
			return [dungeon.TILE_TYPES.snow].pick_random()
		_:
			push_error("Unknown biome:", biome)
			return
