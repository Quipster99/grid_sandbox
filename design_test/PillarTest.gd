extends Node3D

@onready var grid_system: GridSystem = GridSystem.new()

func _ready() -> void:
	add_child(grid_system)

	print("=== PILLAR TEST ===")

	# Test simple corner scenario
	print("\n1. Testing corner excavation...")
	var excavate_points: Array[Vector2i] = [
		Vector2i(0, 0),  # corner
		Vector2i(1, 0),  # east
		Vector2i(0, 1)   # south
	]
	grid_system.excavate(excavate_points)

	print("After excavation:")
	for point in excavate_points:
		var cell := grid_system.get_cell(point.x, 0, point.y)
		print("  Cell ", point, ": terrain=", cell.terrain, " floor=", cell.floor)

	print("\n2. Testing wall edges at corner...")
	var edges := AutoGeo.get_wall_edges(grid_system, 0, 0, 0)
	print("  Walls at (0,0):", edges.size(), " edges:", edges)

	print("\n3. Testing pillar requirements BEFORE stone floor...")
	var has_pillar_before := AutoGeo.corner_has_pillar(grid_system, 0, 0, 0)
	print("  Has pillar before stone floor:", has_pillar_before)

	print("\n4. Adding stone floor to corner...")
	grid_system.build_floor([Vector2i(0, 0)], CellData.Floor.STONE)

	var corner_cell := grid_system.get_cell(0, 0, 0)
	print("  Corner cell after stone floor: terrain=", corner_cell.terrain, " floor=", corner_cell.floor)

	print("\n5. Testing pillar requirements AFTER stone floor...")
	var has_pillar_after := AutoGeo.corner_has_pillar(grid_system, 0, 0, 0)
	print("  Has pillar after stone floor:", has_pillar_after)

	print("\n6. Testing wall edges after stone floor...")
	var edges_after := AutoGeo.get_wall_edges(grid_system, 0, 0, 0)
	print("  Walls at (0,0) after stone:", edges_after.size(), " edges:", edges_after)

	print("\n=== PILLAR TEST COMPLETE ===")

	# Wait then quit
	await get_tree().create_timer(1.0).timeout
	get_tree().quit()