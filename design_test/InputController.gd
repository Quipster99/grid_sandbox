class_name InputController
extends Node

@export var grid_system: GridSystem
@export var camera: Camera3D

enum Tool { EXCAVATE, FLOOR_STONE, FLOOR_CONCRETE, FLOOR_METAL, REMOVE_FLOOR }

var current_tool: Tool = Tool.EXCAVATE
var is_dragging: bool = false
var drag_start: Vector2i
var selected_cells: Array[Vector2i] = []
var hovered_cell: Vector2i = Vector2i(-999, -999)

signal hover_changed(cell_pos: Vector2i)
signal selection_changed(cells: Array[Vector2i])

func _ready() -> void:
	add_to_group("input_controller")
	if not grid_system:
		grid_system = get_tree().get_first_node_in_group("grid_system")

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		_handle_mouse_button(event)
	elif event is InputEventMouseMotion:
		_handle_mouse_motion(event)
	elif event is InputEventKey:
		_handle_key_input(event)

func _handle_mouse_motion(event: InputEventMouseMotion) -> void:
	var cell_pos := _screen_to_grid(event.position)

	# Update hover
	if cell_pos != hovered_cell:
		hovered_cell = cell_pos
		print("Hover changed to: ", hovered_cell)
		hover_changed.emit(hovered_cell)

	# Update drag selection
	if is_dragging and cell_pos != Vector2i(-999, -999):
		var new_selection := _get_rect_cells(drag_start, cell_pos)
		if new_selection != selected_cells:
			selected_cells = new_selection
			selection_changed.emit(selected_cells)

func _handle_mouse_button(event: InputEventMouseButton) -> void:
	if event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var cell_pos := _screen_to_grid(event.position)
			if cell_pos != Vector2i(-999, -999):
				drag_start = cell_pos
				is_dragging = true
				selected_cells = [cell_pos]
		else:
			if is_dragging:
				_apply_tool_to_selection()
				is_dragging = false
				selected_cells.clear()
				selection_changed.emit(selected_cells)

func _handle_key_input(event: InputEventKey) -> void:
	if event.pressed:
		match event.keycode:
			KEY_1:
				current_tool = Tool.EXCAVATE
				print("Tool: Excavate")
			KEY_2:
				current_tool = Tool.FLOOR_STONE
				print("Tool: Stone Floor")
			KEY_3:
				current_tool = Tool.FLOOR_CONCRETE
				print("Tool: Concrete Floor")
			KEY_4:
				current_tool = Tool.FLOOR_METAL
				print("Tool: Metal Floor")
			KEY_5:
				current_tool = Tool.REMOVE_FLOOR
				print("Tool: Remove Floor")
			KEY_Z:
				grid_system.set_active_layer(grid_system.get_active_layer_y() + 1)
				print("Layer up: ", grid_system.get_active_layer_y())
			KEY_X:
				grid_system.set_active_layer(grid_system.get_active_layer_y() - 1)
				print("Layer down: ", grid_system.get_active_layer_y())

func _apply_tool_to_selection() -> void:
	match current_tool:
		Tool.EXCAVATE:
			grid_system.excavate(selected_cells)
		Tool.FLOOR_STONE:
			grid_system.build_floor(selected_cells, CellData.Floor.STONE)
		Tool.FLOOR_CONCRETE:
			grid_system.build_floor(selected_cells, CellData.Floor.CONCRETE)
		Tool.FLOOR_METAL:
			grid_system.build_floor(selected_cells, CellData.Floor.METAL)
		Tool.REMOVE_FLOOR:
			grid_system.remove_floor(selected_cells)

func _screen_to_grid(screen_pos: Vector2) -> Vector2i:
	if not camera:
		return Vector2i(-999, -999)

	var ray_origin := camera.project_ray_origin(screen_pos)
	var ray_direction := camera.project_ray_normal(screen_pos)

	# Step through the ray to find the first solid surface it hits
	var layer_y := grid_system.get_active_layer_y()
	var floor_plane_y := layer_y * 3.0  # wall_height is 3.0
	var top_plane_y := floor_plane_y + 3.0  # Top of terrain cubes

	# Check if ray is pointing towards the planes
	if abs(ray_direction.y) < 0.0001:
		return Vector2i(-999, -999)

	# Calculate intersections with both planes
	var t_floor := (floor_plane_y - ray_origin.y) / ray_direction.y
	var t_top := (top_plane_y - ray_origin.y) / ray_direction.y

	# Only consider positive intersections (in front of camera)
	var intersections: Array[Dictionary] = []

	if t_top > 0:
		var world_pos_top := ray_origin + ray_direction * t_top
		var grid_x := int(round(world_pos_top.x))
		var grid_z := int(round(world_pos_top.z))
		var cell := grid_system.get_cell(grid_x, layer_y, grid_z)

		if cell.is_solid():
			intersections.append({
				"t": t_top,
				"pos": Vector2i(grid_x, grid_z),
				"is_top": true
			})

	if t_floor > 0:
		var world_pos_floor := ray_origin + ray_direction * t_floor
		var grid_x := int(round(world_pos_floor.x))
		var grid_z := int(round(world_pos_floor.z))
		var cell := grid_system.get_cell(grid_x, layer_y, grid_z)

		# Only hit floor if cell is excavated (not blocked by solid cube)
		if not cell.is_solid():
			intersections.append({
				"t": t_floor,
				"pos": Vector2i(grid_x, grid_z),
				"is_top": false
			})

	# Choose the closest intersection
	if intersections.is_empty():
		return Vector2i(-999, -999)

	intersections.sort_custom(func(a, b): return a.t < b.t)
	var closest_hit := intersections[0]

	# Debug output
	if randf() < 0.01:  # Only print occasionally to avoid spam
		print("Ray origin: ", ray_origin)
		print("Ray direction: ", ray_direction)
		print("Hit top face: ", closest_hit.is_top)
		print("Grid pos: ", closest_hit.pos)

	return closest_hit.pos

func _get_rect_cells(start: Vector2i, end: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var min_x: int = min(start.x, end.x)
	var max_x: int = max(start.x, end.x)
	var min_z: int = min(start.y, end.y)
	var max_z: int = max(start.y, end.y)

	for x in range(min_x, max_x + 1):
		for z in range(min_z, max_z + 1):
			cells.append(Vector2i(x, z))

	return cells
