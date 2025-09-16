extends Control

@onready var grid_plane: MeshInstance3D = get_node("../MeshInstance3D")
@onready var button_container: VBoxContainer = $Panel/VBoxContainer

var active_floor_type: int = 0  # GridTileData.FloorType.NONE
var active_tool_mode: String = "none"  # "floor" or "excavate" or "none"
var tool_buttons: Array[Button] = []

# Drag selection state
var is_dragging: bool = false
var drag_start_cell: Vector2i = Vector2i(-999, -999)
var drag_current_cell: Vector2i = Vector2i(-999, -999)
var selection_start_pos: Vector2
var selection_size_label: Label

signal floor_type_changed(floor_type: int)
signal tool_mode_changed(mode: String)

func _ready():
	create_floor_type_buttons()
	connect_signals()
	create_selection_size_label()

func create_floor_type_buttons():
	# Add excavation tool first
	var excavate_button = Button.new()
	excavate_button.text = "Excavate"
	excavate_button.toggle_mode = true
	excavate_button.button_group = create_button_group()
	excavate_button.custom_minimum_size = Vector2(80, 30)
	excavate_button.pressed.connect(_on_excavate_button_pressed.bind(excavate_button))
	button_container.add_child(excavate_button)
	tool_buttons.append(excavate_button)

	# Add separator
	var separator = HSeparator.new()
	separator.custom_minimum_size.y = 5
	button_container.add_child(separator)

	# Add floor type buttons
	var floor_types = [
		{"name": "None", "type": 0},  # GridTileData.FloorType.NONE
		{"name": "Dirt", "type": 1},  # GridTileData.FloorType.DIRT
		{"name": "Stone", "type": 2},  # GridTileData.FloorType.STONE
		{"name": "Concrete", "type": 3},  # GridTileData.FloorType.CONCRETE
		{"name": "Metal", "type": 4}  # GridTileData.FloorType.METAL
	]

	for floor_data in floor_types:
		var button = Button.new()
		button.text = floor_data.name
		button.toggle_mode = true
		button.button_group = excavate_button.button_group  # Use same button group
		button.custom_minimum_size = Vector2(80, 30)

		button.pressed.connect(_on_floor_button_pressed.bind(floor_data.type, button))

		button_container.add_child(button)
		tool_buttons.append(button)

func create_button_group() -> ButtonGroup:
	if tool_buttons.is_empty():
		return ButtonGroup.new()
	else:
		return tool_buttons[0].button_group

func connect_signals():
	# Signal connections can be added here if needed in the future
	pass

func _on_excavate_button_pressed(button: Button):
	if button.button_pressed:
		active_tool_mode = "excavate"
		active_floor_type = 0  # GridTileData.FloorType.NONE
		tool_mode_changed.emit("excavate")
		print("Selected excavation tool")
	else:
		active_tool_mode = "none"
		tool_mode_changed.emit("none")

func _on_floor_button_pressed(floor_type: int, button: Button):
	if button.button_pressed:
		active_tool_mode = "floor"
		active_floor_type = floor_type
		floor_type_changed.emit(floor_type)
		tool_mode_changed.emit("floor")
		print("Selected floor type: ", get_floor_type_name(floor_type))
	else:
		active_tool_mode = "none"
		active_floor_type = 0  # GridTileData.FloorType.NONE
		floor_type_changed.emit(0)  # GridTileData.FloorType.NONE
		tool_mode_changed.emit("none")


func get_floor_type_name(floor_type: int) -> String:
	match floor_type:
		0:  # GridTileData.FloorType.NONE
			return "None"
		1:  # GridTileData.FloorType.DIRT
			return "Dirt"
		2:  # GridTileData.FloorType.STONE
			return "Stone"
		3:  # GridTileData.FloorType.CONCRETE
			return "Concrete"
		4:  # GridTileData.FloorType.METAL
			return "Metal"
		_:
			return "Unknown"

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if active_tool_mode != "none" and grid_plane:
				if event.pressed:
					start_drag_selection(event.position)
				else:
					end_drag_selection(event.position)
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			deselect_tool()
	elif event is InputEventMouseMotion and is_dragging:
		update_drag_selection(event.position)

func handle_tile_click(mouse_pos: Vector2):
	var camera = get_viewport().get_camera_3d()
	if not camera:
		return

	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * 1000

	var intersection_point: Vector3
	var found_intersection = false
	var cell_pos: Vector2i

	# Use the same raycasting logic as GridPlane hover detection
	if active_tool_mode == "excavate":
		# Try intersecting with terrain cube tops first
		var terrain_top_plane = Plane(Vector3.UP, 1.0)
		var terrain_intersection = terrain_top_plane.intersects_ray(from, to - from)

		if terrain_intersection:
			intersection_point = terrain_intersection
			cell_pos = grid_plane.get_tile_at_world_pos(intersection_point)

			if cell_pos != Vector2i(-999, -999):
				var tile_data = grid_plane.get_tile_data(cell_pos)
				# Only register click if there's actually a terrain cube at this position
				if not tile_data.is_excavated():
					found_intersection = true

	# If not excavation mode or no terrain cube hit, use ground plane
	if not found_intersection:
		var plane = Plane(Vector3.UP, grid_plane.global_position.y)
		var intersection = plane.intersects_ray(from, to - from)
		if intersection:
			intersection_point = intersection
			cell_pos = grid_plane.get_tile_at_world_pos(intersection_point)
			if cell_pos != Vector2i(-999, -999):
				found_intersection = true

	# Handle the click based on tool mode
	if found_intersection and cell_pos != Vector2i(-999, -999):
		if active_tool_mode == "excavate":
			var tile_data = grid_plane.get_tile_data(cell_pos)
			if not tile_data.is_excavated():
				grid_plane.excavate_tile(cell_pos)
				print("Excavated tile at ", cell_pos)
			else:
				print("Tile at ", cell_pos, " is already excavated")
		elif active_tool_mode == "floor":
			var tile_data = grid_plane.get_tile_data(cell_pos)
			if tile_data.can_place_floor():
				grid_plane.set_floor_type(cell_pos, active_floor_type)
				print("Set floor type at ", cell_pos, " to ", get_floor_type_name(active_floor_type))
			else:
				print("Cannot place floor at ", cell_pos, " - tile not excavated")

func create_selection_size_label():
	selection_size_label = Label.new()
	selection_size_label.text = ""
	selection_size_label.add_theme_color_override("font_color", Color.WHITE)
	selection_size_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	selection_size_label.add_theme_constant_override("shadow_offset_x", 2)
	selection_size_label.add_theme_constant_override("shadow_offset_y", 2)
	selection_size_label.visible = false
	add_child(selection_size_label)

func start_drag_selection(mouse_pos: Vector2):
	selection_start_pos = mouse_pos
	var cell_pos = get_cell_from_mouse_pos(mouse_pos)
	if cell_pos != Vector2i(-999, -999):
		is_dragging = true
		drag_start_cell = cell_pos
		drag_current_cell = cell_pos
		update_selection_display()

func update_drag_selection(mouse_pos: Vector2):
	if not is_dragging:
		return

	var cell_pos = get_cell_from_mouse_pos(mouse_pos)
	if cell_pos != Vector2i(-999, -999) and cell_pos != drag_current_cell:
		drag_current_cell = cell_pos
		update_selection_display()

	# Update label position to follow cursor
	selection_size_label.position = mouse_pos + Vector2(10, -20)

func end_drag_selection(mouse_pos: Vector2):
	if not is_dragging:
		# Single click - handle as before
		handle_tile_click(mouse_pos)
		return

	is_dragging = false
	selection_size_label.visible = false

	# Apply tool to entire selection
	apply_tool_to_selection()

	# Clear selection in GridPlane
	if grid_plane.has_method("clear_selection_highlight"):
		grid_plane.clear_selection_highlight()

func get_cell_from_mouse_pos(mouse_pos: Vector2) -> Vector2i:
	var camera = get_viewport().get_camera_3d()
	if not camera:
		return Vector2i(-999, -999)

	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * 1000

	var intersection_point: Vector3
	var found_intersection = false

	# Use same raycasting logic as single clicks
	if active_tool_mode == "excavate":
		var terrain_top_plane = Plane(Vector3.UP, 1.0)
		var terrain_intersection = terrain_top_plane.intersects_ray(from, to - from)
		if terrain_intersection:
			intersection_point = terrain_intersection
			var cell_pos = grid_plane.get_tile_at_world_pos(intersection_point)
			if cell_pos != Vector2i(-999, -999):
				var tile_data = grid_plane.get_tile_data(cell_pos)
				if not tile_data.is_excavated():
					found_intersection = true

	if not found_intersection:
		var plane = Plane(Vector3.UP, grid_plane.global_position.y)
		var intersection = plane.intersects_ray(from, to - from)
		if intersection:
			intersection_point = intersection
			found_intersection = true

	if found_intersection:
		return grid_plane.get_tile_at_world_pos(intersection_point)

	return Vector2i(-999, -999)

func update_selection_display():
	if not is_dragging:
		return

	# Calculate selection bounds
	var min_x = min(drag_start_cell.x, drag_current_cell.x)
	var max_x = max(drag_start_cell.x, drag_current_cell.x)
	var min_z = min(drag_start_cell.y, drag_current_cell.y)
	var max_z = max(drag_start_cell.y, drag_current_cell.y)

	var width = max_x - min_x + 1
	var height = max_z - min_z + 1

	# Update size label
	selection_size_label.text = str(width) + "x" + str(height)
	selection_size_label.visible = true

	# Update GridPlane selection highlight
	if grid_plane.has_method("set_selection_highlight"):
		grid_plane.set_selection_highlight(Vector2i(min_x, min_z), Vector2i(max_x, max_z), active_tool_mode)

func apply_tool_to_selection():
	var min_x = min(drag_start_cell.x, drag_current_cell.x)
	var max_x = max(drag_start_cell.x, drag_current_cell.x)
	var min_z = min(drag_start_cell.y, drag_current_cell.y)
	var max_z = max(drag_start_cell.y, drag_current_cell.y)

	for x in range(min_x, max_x + 1):
		for z in range(min_z, max_z + 1):
			var cell_pos = Vector2i(x, z)
			if active_tool_mode == "excavate":
				var tile_data = grid_plane.get_tile_data(cell_pos)
				if not tile_data.is_excavated():
					grid_plane.excavate_tile(cell_pos)
			elif active_tool_mode == "floor":
				var tile_data = grid_plane.get_tile_data(cell_pos)
				if tile_data.can_place_floor():
					grid_plane.set_floor_type(cell_pos, active_floor_type)

	var width = max_x - min_x + 1
	var height = max_z - min_z + 1
	print("Applied ", active_tool_mode, " to ", width, "x", height, " selection")

func deselect_tool():
	active_tool_mode = "none"
	active_floor_type = 0  # GridTileData.FloorType.NONE
	is_dragging = false
	selection_size_label.visible = false
	for button in tool_buttons:
		button.button_pressed = false
	floor_type_changed.emit(0)  # GridTileData.FloorType.NONE
	tool_mode_changed.emit("none")

	# Clear any selection highlight
	if grid_plane and grid_plane.has_method("clear_selection_highlight"):
		grid_plane.clear_selection_highlight()

	print("Tool deselected")
