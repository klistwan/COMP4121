extends TileMap

const DEFAULT_LAYER: int = 0
const DEFAULT_SOURCE_ID: int = 0
const WALL: Vector2i = Vector2i(2, 26)
const FLOOR: Vector2i = Vector2i(2, 34)


func update(map_data: MapData) -> void:
	"""Updates each cell per tile in map_data."""
	for tile in map_data.tiles:
		set_cell(
			DEFAULT_LAYER,
			Grid.world_to_grid(tile.position),
			DEFAULT_SOURCE_ID,
			FLOOR if tile.is_walkable() else WALL,
		)
