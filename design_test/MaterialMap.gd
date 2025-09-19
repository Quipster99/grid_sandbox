class_name MaterialMap
extends RefCounted

static func get_wall_material_name(floor_type: CellData.Floor) -> String:
	match floor_type:
		CellData.Floor.DIRT:
			return "dirt_wall"
		CellData.Floor.STONE:
			return "stone_wall"
		CellData.Floor.CONCRETE:
			return "concrete_wall"
		CellData.Floor.METAL:
			return "metal_wall"
		_:
			return ""

static func get_floor_material_name(floor_type: CellData.Floor) -> String:
	match floor_type:
		CellData.Floor.DIRT:
			return "dirt_floor"
		CellData.Floor.STONE:
			return "stone_floor"
		CellData.Floor.CONCRETE:
			return "concrete_floor"
		CellData.Floor.METAL:
			return "metal_floor"
		_:
			return ""

static func get_pillar_material_name(floor_type: CellData.Floor) -> String:
	match floor_type:
		CellData.Floor.STONE:
			return "stone_pillar"
		CellData.Floor.CONCRETE:
			return "concrete_pillar"
		CellData.Floor.METAL:
			return "metal_pillar"
		_:
			return ""

static func get_strongest_floor_material(materials: Array[CellData.Floor]) -> CellData.Floor:
	var strength_order := [CellData.Floor.METAL, CellData.Floor.CONCRETE, CellData.Floor.STONE, CellData.Floor.DIRT]

	for material in strength_order:
		if material in materials:
			return material

	return CellData.Floor.NONE