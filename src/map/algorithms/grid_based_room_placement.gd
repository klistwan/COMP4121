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


func rnd(max_range: int) -> int:
	"""Pick a random number in [0, max_range)."""
	var res = 0 if max_range < 1 else randi() % max_range
	return res


class RoomDescription:
	# Element i indicates if room i is adjacent.
	var conn: Array[int]
	# Element i indicates if connection has been made to room i.
	var isconn: Array[int] = [0, 0, 0, 0, 0, 0, 0, 0, 0]
	# Boolean indicating if this room is in the graph.
	var ingraph: bool = false
	# Room index (e.g. 0 is room in the top-left, 1 is room in the top-middle, etc).
	var index: int

	func _init(p_conn: Array[int], p_index: int) -> void:
		self.conn = p_conn
		self.index = p_index


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

	# Initialize room graph description.
	var rdes: Array[RoomDescription] = [
		RoomDescription.new([0, 1, 0, 1, 0, 0, 0, 0, 0], 0),
		RoomDescription.new([1, 0, 1, 0, 1, 0, 0, 0, 0], 1),
		RoomDescription.new([0, 1, 0, 0, 0, 1, 0, 0, 0], 2),
		RoomDescription.new([1, 0, 0, 0, 1, 0, 1, 0, 0], 3),
		RoomDescription.new([0, 1, 0, 1, 0, 1, 0, 1, 0], 4),
		RoomDescription.new([0, 0, 1, 0, 1, 0, 0, 0, 1], 5),
		RoomDescription.new([0, 0, 0, 1, 0, 0, 0, 1, 0], 6),
		RoomDescription.new([0, 0, 0, 0, 1, 0, 1, 0, 1], 7),
		RoomDescription.new([0, 0, 0, 0, 0, 1, 0, 1, 0], 8),
	]

	# Starting with one room, connect it to a random adjacent room, and then pick a new room to start with.
	var room_count := 1
	var r1 = rdes[rnd(MAX_ROOMS)]
	var r2: RoomDescription
	r1.ingraph = true

	while room_count < MAX_ROOMS:
		# Find a room to connect with.
		var j := 0
		for i in range(MAX_ROOMS):
			if r1.conn[i] and !rdes[i].ingraph and rnd(j) == 0:
				j += 1
				r2 = rdes[i]
		# If no adjacent rooms are outside the graph, pick a new room to look from.
		if j == 0:
			r1 = rdes[rnd(MAX_ROOMS)]
			while !r1.ingraph:
				r1 = rdes[rnd(MAX_ROOMS)]
		# Otherwise, connect new room to the graph, and draw a tunnel to it.
		else:
			r2.ingraph = true
			draw_corridor(r1.index, r2.index)
			r1.isconn[r2.index] = 1
			r2.isconn[r1.index] = 1
			room_count += 1

	finished.emit()
	return dungeon


func draw_corridor(r1: int, r2: int) -> void:
	print("Draw corridor from", r1, "to", r2)


func _carve_room(dungeon: MapData, room: Rect2i) -> void:
	var inner: Rect2i = room.grow(-1)
	for y in range(inner.position.y, inner.end.y + 1):
		for x in range(inner.position.x, inner.end.x + 1):
			_carve_tile(dungeon, x, y)


func _carve_tile(dungeon: MapData, x: int, y: int) -> void:
	var tile_position = Vector2i(x, y)
	var tile: Tile = dungeon.get_tile(tile_position)
	tile.set_tile_type(dungeon.TILE_TYPES.floor)
