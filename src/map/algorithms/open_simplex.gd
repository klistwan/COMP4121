class_name OpenSimplex
extends Node

signal finished

@export_category("Map Dimensions")
@export var map_width: int = 45
@export var map_height: int = 45

@export_category("Algorithm Parameters")
# Determines the strength of each subsequent layer of noise in fractal noise.
# A low value places more emphasis on the lower frequency base layers,
# while a high value puts more emphasis on the higher frequency layers.
@export var fractal_gain: float = 0.5  # Default of 0.5.

# Frequency multiplier between subsequent octaves.
# Increasing this value results in higher octaves producing noise with finer details and a rougher appearance.
@export var fractal_lacunarity: float = 2.0  # Default of 2.0.

# The number of noise layers that are sampled to get the final value for fractal noise types.
@export var fractal_octaves: int = 5  # Default of 5.

# Higher weighting means higher octaves have less impact if lower octaves have a large impact.
@export var fractal_weighted_strength: float = 0.0  # Default of 0.0.

# The frequency for all noise types.
# Low frequency results in smooth noise while high frequency results in rougher, more granular noise.
@export var frequency: float = 0.05  # Default of 0.01.

var noise = FastNoiseLite.new()
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
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
			var noise_2d: float = noise.get_noise_2d(x, y)
			if noise_2d > 0:
				dungeon.get_tile(Vector2i(x, y)).set_tile_type(dungeon.TILE_TYPES.evergreen_tree)
			else:
				dungeon.get_tile(Vector2i(x, y)).set_tile_type(dungeon.TILE_TYPES.water)
	tile_map.update(dungeon)

	finished.emit()
	return dungeon
