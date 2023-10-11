class_name GridBasedRoomPlacement
extends Node

signal finished

const STEP_PAUSE_INTERVAL := 0.4

@export_category("Map Dimensions")
@export var map_width: int = 45
@export var map_height: int = 45

@export_category("Rooms RNG")
@export var min_rooms: int = 5
@export var max_rooms: int = 9
@export var room_max_size: int = 12
@export var room_min_size: int = 4

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()


func generate_dungeon(tile_map: TileMap) -> MapData:
	var dungeon := MapData.new(map_width, map_height)
	var rooms: Array[Rect2i] = []
	var num_rooms = min_rooms + randi() % (max_rooms - min_rooms + 1)
	var used_sectors := {}

	for _idx in range(num_rooms):
		# Randomly select a sector that has not been chosen yet.
		var sector := Vector2i(randi() % 3, randi() % 3)
		while used_sectors.has(sector):
			sector = Vector2i(randi() % 3, randi() % 3)
		used_sectors[sector] = true

		# Generate room dimensions.
		var room_width: int = _rng.randi_range(room_min_size, room_max_size)
		var room_height: int = _rng.randi_range(room_min_size, room_max_size)

		# Generate room position within the sector.
		var x: int = _rng.randi_range(15 * sector.x, 15 * (sector.x + 1) - room_width - 1)
		var y: int = _rng.randi_range(15 * sector.y, 15 * (sector.y + 1) - room_height - 1)

		var new_room := Rect2i(x, y, room_width, room_height)

		_carve_room(dungeon, new_room)
		tile_map.update(dungeon)
		await get_tree().create_timer(STEP_PAUSE_INTERVAL).timeout

		if !rooms.is_empty():
			_tunnel_between(dungeon, rooms.back().get_center(), new_room.get_center())
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


func _tunnel_horizontal(dungeon: MapData, y: int, x_start: int, x_end: int) -> void:
	var x_min: int = mini(x_start, x_end)
	var x_max: int = maxi(x_start, x_end)
	for x in range(x_min, x_max + 1):
		_carve_tile(dungeon, x, y)


func _tunnel_vertical(dungeon: MapData, x: int, y_start: int, y_end: int) -> void:
	var y_min: int = mini(y_start, y_end)
	var y_max: int = maxi(y_start, y_end)
	for y in range(y_min, y_max + 1):
		_carve_tile(dungeon, x, y)


func _tunnel_between(dungeon: MapData, start: Vector2i, end: Vector2i) -> void:
	if _rng.randf() < 0.5:
		_tunnel_horizontal(dungeon, start.y, start.x, end.x)
		_tunnel_vertical(dungeon, end.x, start.y, end.y)
	else:
		_tunnel_vertical(dungeon, start.x, start.y, end.y)
		_tunnel_horizontal(dungeon, end.y, start.x, end.x)


func _carve_tile(dungeon: MapData, x: int, y: int) -> void:
	var tile_position = Vector2i(x, y)
	var tile: Tile = dungeon.get_tile(tile_position)
	tile.set_tile_type(dungeon.TILE_TYPES.floor)
