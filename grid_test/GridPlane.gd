extends MeshInstance3D

@export var cell_size: float = 1.0
@export var grid_color: Color = Color(0.8, 0.8, 0.8, 0.5)
@export var auto_update: bool = true

var grid_overlay: MeshInstance3D
var highlight_overlay: MeshInstance3D
var selection_highlight_overlay: MeshInstance3D
var camera: Camera3D
var current_hovered_cell: Vector2i = Vector2i(-999, -999)

var tile_data: Dictionary = {}
var terrain_block_scene: PackedScene
var terrain_block_instances: Dictionary = {}  # Vector2i -> TerrainBlock
var floor_tool_ui: Control

# Selection state
var selection_min: Vector2i = Vector2i(-999, -999)
var selection_max: Vector2i = Vector2i(-999, -999)
var selection_mode: String = "none"

func _ready():
	create_grid_overlay()
	create_highlight_overlay()
	create_selection_highlight_overlay()
	load_terrain_block_scene()
	find_camera()
	find_floor_tool_ui()
	if auto_update:
		connect_mesh_changes()
	update_terrain_blocks()

func _notification(what):
	if what == NOTIFICATION_EDITOR_PRE_SAVE or what == NOTIFICATION_EDITOR_POST_SAVE:
		if grid_overlay:
			update_grid()

func create_grid_overlay():
	if grid_overlay:
		grid_overlay.queue_free()

	grid_overlay = MeshInstance3D.new()
	grid_overlay.name = "GridOverlay"
	add_child(grid_overlay)

	var line_material = StandardMaterial3D.new()
	line_material.flags_unshaded = true
	line_material.albedo_color = grid_color
	line_material.flags_transparent = true
	grid_overlay.material_override = line_material

	update_grid()

func connect_mesh_changes():
	if mesh and mesh.changed.connect(_on_mesh_changed) != OK:
		pass

func _on_mesh_changed():
	if grid_overlay:
		update_grid()

func update_grid():
	if not mesh or not grid_overlay:
		return

	var plane_mesh = mesh as PlaneMesh
	if not plane_mesh:
		return

	var size = plane_mesh.size
	var width = size.x
	var depth = size.y

	var array_mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)

	var vertices = PackedVector3Array()

	var half_width = width / 2.0
	var half_depth = depth / 2.0

	var lines_x = int(width / cell_size) + 1
	var lines_z = int(depth / cell_size) + 1

	for i in range(lines_x):
		var x_pos = -half_width + i * cell_size
		if x_pos > half_width:
			x_pos = half_width

		vertices.push_back(Vector3(x_pos, 0.01, -half_depth))
		vertices.push_back(Vector3(x_pos, 0.01, half_depth))

	for i in range(lines_z):
		var z_pos = -half_depth + i * cell_size
		if z_pos > half_depth:
			z_pos = half_depth

		vertices.push_back(Vector3(-half_width, 0.01, z_pos))
		vertices.push_back(Vector3(half_width, 0.01, z_pos))

	arrays[Mesh.ARRAY_VERTEX] = vertices
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)

	grid_overlay.mesh = array_mesh

func set_cell_size(new_size: float):
	cell_size = new_size
	update_grid()

func set_grid_color(new_color: Color):
	grid_color = new_color
	if grid_overlay and grid_overlay.material_override:
		var material = grid_overlay.material_override as StandardMaterial3D
		if material:
			material.albedo_color = grid_color

func find_camera():
	camera = get_viewport().get_camera_3d()

func find_floor_tool_ui():
	floor_tool_ui = get_node("../UI")

func create_highlight_overlay():
	if highlight_overlay:
		highlight_overlay.queue_free()

	highlight_overlay = MeshInstance3D.new()
	highlight_overlay.name = "HighlightOverlay"
	add_child(highlight_overlay)

	var highlight_material = StandardMaterial3D.new()
	highlight_material.flags_unshaded = true
	highlight_material.albedo_color = Color.BLUE
	highlight_material.flags_transparent = true
	highlight_overlay.material_override = highlight_material
	highlight_overlay.visible = false

func _input(event):
	if event is InputEventMouseMotion and camera:
		handle_mouse_hover(event.position)

func handle_mouse_hover(mouse_pos: Vector2):
	if not mesh or not camera:
		return

	var plane_mesh = mesh as PlaneMesh
	if not plane_mesh:
		return

	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * 1000

	# Check if we're in excavation mode
	var is_excavation_mode = false
	if floor_tool_ui:
		is_excavation_mode = (floor_tool_ui.active_tool_mode == "excavate")

	var intersection_point: Vector3
	var found_intersection = false

	# First try intersecting with terrain cube tops if in excavation mode
	if is_excavation_mode:
		# Create a plane at terrain cube top level (y = 1.0)
		var terrain_top_plane = Plane(Vector3.UP, 1.0)
		var terrain_intersection = terrain_top_plane.intersects_ray(from, to - from)

		if terrain_intersection:
			var local_pos = to_local(terrain_intersection)
			var half_width = plane_mesh.size.x / 2.0
			var half_depth = plane_mesh.size.y / 2.0

			# Check if intersection is within grid bounds
			if abs(local_pos.x) <= half_width and abs(local_pos.z) <= half_depth:
				# Check if there's a terrain block at this position
				var cell_x = int((local_pos.x + half_width) / cell_size)
				var cell_z = int((local_pos.z + half_depth) / cell_size)
				var cell_pos = Vector2i(cell_x, cell_z)
				var tile_data_check = get_tile_data(cell_pos)

				if not tile_data_check.is_excavated():
					intersection_point = terrain_intersection
					found_intersection = true

	# If no terrain block hit or not in excavation mode, raycast against ground plane
	if not found_intersection:
		var plane = Plane(Vector3.UP, global_position.y)
		var intersection = plane.intersects_ray(from, to - from)
		if intersection:
			intersection_point = intersection
			found_intersection = true

	if found_intersection:
		var local_pos = to_local(intersection_point)
		update_hover_highlight(local_pos, plane_mesh.size)
	else:
		highlight_overlay.visible = false
		current_hovered_cell = Vector2i(-999, -999)

func update_hover_highlight(local_pos: Vector3, plane_size: Vector2):
	var half_width = plane_size.x / 2.0
	var half_depth = plane_size.y / 2.0

	if abs(local_pos.x) > half_width or abs(local_pos.z) > half_depth:
		highlight_overlay.visible = false
		current_hovered_cell = Vector2i(-999, -999)
		return

	var cell_x = int((local_pos.x + half_width) / cell_size)
	var cell_z = int((local_pos.z + half_depth) / cell_size)

	var new_cell = Vector2i(cell_x, cell_z)
	if new_cell != current_hovered_cell:
		current_hovered_cell = new_cell
		create_cell_highlight(cell_x, cell_z, plane_size)

func create_cell_highlight(cell_x: int, cell_z: int, plane_size: Vector2):
	var half_width = plane_size.x / 2.0
	var half_depth = plane_size.y / 2.0

	var cell_left = -half_width + cell_x * cell_size
	var cell_right = min(cell_left + cell_size, half_width)
	var cell_top = -half_depth + cell_z * cell_size
	var cell_bottom = min(cell_top + cell_size, half_depth)

	# Determine highlight height based on tool mode
	var is_excavation_mode = false
	if floor_tool_ui:
		is_excavation_mode = (floor_tool_ui.active_tool_mode == "excavate")

	# Check if this tile has a terrain block
	var cell_pos = Vector2i(cell_x, cell_z)
	var tile_data = get_tile_data(cell_pos)

	# Set highlight height based on mode and tile state
	var highlight_y = 0.02  # Default floor level
	if is_excavation_mode and not tile_data.is_excavated():
		highlight_y = 1.02  # Terrain cube top level

	# Create highlight mesh
	var array_mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	var vertices = PackedVector3Array()

	# Draw cell edge lines at the appropriate height
	vertices.push_back(Vector3(cell_left, highlight_y, cell_top))
	vertices.push_back(Vector3(cell_right, highlight_y, cell_top))

	vertices.push_back(Vector3(cell_right, highlight_y, cell_top))
	vertices.push_back(Vector3(cell_right, highlight_y, cell_bottom))

	vertices.push_back(Vector3(cell_right, highlight_y, cell_bottom))
	vertices.push_back(Vector3(cell_left, highlight_y, cell_bottom))

	vertices.push_back(Vector3(cell_left, highlight_y, cell_bottom))
	vertices.push_back(Vector3(cell_left, highlight_y, cell_top))

	arrays[Mesh.ARRAY_VERTEX] = vertices
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)

	highlight_overlay.mesh = array_mesh
	highlight_overlay.visible = true

func get_tile_data(cell_pos: Vector2i) -> GridTileData:
	if not tile_data.has(cell_pos):
		tile_data[cell_pos] = GridTileData.new()
	return tile_data[cell_pos]

func set_tile_data(cell_pos: Vector2i, data: GridTileData):
	tile_data[cell_pos] = data

func get_tile_at_world_pos(world_pos: Vector3) -> Vector2i:
	if not mesh:
		return Vector2i(-999, -999)

	var plane_mesh = mesh as PlaneMesh
	if not plane_mesh:
		return Vector2i(-999, -999)

	var local_pos = to_local(world_pos)
	var plane_size = plane_mesh.size
	var half_width = plane_size.x / 2.0
	var half_depth = plane_size.y / 2.0

	if abs(local_pos.x) > half_width or abs(local_pos.z) > half_depth:
		return Vector2i(-999, -999)

	var cell_x = int((local_pos.x + half_width) / cell_size)
	var cell_z = int((local_pos.z + half_depth) / cell_size)

	return Vector2i(cell_x, cell_z)

func get_hovered_tile_data() -> GridTileData:
	if current_hovered_cell == Vector2i(-999, -999):
		return null
	return get_tile_data(current_hovered_cell)

func mark_tile_for_removal(cell_pos: Vector2i):
	var data = get_tile_data(cell_pos)
	data.mark_for_removal()

func excavate_tile(cell_pos: Vector2i):
	var data = get_tile_data(cell_pos)
	data.complete_excavation()
	update_terrain_blocks()

func set_floor_type(cell_pos: Vector2i, floor_type: int):
	var data = get_tile_data(cell_pos)
	if data.can_place_floor():
		data.floor_type = floor_type

func get_grid_bounds() -> Dictionary:
	if not mesh:
		return {"min_x": 0, "max_x": 0, "min_z": 0, "max_z": 0}

	var plane_mesh = mesh as PlaneMesh
	if not plane_mesh:
		return {"min_x": 0, "max_x": 0, "min_z": 0, "max_z": 0}

	var size = plane_mesh.size
	var cells_x = int(size.x / cell_size)
	var cells_z = int(size.y / cell_size)

	return {
		"min_x": 0,
		"max_x": cells_x - 1,
		"min_z": 0,
		"max_z": cells_z - 1
	}

func save_tile_data_to_file(file_path: String) -> bool:
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if not file:
		return false

	var save_data = {}
	for pos in tile_data:
		save_data[str(pos)] = tile_data[pos].to_dict()

	file.store_string(JSON.stringify(save_data))
	file.close()
	return true

func load_tile_data_from_file(file_path: String) -> bool:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		return false

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	var parse_result = json.parse(json_string)
	if parse_result != OK:
		return false

	var loaded_data = json.data
	tile_data.clear()

	for pos_str in loaded_data:
		var pos_array = pos_str.strip_edges("(").strip_edges(")").split(",")
		var pos = Vector2i(int(pos_array[0]), int(pos_array[1]))
		var tile_data_instance = GridTileData.new()
		tile_data[pos] = tile_data_instance.from_dict(loaded_data[pos_str])

	return true


func load_terrain_block_scene():
	terrain_block_scene = load("res://terrain_block.tscn")
	if not terrain_block_scene:
		print("Error: Could not load terrain_block.tscn")

func update_terrain_blocks():
	if not mesh or not terrain_block_scene:
		return

	var plane_mesh = mesh as PlaneMesh
	if not plane_mesh:
		return

	var size = plane_mesh.size
	var cells_x = int(size.x / cell_size)
	var cells_z = int(size.y / cell_size)
	var half_width = size.x / 2.0
	var half_depth = size.y / 2.0

	# Remove terrain blocks for excavated tiles
	for pos in terrain_block_instances.keys():
		var data = get_tile_data(pos)
		if data.is_excavated():
			var instance = terrain_block_instances[pos]
			if instance:
				instance.queue_free()
			terrain_block_instances.erase(pos)

	# Add terrain blocks for non-excavated tiles
	for x in range(cells_x):
		for z in range(cells_z):
			var cell_pos = Vector2i(x, z)
			var data = get_tile_data(cell_pos)

			if not data.is_excavated() and not terrain_block_instances.has(cell_pos):
				var instance = terrain_block_scene.instantiate() as TerrainBlock
				add_child(instance)

				# Position the terrain block
				var world_x = -half_width + (x + 0.5) * cell_size
				var world_z = -half_depth + (z + 0.5) * cell_size
				instance.position = Vector3(world_x, 0, world_z)

				# Scale to match cell size
				instance.scale = Vector3(cell_size, 1.0, cell_size)

				# Configure wall cladding based on tile data
				instance.configure_from_tile_data(data)

				terrain_block_instances[cell_pos] = instance

func clear_all_terrain_blocks():
	for instance in terrain_block_instances.values():
		if instance:
			instance.queue_free()
	terrain_block_instances.clear()

func get_terrain_block_at(cell_pos: Vector2i) -> TerrainBlock:
	return terrain_block_instances.get(cell_pos, null)

func update_terrain_block_walls(cell_pos: Vector2i):
	var terrain_block = get_terrain_block_at(cell_pos)
	if terrain_block:
		var data = get_tile_data(cell_pos)
		terrain_block.configure_from_tile_data(data)

func toggle_wall_at_position(cell_pos: Vector2i, face: String):
	var terrain_block = get_terrain_block_at(cell_pos)
	if terrain_block:
		terrain_block.toggle_wall_face(face)

		# Update the tile data to reflect the change
		var data = get_tile_data(cell_pos)
		var current_wall_type = data.get_wall_type(face)
		var new_wall_type = GridTileData.WallType.NONE if current_wall_type != GridTileData.WallType.NONE else GridTileData.WallType.DIRT
		data.set_wall_type(face, new_wall_type)

func create_selection_highlight_overlay():
	if selection_highlight_overlay:
		selection_highlight_overlay.queue_free()

	selection_highlight_overlay = MeshInstance3D.new()
	selection_highlight_overlay.name = "SelectionHighlightOverlay"
	add_child(selection_highlight_overlay)

	var selection_material = StandardMaterial3D.new()
	selection_material.flags_unshaded = true
	selection_material.albedo_color = Color.YELLOW
	selection_material.flags_transparent = true
	selection_highlight_overlay.material_override = selection_material
	selection_highlight_overlay.visible = false

func set_selection_highlight(min_cell: Vector2i, max_cell: Vector2i, mode: String):
	selection_min = min_cell
	selection_max = max_cell
	selection_mode = mode
	create_selection_highlight_mesh()

func clear_selection_highlight():
	selection_min = Vector2i(-999, -999)
	selection_max = Vector2i(-999, -999)
	selection_mode = "none"
	selection_highlight_overlay.visible = false

func create_selection_highlight_mesh():
	if not mesh or selection_min == Vector2i(-999, -999):
		selection_highlight_overlay.visible = false
		return

	var plane_mesh = mesh as PlaneMesh
	if not plane_mesh:
		return

	var size = plane_mesh.size
	var half_width = size.x / 2.0
	var half_depth = size.y / 2.0

	# Calculate world positions for selection rectangle
	var world_left = -half_width + selection_min.x * cell_size
	var world_right = -half_width + (selection_max.x + 1) * cell_size
	var world_top = -half_depth + selection_min.y * cell_size
	var world_bottom = -half_depth + (selection_max.y + 1) * cell_size

	# Clamp to grid bounds
	world_right = min(world_right, half_width)
	world_bottom = min(world_bottom, half_depth)

	# Determine highlight height based on selection mode
	var highlight_y = 0.03  # Default floor level
	if selection_mode == "excavate":
		highlight_y = 1.03  # Terrain cube top level

	var array_mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	var vertices = PackedVector3Array()

	# Draw selection rectangle outline
	vertices.push_back(Vector3(world_left, highlight_y, world_top))
	vertices.push_back(Vector3(world_right, highlight_y, world_top))

	vertices.push_back(Vector3(world_right, highlight_y, world_top))
	vertices.push_back(Vector3(world_right, highlight_y, world_bottom))

	vertices.push_back(Vector3(world_right, highlight_y, world_bottom))
	vertices.push_back(Vector3(world_left, highlight_y, world_bottom))

	vertices.push_back(Vector3(world_left, highlight_y, world_bottom))
	vertices.push_back(Vector3(world_left, highlight_y, world_top))

	# Add interior grid lines for large selections
	if selection_max.x - selection_min.x > 0:
		for x in range(selection_min.x + 1, selection_max.x + 1):
			var world_x = -half_width + x * cell_size
			if world_x < world_right:
				vertices.push_back(Vector3(world_x, highlight_y, world_top))
				vertices.push_back(Vector3(world_x, highlight_y, world_bottom))

	if selection_max.y - selection_min.y > 0:
		for z in range(selection_min.y + 1, selection_max.y + 1):
			var world_z = -half_depth + z * cell_size
			if world_z < world_bottom:
				vertices.push_back(Vector3(world_left, highlight_y, world_z))
				vertices.push_back(Vector3(world_right, highlight_y, world_z))

	arrays[Mesh.ARRAY_VERTEX] = vertices
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)

	selection_highlight_overlay.mesh = array_mesh
	selection_highlight_overlay.visible = true
