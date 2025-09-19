class_name SliceRenderer
extends Node3D

@export var cell_size: float = 1.0
@export var wall_height: float = 3.0
@export var terrain_size: int = 20
@export var show_solid_terrain: bool = true

var grid_system: GridSystem
var floor_instances: Dictionary = {}
var wall_instances: Dictionary = {}
var pillar_instances: Dictionary = {}
var solid_terrain_instances: Dictionary = {}
var hover_highlight: MeshInstance3D
var selection_highlights: Array[MeshInstance3D] = []

func _ready() -> void:
	grid_system = get_tree().get_first_node_in_group("grid_system")
	if grid_system:
		grid_system.layer_rebuilt.connect(_on_layer_rebuilt)
		# Show initial terrain
		call_deferred("rebuild_active_layer")

	_create_hover_highlight()

	# Try to connect to input controller with a slight delay
	call_deferred("_connect_to_input_controller")

func _on_layer_rebuilt(y: int) -> void:
	if y == grid_system.get_active_layer_y():
		rebuild_active_layer()

func rebuild_active_layer() -> void:
	clear_instances()
	var layer := grid_system.active_layer()
	var y := grid_system.get_active_layer_y()

	# Render solid terrain grid
	if show_solid_terrain:
		_create_solid_terrain_grid(y)

	# Render excavated areas
	for key in layer.get_all_cells():
		var coords: PackedStringArray = key.split(",")
		var x := int(coords[0])
		var z := int(coords[1])
		var cell := layer.get_cell(x, z)

		if cell.is_excavated() and cell.has_any_floor():
			_create_floor_instance(x, y, z, cell.floor)
			_create_wall_instances(x, y, z)

			if AutoGeo.corner_has_pillar(grid_system, x, y, z):
				print("Creating pillar at: ", x, ",", y, ",", z)
				_create_pillar_instance(x, y, z)
			else:
				print("No pillar at: ", x, ",", y, ",", z, " - cell floor:", cell.floor)

func _create_floor_instance(x: int, y: int, z: int, floor_type: CellData.Floor) -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.position = Vector3(x * cell_size, y * wall_height, z * cell_size)

	var box_mesh := BoxMesh.new()
	box_mesh.size = Vector3(cell_size, 0.1, cell_size)
	mesh_instance.mesh = box_mesh

	var material := StandardMaterial3D.new()
	material.albedo_color = _get_floor_color(floor_type)
	mesh_instance.material_override = material

	add_child(mesh_instance)
	var key := "%d,%d,%d" % [x, y, z]
	floor_instances[key] = mesh_instance

func _create_wall_instances(x: int, y: int, z: int) -> void:
	var edges := AutoGeo.get_wall_edges(grid_system, x, y, z)

	for edge in edges:
		var wall_material := AutoGeo.get_edge_floor_material(grid_system, x, y, z, edge)

		var wall_pos := Vector3(
			(x + edge.x * 0.5) * cell_size,
			y * wall_height + wall_height * 0.5,
			(z + edge.y * 0.5) * cell_size
		)

		var mesh_instance := MeshInstance3D.new()
		mesh_instance.position = wall_pos

		var box_mesh := BoxMesh.new()
		if abs(edge.x) > 0:
			box_mesh.size = Vector3(0.1, wall_height, cell_size)
		else:
			box_mesh.size = Vector3(cell_size, wall_height, 0.1)

		mesh_instance.mesh = box_mesh

		var material := StandardMaterial3D.new()
		material.albedo_color = _get_wall_color(wall_material)
		mesh_instance.material_override = material

		add_child(mesh_instance)
		var key := "%d,%d,%d,%d,%d" % [x, y, z, edge.x, edge.y]
		wall_instances[key] = mesh_instance

func _create_pillar_instance(x: int, y: int, z: int) -> void:
	var pillar_material := AutoGeo.get_pillar_material(grid_system, x, y, z)
	var edges := AutoGeo.get_wall_edges(grid_system, x, y, z)

	# Find which corner of the floor tile should have the pillar
	# Based on which directions have walls (inward from solid terrain)
	var pillar_offset := Vector3.ZERO
	for i in range(edges.size()):
		for j in range(i + 1, edges.size()):
			var edge1 := edges[i]
			var edge2 := edges[j]
			# Check if walls are perpendicular (dot product = 0)
			if edge1.x * edge2.x + edge1.y * edge2.y == 0:
				# Position pillar at the corner closest to the walls
				# Move toward the walls but stay within the floor tile
				pillar_offset = Vector3(
					edge1.x * cell_size * 0.4 + edge2.x * cell_size * 0.4,
					0,
					edge1.y * cell_size * 0.4 + edge2.y * cell_size * 0.4
				)
				break
		if pillar_offset != Vector3.ZERO:
			break

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.position = Vector3(
		x * cell_size + pillar_offset.x,
		y * wall_height + wall_height * 0.5,
		z * cell_size + pillar_offset.z
	)

	var box_mesh := BoxMesh.new()
	box_mesh.size = Vector3(0.15, wall_height, 0.15)
	mesh_instance.mesh = box_mesh

	var material := StandardMaterial3D.new()
	material.albedo_color = _get_pillar_color(pillar_material)
	mesh_instance.material_override = material

	add_child(mesh_instance)
	var key := "%d,%d,%d" % [x, y, z]
	pillar_instances[key] = mesh_instance

func _create_solid_terrain_grid(y: int) -> void:
	var layer := grid_system.get_layer(y)
	var half_size := terrain_size / 2

	for x in range(-half_size, half_size):
		for z in range(-half_size, half_size):
			var cell := layer.get_cell(x, z)
			if cell.is_solid():
				var mesh_instance := MeshInstance3D.new()
				mesh_instance.position = Vector3(x * cell_size, y * wall_height + wall_height * 0.5, z * cell_size)

				var box_mesh := BoxMesh.new()
				box_mesh.size = Vector3(cell_size, wall_height, cell_size)
				mesh_instance.mesh = box_mesh

				var material := StandardMaterial3D.new()
				material.albedo_color = Color.TAN
				mesh_instance.material_override = material

				add_child(mesh_instance)
				var key := "%d,%d,%d" % [x, y, z]
				solid_terrain_instances[key] = mesh_instance

func clear_instances() -> void:
	for instance in floor_instances.values():
		instance.queue_free()
	for instance in wall_instances.values():
		instance.queue_free()
	for instance in pillar_instances.values():
		instance.queue_free()
	for instance in solid_terrain_instances.values():
		instance.queue_free()

	floor_instances.clear()
	wall_instances.clear()
	pillar_instances.clear()
	solid_terrain_instances.clear()

func _get_floor_color(floor_type: CellData.Floor) -> Color:
	match floor_type:
		CellData.Floor.DIRT:
			return Color.SADDLE_BROWN
		CellData.Floor.STONE:
			return Color.GRAY
		CellData.Floor.CONCRETE:
			return Color.LIGHT_GRAY
		CellData.Floor.METAL:
			return Color.SILVER
		_:
			return Color.WHITE

func _get_wall_color(floor_type: CellData.Floor) -> Color:
	match floor_type:
		CellData.Floor.DIRT:
			return Color.DARK_GOLDENROD
		CellData.Floor.STONE:
			return Color.DIM_GRAY
		CellData.Floor.CONCRETE:
			return Color.GRAY
		CellData.Floor.METAL:
			return Color.DARK_GRAY
		_:
			return Color.WHITE

func _get_pillar_color(floor_type: CellData.Floor) -> Color:
	match floor_type:
		CellData.Floor.STONE:
			return Color.SLATE_GRAY
		CellData.Floor.CONCRETE:
			return Color.LIGHT_GRAY
		CellData.Floor.METAL:
			return Color.SILVER
		_:
			return Color.WHITE

func _create_hover_highlight() -> void:
	hover_highlight = MeshInstance3D.new()
	add_child(hover_highlight)

	# Create a thin flat highlight for top face
	var box_mesh := BoxMesh.new()
	box_mesh.size = Vector3(cell_size * 1.02, 0.05, cell_size * 1.02)
	hover_highlight.mesh = box_mesh

	var material := StandardMaterial3D.new()
	material.flags_unshaded = true
	material.flags_do_not_receive_shadows = true
	material.albedo_color = Color.YELLOW
	material.albedo_color.a = 0.9
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	hover_highlight.material_override = material

	hover_highlight.visible = false

func _on_hover_changed(cell_pos: Vector2i) -> void:
	print("SliceRenderer received hover: ", cell_pos)
	if cell_pos == Vector2i(-999, -999):
		hover_highlight.visible = false
		print("Hiding hover highlight")
	else:
		var y := grid_system.get_active_layer_y()
		var cell := grid_system.get_cell(cell_pos.x, y, cell_pos.y)

		var highlight_y: float
		if cell.is_solid():
			# Highlight on top of unexcavated terrain
			highlight_y = y * wall_height + wall_height + 0.1
		else:
			# Highlight at floor level for excavated areas
			highlight_y = y * wall_height + 0.1

		hover_highlight.position = Vector3(cell_pos.x * cell_size, highlight_y, cell_pos.y * cell_size)
		hover_highlight.visible = true
		print("Showing hover highlight at: ", hover_highlight.position)

func _on_selection_changed(cells: Array[Vector2i]) -> void:
	# Clear existing highlights
	for highlight in selection_highlights:
		highlight.queue_free()
	selection_highlights.clear()

	# Create new highlights
	var y := grid_system.get_active_layer_y()
	for cell in cells:
		if cell == Vector2i(-999, -999):
			continue

		var cell_data := grid_system.get_cell(cell.x, y, cell.y)
		var highlight := MeshInstance3D.new()
		add_child(highlight)

		# Create thin flat highlight
		var box_mesh := BoxMesh.new()
		box_mesh.size = Vector3(cell_size * 0.98, 0.04, cell_size * 0.98)
		highlight.mesh = box_mesh

		var material := StandardMaterial3D.new()
		material.flags_unshaded = true
		material.flags_do_not_receive_shadows = true
		material.albedo_color = Color.CYAN
		material.albedo_color.a = 0.8
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		highlight.material_override = material

		var highlight_y: float
		if cell_data.is_solid():
			# Highlight on top of unexcavated terrain
			highlight_y = y * wall_height + wall_height + 0.08
		else:
			# Highlight at floor level for excavated areas
			highlight_y = y * wall_height + 0.08

		highlight.position = Vector3(cell.x * cell_size, highlight_y, cell.y * cell_size)
		selection_highlights.append(highlight)

func _connect_to_input_controller() -> void:
	var input_controller := get_tree().get_first_node_in_group("input_controller")
	if input_controller:
		print("SliceRenderer: Found input controller, connecting signals")
		input_controller.hover_changed.connect(_on_hover_changed)
		input_controller.selection_changed.connect(_on_selection_changed)
	else:
		print("SliceRenderer: Input controller still not found, retrying...")
		# Try again in the next frame
		call_deferred("_connect_to_input_controller")
