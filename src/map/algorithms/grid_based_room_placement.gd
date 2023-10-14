class_name GridBasedRoomPlacement
extends Node

signal finished

const MAX_ROOMS := 9
const MAX_ROOM_SIZE := Vector2i(14, 14)
const STEP_PAUSE_INTERVAL := 0.4

@export_category("Map Dimensions")
@export var map_width: int = 45
@export var map_height: int = 45

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()


func generate_dungeon(tile_map: TileMap) -> MapData:
	var dungeon := MapData.new(map_width, map_height)
	var rooms: Array[Rect2i] = []

	# Add rooms.
	for i in range(MAX_ROOMS):
		# Find upper left corner of box that this room goes in.
		var top := Vector2i((i % 3) * MAX_ROOM_SIZE.x + 1, i / 3 * MAX_ROOM_SIZE.y)

		# Find a random size and position for the room.
		var size := Vector2i(
			_rng.randi_range(4, MAX_ROOM_SIZE.x),
			_rng.randi_range(4, MAX_ROOM_SIZE.y),
		)
		var pos := Vector2i(
			top.x + _rng.randi_range(0, MAX_ROOM_SIZE.x - size.x),
			top.y + _rng.randi_range(0, MAX_ROOM_SIZE.y - size.y),
		)

		# Add the room.
		var new_room := Rect2i(pos, size)
		_carve_room(dungeon, new_room)
		tile_map.update(dungeon)
		await get_tree().create_timer(STEP_PAUSE_INTERVAL).timeout
		rooms.append(new_room)

	finished.emit()
	return dungeon


func _carve_room(dungeon: MapData, room: Rect2i) -> void:
	var inner: Rect2i = room.grow(-1)
	for y in range(inner.position.y, inner.end.y + 1):
		for x in range(inner.position.x, inner.end.x + 1):
			_carve_tile(dungeon, x, y)


func _carve_tile(dungeon: MapData, x: int, y: int) -> void:
	var tile_position = Vector2i(x, y)
	var tile: Tile = dungeon.get_tile(tile_position)
	tile.set_tile_type(dungeon.TILE_TYPES.floor)
