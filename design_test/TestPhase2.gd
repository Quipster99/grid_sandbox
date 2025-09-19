extends Node3D

@onready var grid_system: GridSystem = GridSystem.new()
@onready var slice_renderer: SliceRenderer = SliceRenderer.new()
@onready var camera: Camera3D = Camera3D.new()

func _ready() -> void:
	add_child(grid_system)
	add_child(slice_renderer)
	add_child(camera)

	camera.position = Vector3(0, 8, 8)
	camera.look_at(Vector3.ZERO, Vector3.UP)

	_run_phase2_tests()

func _run_phase2_tests() -> void:
	print("Starting Phase 2 tests...")

	_test_corner_pillars()
	await get_tree().create_timer(3.0).timeout

	_test_floor_removal_downgrade()
	await get_tree().create_timer(3.0).timeout

	print("Phase 2 tests completed!")

func _test_corner_pillars() -> void:
	print("Test: Stone floors in corner → pillars appear")

	var excavate_points: Array[Vector2i] = [
		Vector2i(0, 0),
		Vector2i(1, 0),
		Vector2i(0, 1)
	]
	grid_system.excavate(excavate_points)

	await get_tree().process_frame

	var floor_points: Array[Vector2i] = [Vector2i(0, 0)]
	grid_system.build_floor(floor_points, CellData.Floor.STONE)

	await get_tree().process_frame

	var has_pillar := AutoGeo.corner_has_pillar(grid_system, 0, 0, 0)
	assert(has_pillar, "Should have pillar at corner with Stone floor")

	var pillar_material := AutoGeo.get_pillar_material(grid_system, 0, 0, 0)
	assert(pillar_material == CellData.Floor.STONE, "Pillar should be Stone material")

	print("✓ Corner pillar test passed")

func _test_floor_removal_downgrade() -> void:
	print("Test: Remove floor → pillar disappears, walls downgrade")

	grid_system.set_active_layer(1)

	var excavate_points: Array[Vector2i] = [
		Vector2i(0, 0),
		Vector2i(1, 0),
		Vector2i(0, 1)
	]
	grid_system.excavate(excavate_points)

	await get_tree().process_frame

	var floor_points: Array[Vector2i] = [Vector2i(0, 0)]
	grid_system.build_floor(floor_points, CellData.Floor.CONCRETE)

	await get_tree().process_frame

	var has_pillar_before := AutoGeo.corner_has_pillar(grid_system, 0, 1, 0)
	assert(has_pillar_before, "Should have pillar before removal")

	grid_system.remove_floor(floor_points)

	await get_tree().process_frame

	var has_pillar_after := AutoGeo.corner_has_pillar(grid_system, 0, 1, 0)
	assert(not has_pillar_after, "Should not have pillar after floor removal")

	var wall_material := AutoGeo.get_wall_material(grid_system, 0, 1, 0)
	assert(wall_material == CellData.Floor.NONE, "Wall should be removed after floor removal")

	print("✓ Floor removal downgrade test passed")