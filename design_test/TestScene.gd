extends Node3D

@onready var grid_system: GridSystem = GridSystem.new()
@onready var slice_renderer: SliceRenderer = SliceRenderer.new()
@onready var camera: Camera3D = Camera3D.new()

func _ready() -> void:
	add_child(grid_system)
	add_child(slice_renderer)
	add_child(camera)

	camera.position = Vector3(0, 5, 5)
	camera.look_at(Vector3.ZERO, Vector3.UP)

	_run_tests()

func _run_tests() -> void:
	print("Starting Phase 1 tests...")

	_test_single_cell_excavation()
	await get_tree().create_timer(2.0).timeout

	_test_strip_excavation()
	await get_tree().create_timer(2.0).timeout

	print("Phase 1 tests completed!")

func _test_single_cell_excavation() -> void:
	print("Test: Excavate 1x1 -> Dirt floor + walls")

	var points: Array[Vector2i] = [Vector2i(0, 0)]
	grid_system.excavate(points)

	await get_tree().process_frame

	var cell := grid_system.get_cell(0, 0, 0)
	assert(cell.terrain == CellData.Terrain.EXCAVATED, "Cell should be excavated")
	assert(cell.floor == CellData.Floor.DIRT, "Cell should have dirt floor")

	var edges := AutoGeo.get_wall_edges(grid_system, 0, 0, 0)
	assert(edges.size() == 4, "Should have 4 walls around isolated cell")

	print("✓ Single cell excavation test passed")

func _test_strip_excavation() -> void:
	print("Test: Excavate strip -> parallel Dirt walls appear")

	grid_system.set_active_layer(1)

	var points: Array[Vector2i] = [
		Vector2i(0, 0),
		Vector2i(1, 0),
		Vector2i(2, 0)
	]
	grid_system.excavate(points)

	await get_tree().process_frame

	for point in points:
		var cell := grid_system.get_cell(point.x, 1, point.y)
		assert(cell.terrain == CellData.Terrain.EXCAVATED, "Cell should be excavated")
		assert(cell.floor == CellData.Floor.DIRT, "Cell should have dirt floor")

	var edges_middle := AutoGeo.get_wall_edges(grid_system, 1, 1, 0)
	assert(edges_middle.size() == 2, "Middle cell should have 2 walls (north and south)")

	print("✓ Strip excavation test passed")