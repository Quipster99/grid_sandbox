class_name GridTileData
extends RefCounted

enum FloorType {
	NONE,
	DIRT,
	STONE,
	CONCRETE,
	METAL
}

enum TerrainState {
	SOLID,
	MARKED_FOR_REMOVAL,
	BEING_EXCAVATED,
	EXCAVATED
}

enum WallType {
	NONE,
	DIRT,
	STONE,
	REINFORCED
}

@export var floor_type: FloorType = FloorType.NONE
@export var has_terrain_cube: bool = true
@export var terrain_state: TerrainState = TerrainState.SOLID

@export var wall_north: WallType = WallType.DIRT
@export var wall_south: WallType = WallType.DIRT
@export var wall_east: WallType = WallType.DIRT
@export var wall_west: WallType = WallType.DIRT

@export var pillar_northeast: bool = false
@export var pillar_northwest: bool = false
@export var pillar_southeast: bool = false
@export var pillar_southwest: bool = false

@export var custom_properties: Dictionary = {}

func _init(
	p_floor_type: FloorType = FloorType.NONE,
	p_has_terrain: bool = true,
	p_state: TerrainState = TerrainState.SOLID
):
	floor_type = p_floor_type
	has_terrain_cube = p_has_terrain
	terrain_state = p_state

func set_wall_type(face: String, wall_type: WallType):
	match face.to_lower():
		"north", "n":
			wall_north = wall_type
		"south", "s":
			wall_south = wall_type
		"east", "e":
			wall_east = wall_type
		"west", "w":
			wall_west = wall_type

func get_wall_type(face: String) -> WallType:
	match face.to_lower():
		"north", "n":
			return wall_north
		"south", "s":
			return wall_south
		"east", "e":
			return wall_east
		"west", "w":
			return wall_west
		_:
			return WallType.NONE

func set_pillar(corner: String, enabled: bool):
	match corner.to_lower():
		"northeast", "ne":
			pillar_northeast = enabled
		"northwest", "nw":
			pillar_northwest = enabled
		"southeast", "se":
			pillar_southeast = enabled
		"southwest", "sw":
			pillar_southwest = enabled

func get_pillar(corner: String) -> bool:
	match corner.to_lower():
		"northeast", "ne":
			return pillar_northeast
		"northwest", "nw":
			return pillar_northwest
		"southeast", "se":
			return pillar_southeast
		"southwest", "sw":
			return pillar_southwest
		_:
			return false

func mark_for_removal():
	terrain_state = TerrainState.MARKED_FOR_REMOVAL

func start_excavation():
	terrain_state = TerrainState.BEING_EXCAVATED

func complete_excavation():
	terrain_state = TerrainState.EXCAVATED
	has_terrain_cube = false

func is_excavated() -> bool:
	return terrain_state == TerrainState.EXCAVATED

func is_marked_for_removal() -> bool:
	return terrain_state == TerrainState.MARKED_FOR_REMOVAL

func can_place_floor() -> bool:
	# Check if the tile is excavated and ready for floor placement
	return terrain_state == TerrainState.EXCAVATED

func to_dict() -> Dictionary:
	return {
		"floor_type": floor_type,
		"has_terrain_cube": has_terrain_cube,
		"terrain_state": terrain_state,
		"walls": {
			"north": wall_north,
			"south": wall_south,
			"east": wall_east,
			"west": wall_west
		},
		"pillars": {
			"northeast": pillar_northeast,
			"northwest": pillar_northwest,
			"southeast": pillar_southeast,
			"southwest": pillar_southwest
		},
		"custom_properties": custom_properties
	}

func from_dict(data: Dictionary) -> GridTileData:
	floor_type = data.get("floor_type", FloorType.NONE)
	has_terrain_cube = data.get("has_terrain_cube", true)
	terrain_state = data.get("terrain_state", TerrainState.SOLID)

	var walls = data.get("walls", {})
	wall_north = walls.get("north", WallType.DIRT)
	wall_south = walls.get("south", WallType.DIRT)
	wall_east = walls.get("east", WallType.DIRT)
	wall_west = walls.get("west", WallType.DIRT)

	var pillars = data.get("pillars", {})
	pillar_northeast = pillars.get("northeast", false)
	pillar_northwest = pillars.get("northwest", false)
	pillar_southeast = pillars.get("southeast", false)
	pillar_southwest = pillars.get("southwest", false)

	custom_properties = data.get("custom_properties", {})
	return self
