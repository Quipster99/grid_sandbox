extends Node3D

@onready var grid_system: GridSystem = GridSystem.new()
@onready var slice_renderer: SliceRenderer = SliceRenderer.new()
@onready var input_controller: InputController = InputController.new()
@onready var camera_controller: CameraController = $CameraController

func _ready() -> void:
	add_child(grid_system)
	add_child(slice_renderer)
	add_child(input_controller)

	camera_controller.set_zoom_distance(15.0)

	input_controller.grid_system = grid_system
	input_controller.camera = camera_controller.get_camera()

	# Connect to layer changes to move camera
	grid_system.layer_rebuilt.connect(_on_layer_changed)

	_show_instructions()

func _on_layer_changed(layer_y: int) -> void:
	var target_y := layer_y * 3.0  # wall_height
	var current_pos := camera_controller.position
	camera_controller.set_target_position(Vector3(current_pos.x, target_y, current_pos.z))

func _show_instructions() -> void:
	print("=== Phase 1 Excavation System ===")
	print("Camera Controls:")
	print("  WASD - Pan camera")
	print("  Q/E - Rotate camera")
	print("  Mouse wheel - Zoom in/out")
	print("  Middle mouse - Free look (hold)")
	print("  ESC - Release mouse")
	print("")
	print("Excavation Tools:")
	print("  1 - Excavate tool")
	print("  2 - Stone floor tool")
	print("  3 - Concrete floor tool")
	print("  4 - Metal floor tool")
	print("  5 - Remove floor tool")
	print("  Z/X - Layer up/down")
	print("  Left mouse - Click/drag to select area")
	print("")
	print("✅ Phase 1, 2 & 3 Features implemented:")
	print("  - Grid data model with terrain + floor")
	print("  - Excavation → Dirt floors")
	print("  - Auto walls on Dirt floors")
	print("  - Floor building (Stone/Concrete/Metal)")
	print("  - Wall material upgrades based on strongest adjacent floor")
	print("  - Auto pillars at perpendicular wall corners with Built floors")
	print("  - Floor removal with wall/pillar downgrades")
	print("  - Working multi-layer system (Z/X to switch layers)")
	print("  - Robust camera controls")
	print("  - Smart visual highlights")
	print("")
	print("Ready to excavate!")