class_name GridBasedRoomPlacement
extends Node

signal finished

const MAX_ROOMS := 9
const MAX_ROOM_SIZE := Vector2i(13, 13)
const STEP_PAUSE_INTERVAL := 0.4

@export_category("Map Dimensions")
@export var map_width: int = 45
@export var map_height: int = 45

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	print_debug("_rng.seed=", _rng.seed)


func rnd(max_range: int) -> int:
	"""Pick a random number in [0, max_range)."""
	var res = 0 if max_range < 1 else _rng.randi() % max_range
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
		var top := Vector2i(
			(i % 3) * 15 + 1,
			i / 3 * 15,
		)

		# Find a random size and position for the room.
		var size := Vector2i(
			rnd(MAX_ROOM_SIZE.x - 4) + 4,
			rnd(MAX_ROOM_SIZE.y - 4) + 4,
		)
		var pos := Vector2i(
			top.x + rnd(MAX_ROOM_SIZE.x - size.x),
			top.y + rnd(MAX_ROOM_SIZE.y - size.y),
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
			draw_corridor(r1.index, r2.index, rooms, dungeon)
			r1.isconn[r2.index] = 1
			r2.isconn[r1.index] = 1
			room_count += 1
			tile_map.update(dungeon)
			await get_tree().create_timer(STEP_PAUSE_INTERVAL).timeout

	# Add a random number of passages so there isn't always just one unique passage through it.
	for _room_count in range(rnd(5), 0, -1):
		# Choose a random room.
		r1 = rdes[rnd(MAX_ROOMS)]
		# Find an adjacent room not already connected.
		var j := 0
		for i in range(MAX_ROOMS):
			if r1.conn[i] && !r1.isconn[i] && rnd(j) == 0:
				j += 1
				r2 = rdes[i]
		# If there is one, connect it and look for the next added.
		if j != 0:
			draw_corridor(r1.index, r2.index, rooms, dungeon)
			r1.isconn[r2.index] = 1
			r2.isconn[r1.index] = 1
			tile_map.update(dungeon)
			await get_tree().create_timer(STEP_PAUSE_INTERVAL).timeout

	finished.emit()
	return dungeon


func draw_corridor(r1: int, r2: int, rooms: Array[Rect2i], dungeon: MapData) -> void:
	# One room is to the left of the other.
	if abs(r1 - r2) == 1:
		if r1 + 1 == r2:
			draw_horizontal_corridor(rooms[r1], rooms[r2], dungeon)
		elif r2 + 1 == r1:
			draw_horizontal_corridor(rooms[r2], rooms[r1], dungeon)
	# One room is above the other.
	elif abs(r1 - r2) == 3:
		if r1 + 3 == r2:
			draw_vertical_corridor(rooms[r1], rooms[r2], dungeon)
		elif r2 + 3 == r1:
			draw_vertical_corridor(rooms[r2], rooms[r1], dungeon)
	else:
		push_error("Rooms at indices", r1, r2, "are not adjacent")


func draw_horizontal_corridor(left_room: Rect2i, right_room: Rect2i, dungeon: MapData) -> void:
	var door1 = Vector2i(
		left_room.position.x + left_room.size.x,
		_rng.randi_range(left_room.position.y + 1, left_room.position.y + left_room.size.y - 1)
	)
	var door2 = Vector2i(
		right_room.position.x,
		_rng.randi_range(right_room.position.y + 1, right_room.position.y + right_room.size.y - 1)
	)

	# Draw doors.
	_carve_tile(dungeon, door1.x, door1.y, dungeon.TILE_TYPES.door)
	_carve_tile(dungeon, door2.x, door2.y, dungeon.TILE_TYPES.door)

	# Find midpoint between two doors.
	var midpoint = _rng.randi_range(door1.x + 1, door2.x - 1)

	_tunnel_horizontal(dungeon, door1.y, door1.x + 1, midpoint)
	_tunnel_horizontal(dungeon, door2.y, door2.x - 1, midpoint)
	_tunnel_vertical(dungeon, midpoint, door1.y, door2.y)


func draw_vertical_corridor(top_room: Rect2i, bottom_room: Rect2i, dungeon: MapData) -> void:
	var door1 = Vector2(
		_rng.randi_range(top_room.position.x + 1, top_room.position.x + top_room.size.x - 1),
		top_room.position.y + top_room.size.y
	)
	var door2 = Vector2(
		_rng.randi_range(bottom_room.position.x + 1, bottom_room.position.x + bottom_room.size.x - 1),
		bottom_room.position.y
	)

	# Draw doors.
	_carve_tile(dungeon, door1.x, door1.y, dungeon.TILE_TYPES.door)
	_carve_tile(dungeon, door2.x, door2.y, dungeon.TILE_TYPES.door)

	# Find midpoint between two doors.
	var midpoint = _rng.randi_range(door1.y + 1, door2.y - 1)

	_tunnel_vertical(dungeon, door1.x, door1.y + 1, midpoint)
	_tunnel_vertical(dungeon, door2.x, door2.y - 1, midpoint)
	_tunnel_horizontal(dungeon, midpoint, door1.x, door2.x)


func _tunnel_horizontal(dungeon: MapData, y: int, x_start: int, x_end: int) -> void:
	var x_min: int = mini(x_start, x_end)
	var x_max: int = maxi(x_start, x_end)
	for x in range(x_min, x_max + 1):
		_carve_tile(dungeon, x, y, dungeon.TILE_TYPES.floor)


func _tunnel_vertical(dungeon: MapData, x: int, y_start: int, y_end: int) -> void:
	var y_min: int = mini(y_start, y_end)
	var y_max: int = maxi(y_start, y_end)
	for y in range(y_min, y_max + 1):
		_carve_tile(dungeon, x, y, dungeon.TILE_TYPES.floor)


func _carve_room(dungeon: MapData, room: Rect2i) -> void:
	var inner: Rect2i = room.grow(-1)
	for y in range(inner.position.y, inner.end.y + 1):
		for x in range(inner.position.x, inner.end.x + 1):
			_carve_tile(dungeon, x, y, dungeon.TILE_TYPES.floor)


func _carve_tile(dungeon: MapData, x: int, y: int, tile_type: Resource) -> void:
	var tile_position = Vector2i(x, y)
	var tile: Tile = dungeon.get_tile(tile_position)
	tile.set_tile_type(tile_type)
