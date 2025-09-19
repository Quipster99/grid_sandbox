class_name LayerData
extends RefCounted

var cells: Dictionary = {}

func _init() -> void:
	cells = {}

func get_cell(x: int, z: int) -> CellData:
	var key := "%d,%d" % [x, z]
	if key in cells:
		return cells[key]
	return CellData.new(CellData.Terrain.SOLID, CellData.Floor.NONE)

func set_cell(x: int, z: int, cell_data: CellData) -> void:
	var key := "%d,%d" % [x, z]
	if cell_data.is_solid() and cell_data.floor == CellData.Floor.NONE:
		cells.erase(key)
	else:
		cells[key] = cell_data

func has_cell(x: int, z: int) -> bool:
	var key := "%d,%d" % [x, z]
	return key in cells

func get_all_cells() -> Dictionary:
	return cells.duplicate()

func clear() -> void:
	cells.clear()

func to_dict() -> Dictionary:
	var result := {}
	for key in cells:
		result[key] = cells[key].to_dict()
	return result

static func from_dict(data: Dictionary) -> LayerData:
	var layer := LayerData.new()
	for key in data:
		layer.cells[key] = CellData.from_dict(data[key])
	return layer