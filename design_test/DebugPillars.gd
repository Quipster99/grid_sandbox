extends Node3D

@onready var grid_system: GridSystem = GridSystem.new()

func _ready() -> void:
	add_child(grid_system)

	print("=== DETAILED PILLAR DEBUG ===")

	# Create a simple L-shape corner
	print("\n1. Creating L-shape excavation...")
	var excavate_points: Array[Vector2i] = [
		Vector2i(0, 0),  # corner
		Vector2i(1, 0),  # east
		Vector2i(0, 1)   # south
	]
	grid_system.excavate(excavate_points)

	print("Excavated cells:")
	for point in excavate_points:
		var cell := grid_system.get_cell(point.x, 0, point.y)
		print("  ", point, ": terrain=", CellData.Terrain.keys()[cell.terrain], " floor=", CellData.Floor.keys()[cell.floor])

	print("\n2. Checking wall edges at corner...")
	var edges := AutoGeo.get_wall_edges(grid_system, 0, 0, 0)
	print("Wall edges at (0,0): ", edges.size(), " edges")
	for edge in edges:
		print("  Edge direction: ", edge)

	print("\n3. Checking perpendicular walls...")
	var has_perp := AutoGeo._has_perpendicular_walls(edges)
	print("Has perpendicular walls: ", has_perp)

	print("\n4. Checking pillar BEFORE stone floor...")
	var has_pillar_before := AutoGeo.corner_has_pillar(grid_system, 0, 0, 0)
	print("Has pillar before stone: ", has_pillar_before)

	print("\n5. Adding stone floor to corner...")
	grid_system.build_floor([Vector2i(0, 0)], CellData.Floor.STONE)

	var corner_cell := grid_system.get_cell(0, 0, 0)
	print("Corner cell after stone: terrain=", CellData.Terrain.keys()[corner_cell.terrain], " floor=", CellData.Floor.keys()[corner_cell.floor])

	print("\n6. Checking pillar AFTER stone floor...")
	var has_pillar_after := AutoGeo.corner_has_pillar(grid_system, 0, 0, 0)
	print("Has pillar after stone: ", has_pillar_after)

	print("\n7. Checking pillar material...")
	if has_pillar_after:
		var pillar_material := AutoGeo.get_pillar_material(grid_system, 0, 0, 0)
		print("Pillar material: ", CellData.Floor.keys()[pillar_material])

	print("\n=== DEBUG COMPLETE ===")

	await get_tree().create_timer(1.0).timeout
	get_tree().quit()