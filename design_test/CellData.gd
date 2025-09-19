class_name CellData
extends RefCounted

enum Terrain {
	SOLID,
	MARKED,
	DIGGING,
	EXCAVATED
}

enum Floor {
	NONE,
	DIRT,
	STONE,
	CONCRETE,
	METAL
}

@export var terrain: Terrain = Terrain.SOLID
@export var floor: Floor = Floor.NONE

func _init(p_terrain: Terrain = Terrain.SOLID, p_floor: Floor = Floor.NONE) -> void:
	terrain = p_terrain
	floor = p_floor

func has_any_floor() -> bool:
	return floor != Floor.NONE

func is_solid() -> bool:
	return terrain == Terrain.SOLID

func is_excavated() -> bool:
	return terrain == Terrain.EXCAVATED

func to_dict() -> Dictionary:
	return {
		"t": terrain,
		"f": floor
	}

static func from_dict(data: Dictionary) -> CellData:
	var cell := CellData.new()
	cell.terrain = data.get("t", Terrain.SOLID)
	cell.floor = data.get("f", Floor.NONE)
	return cell