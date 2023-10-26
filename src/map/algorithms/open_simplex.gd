class_name OpenSimplex
extends Node

signal finished

enum Biome {
	TUNDRA,
	FOREST,
	WOODLAND,
	DESERT,
}

@export_category("Map Dimensions")
@export var map_width: int = 45
@export var map_height: int = 45

@export_category("Algorithm Parameters")
# Determines the strength of each subsequent layer of noise in fractal noise.
# A low value places more emphasis on the lower frequency base layers,
# while a high value puts more emphasis on the higher frequency layers.
@export var fractal_gain: float = 0.3  # Default of 0.5.

# Frequency multiplier between subsequent octaves.
# Increasing this value results in higher octaves producing noise with finer details and a rougher appearance.
@export var fractal_lacunarity: float = 2.0  # Default of 2.0.

# The number of noise layers that are sampled to get the final value for fractal noise types.
@export var fractal_octaves: int = 5  # Default of 5.

# Higher weighting means higher octaves have less impact if lower octaves have a large impact.
@export var fractal_weighted_strength: float = 0.0  # Default of 0.0.

# The frequency for all noise types.
# Low frequency results in smooth noise while high frequency results in rougher, more granular noise.
@export var frequency: float = 0.03  # Default of 0.01.

var t_noise := FastNoiseLite.new()
var p_noise := FastNoiseLite.new()

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	for noise in [t_noise, p_noise]:
		noise.seed = _rng.randi()
		noise.fractal_gain = fractal_gain
		noise.fractal_lacunarity = fractal_lacunarity
		noise.fractal_octaves = fractal_octaves
		noise.frequency = frequency
	print_debug("_rng.seed=", _rng.seed)


func generate_dungeon(tile_map: TileMap) -> MapData:
	var dungeon := MapData.new(map_width, map_height)
	tile_map.update(dungeon)

	for x in range(map_width):
		for y in range(map_height):
			var temperature: float = t_noise.get_noise_2d(x, y)
			var precipitation: float = p_noise.get_noise_2d(x, y)
			var biome: Biome = get_biome(temperature, precipitation)
			dungeon.get_tile(Vector2i(x, y)).set_tile_type(get_tile_type(biome, dungeon))
	tile_map.update(dungeon)

	finished.emit()
	return dungeon


func get_biome(temperature: float, precipitation: float) -> Biome:
	if precipitation > 0:
		if temperature > 0:
			return Biome.WOODLAND
		return Biome.FOREST
	if temperature > 0:
		return Biome.DESERT
	return Biome.TUNDRA


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
