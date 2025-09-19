class_name AutoGeo
extends RefCounted

static func is_wall_edge(grid: GridSystem, x: int, y: int, z: int, direction: Vector2i) -> bool:
	var current_cell := grid.get_cell(x, y, z)
	var neighbor_cell := grid.get_cell(x + direction.x, y, z + direction.y)

	var current_has_floor := current_cell.has_any_floor() and current_cell.is_excavated()
	var neighbor_is_solid := neighbor_cell.is_solid()

	return current_has_floor and neighbor_is_solid

static func get_wall_material(grid: GridSystem, x: int, y: int, z: int) -> CellData.Floor:
	var cell := grid.get_cell(x, y, z)
	if cell.is_excavated() and cell.has_any_floor():
		return cell.floor
	return CellData.Floor.NONE

static func get_edge_floor_material(grid: GridSystem, x: int, y: int, z: int, direction: Vector2i) -> CellData.Floor:
	var current_cell := grid.get_cell(x, y, z)
	var neighbor_cell := grid.get_cell(x + direction.x, y, z + direction.y)

	var materials: Array[CellData.Floor] = []

	if current_cell.is_excavated() and current_cell.has_any_floor():
		materials.append(current_cell.floor)

	if neighbor_cell.is_excavated() and neighbor_cell.has_any_floor():
		materials.append(neighbor_cell.floor)

	return MaterialMap.get_strongest_floor_material(materials)

static func get_wall_edges(grid: GridSystem, x: int, y: int, z: int) -> Array[Vector2i]:
	var edges: Array[Vector2i] = []
	var directions := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

	for direction in directions:
		if is_wall_edge(grid, x, y, z, direction):
			edges.append(direction)

	return edges

static func corner_has_pillar(grid: GridSystem, x: int, y: int, z: int) -> bool:
	var cell := grid.get_cell(x, y, z)

	# Must be excavated with a built floor (not dirt, not none)
	if not cell.is_excavated():
		return false
	if cell.floor == CellData.Floor.NONE or cell.floor == CellData.Floor.DIRT:
		return false

	# Must have at least 2 walls
	var edges := get_wall_edges(grid, x, y, z)
	if edges.size() < 2:
		return false

	# Must have perpendicular walls
	return _has_perpendicular_walls(edges)

static func get_pillar_material(grid: GridSystem, x: int, y: int, z: int) -> CellData.Floor:
	var edges := get_wall_edges(grid, x, y, z)
	var wall_materials: Array[CellData.Floor] = []

	for edge in edges:
		var wall_material := get_edge_floor_material(grid, x, y, z, edge)
		if wall_material != CellData.Floor.NONE:
			wall_materials.append(wall_material)

	return MaterialMap.get_strongest_floor_material(wall_materials)

static func _has_perpendicular_walls(edges: Array[Vector2i]) -> bool:
	for i in range(edges.size()):
		for j in range(i + 1, edges.size()):
			var edge1 := edges[i]
			var edge2 := edges[j]
			if edge1.x * edge2.x + edge1.y * edge2.y == 0:
				return true
	return false
