extends Node3D
class_name TerrainBlock

@onready var wall_north: MeshInstance3D = $WallCladding/WallNorth
@onready var wall_south: MeshInstance3D = $WallCladding/WallSouth
@onready var wall_east: MeshInstance3D = $WallCladding/WallEast
@onready var wall_west: MeshInstance3D = $WallCladding/WallWest
@onready var terrain_cube: MeshInstance3D = $terrain_cube

# Individual wall face visibility controls
@export var show_north_wall: bool = false : set = set_north_wall_visible
@export var show_south_wall: bool = false : set = set_south_wall_visible
@export var show_east_wall: bool = false : set = set_east_wall_visible
@export var show_west_wall: bool = false : set = set_west_wall_visible

# Wall materials for different types
var wall_materials: Dictionary = {}

func _ready():
	setup_wall_materials()
	update_wall_visibility()

func setup_wall_materials():
	# Create materials for different wall types
	# DIRT wall material (default gray)
	var dirt_material = StandardMaterial3D.new()
	dirt_material.albedo_color = Color(0.4, 0.4, 0.4, 1)
	wall_materials[GridTileData.WallType.DIRT] = dirt_material

	# STONE wall material (lighter gray)
	var stone_material = StandardMaterial3D.new()
	stone_material.albedo_color = Color(0.6, 0.6, 0.6, 1)
	wall_materials[GridTileData.WallType.STONE] = stone_material

	# REINFORCED wall material (metallic)
	var reinforced_material = StandardMaterial3D.new()
	reinforced_material.albedo_color = Color(0.3, 0.3, 0.4, 1)
	reinforced_material.metallic = 0.8
	reinforced_material.roughness = 0.2
	wall_materials[GridTileData.WallType.REINFORCED] = reinforced_material

func set_north_wall_visible(value: bool):
	show_north_wall = value
	if wall_north:
		wall_north.visible = value

func set_south_wall_visible(value: bool):
	show_south_wall = value
	if wall_south:
		wall_south.visible = value

func set_east_wall_visible(value: bool):
	show_east_wall = value
	if wall_east:
		wall_east.visible = value

func set_west_wall_visible(value: bool):
	show_west_wall = value
	if wall_west:
		wall_west.visible = value

func update_wall_visibility():
	if wall_north:
		wall_north.visible = show_north_wall
	if wall_south:
		wall_south.visible = show_south_wall
	if wall_east:
		wall_east.visible = show_east_wall
	if wall_west:
		wall_west.visible = show_west_wall

func set_wall_visibility(north: bool, south: bool, east: bool, west: bool):
	show_north_wall = north
	show_south_wall = south
	show_east_wall = east
	show_west_wall = west
	update_wall_visibility()

func set_wall_material(face: String, wall_type: int):
	var material = wall_materials.get(wall_type, wall_materials[GridTileData.WallType.DIRT])

	match face.to_lower():
		"north", "n":
			if wall_north:
				wall_north.material_override = material
		"south", "s":
			if wall_south:
				wall_south.material_override = material
		"east", "e":
			if wall_east:
				wall_east.material_override = material
		"west", "w":
			if wall_west:
				wall_west.material_override = material

func configure_from_tile_data(tile_data: GridTileData):
	# Configure wall visibility based on wall types (NONE = hidden)
	var north_visible = tile_data.wall_north != GridTileData.WallType.NONE
	var south_visible = tile_data.wall_south != GridTileData.WallType.NONE
	var east_visible = tile_data.wall_east != GridTileData.WallType.NONE
	var west_visible = tile_data.wall_west != GridTileData.WallType.NONE

	set_wall_visibility(north_visible, south_visible, east_visible, west_visible)

	# Set materials for each wall face
	if north_visible:
		set_wall_material("north", tile_data.wall_north)
	if south_visible:
		set_wall_material("south", tile_data.wall_south)
	if east_visible:
		set_wall_material("east", tile_data.wall_east)
	if west_visible:
		set_wall_material("west", tile_data.wall_west)

func toggle_wall_face(face: String):
	match face.to_lower():
		"north", "n":
			set_north_wall_visible(!show_north_wall)
		"south", "s":
			set_south_wall_visible(!show_south_wall)
		"east", "e":
			set_east_wall_visible(!show_east_wall)
		"west", "w":
			set_west_wall_visible(!show_west_wall)

func get_wall_visibility(face: String) -> bool:
	match face.to_lower():
		"north", "n":
			return show_north_wall
		"south", "s":
			return show_south_wall
		"east", "e":
			return show_east_wall
		"west", "w":
			return show_west_wall
		_:
			return false