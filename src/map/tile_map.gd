extends TileMap

const DEFAULT_LAYER: int = 0
const DEFAULT_SOURCE_ID: int = 0


func update(map_data: MapData) -> void:
	"""Updates each cell per tile in map_data."""
	for tile in map_data.tiles:
		set_cell(
			DEFAULT_LAYER,
			Grid.world_to_grid(tile.position),
			DEFAULT_SOURCE_ID,
			tile.texture.region.position / 16,
		)
