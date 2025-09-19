class_name GridSystem
extends Node

signal cell_changed(x: int, y: int, z: int)
signal layer_rebuilt(y: int)

var layers: Dictionary = {}
var _active_layer_y: int = 0

func _ready() -> void:
	add_to_group("grid_system")

func active_layer() -> LayerData:
	if _active_layer_y not in layers:
		layers[_active_layer_y] = LayerData.new()
	return layers[_active_layer_y]

func get_layer(y: int) -> LayerData:
	if y not in layers:
		layers[y] = LayerData.new()
	return layers[y]

func set_active_layer(y: int) -> void:
	if _active_layer_y != y:
		_active_layer_y = y
		layer_rebuilt.emit(y)

func get_active_layer_y() -> int:
	return _active_layer_y

func excavate(points: Array[Vector2i]) -> void:
	var layer := active_layer()
	var changed_cells: Array[Vector2i] = []

	for point in points:
		var current_cell := layer.get_cell(point.x, point.y)
		if current_cell.is_solid():
			var new_cell := CellData.new(CellData.Terrain.EXCAVATED, CellData.Floor.DIRT)
			layer.set_cell(point.x, point.y, new_cell)
			changed_cells.append(point)
			cell_changed.emit(point.x, _active_layer_y, point.y)

	if not changed_cells.is_empty():
		_mark_edges_dirty(changed_cells)

func build_floor(points: Array[Vector2i], floor_type: CellData.Floor) -> void:
	var layer := active_layer()
	var changed_cells: Array[Vector2i] = []

	for point in points:
		var current_cell := layer.get_cell(point.x, point.y)
		if current_cell.is_excavated():
			var new_cell := CellData.new(CellData.Terrain.EXCAVATED, floor_type)
			layer.set_cell(point.x, point.y, new_cell)
			changed_cells.append(point)
			cell_changed.emit(point.x, _active_layer_y, point.y)

	if not changed_cells.is_empty():
		_mark_edges_dirty(changed_cells)

func remove_floor(points: Array[Vector2i]) -> void:
	var layer := active_layer()
	var changed_cells: Array[Vector2i] = []

	for point in points:
		var current_cell := layer.get_cell(point.x, point.y)
		if current_cell.is_excavated() and current_cell.floor != CellData.Floor.NONE:
			var new_cell := CellData.new(CellData.Terrain.EXCAVATED, CellData.Floor.NONE)
			layer.set_cell(point.x, point.y, new_cell)
			changed_cells.append(point)
			cell_changed.emit(point.x, _active_layer_y, point.y)

	if not changed_cells.is_empty():
		_mark_edges_dirty(changed_cells)

func get_cell(x: int, y: int, z: int) -> CellData:
	return get_layer(y).get_cell(x, z)

func _mark_edges_dirty(changed_cells: Array[Vector2i]) -> void:
	var all_affected: Array[Vector2i] = []

	for cell in changed_cells:
		all_affected.append(cell)
		for dx in [-1, 0, 1]:
			for dz in [-1, 0, 1]:
				if dx == 0 and dz == 0:
					continue
				all_affected.append(Vector2i(cell.x + dx, cell.y + dz))

	layer_rebuilt.emit(_active_layer_y)