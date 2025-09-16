# Godot 4.4 Best Practices & Standards for Claude

## GDScript Syntax & Style

### Type Annotations
- Always use type annotations for variables, parameters, and return types
- Use explicit typing for better performance and error catching
```gdscript
var health: int = 100
var player_name: String = "Player"
func get_damage(amount: int) -> int:
    return amount * 2
```

### Enum Usage
- Define enums within classes for organization
- Access enums using integer values from outside the class (Godot limitation)
```gdscript
# In TileData class
enum FloorType { NONE, DIRT, STONE, CONCRETE, METAL }

# From outside class - use integers with comments
var floor_type: int = 1  # TileData.FloorType.DIRT
```

### Node References
- Use `@onready` for node references that depend on scene tree
- Use `get_node()` or `$` for reliable node access
```gdscript
@onready var camera: Camera3D = get_viewport().get_camera_3d()
@onready var ui_panel: Panel = $UI/Panel
```

## Common Godot 4.4 Patterns

### Input Handling
- Use `_input()` for global input events
- Use `_unhandled_input()` for input that should be processed after UI
- Check event types properly
```gdscript
func _input(event):
    if event is InputEventMouseButton and event.pressed:
        if event.button_index == MOUSE_BUTTON_LEFT:
            handle_left_click(event.position)
```

### Raycasting
- Use `PhysicsRayQueryParameters3D.create()` for ray queries
- Access world space through viewport
```gdscript
var space_state = get_viewport().get_world_3d().direct_space_state
var query = PhysicsRayQueryParameters3D.create(from, to)
var result = space_state.intersect_ray(query)
```

### Signal Connections
- Use `signal_name.connect(callable)` for signal connections
- Use `bind()` for passing additional parameters
```gdscript
button.pressed.connect(_on_button_pressed.bind(button_id))
```

## Node Architecture

### Control Nodes
- Use Control nodes for UI elements
- Set `mouse_filter = 2` (MOUSE_FILTER_IGNORE) on container controls to allow clicks through
- Use proper anchoring and layout modes for responsive UI

### 3D Scene Structure
- MeshInstance3D for renderable geometry
- Use Node3D for logical grouping and transforms
- StaticBody3D/RigidBody3D for physics interaction

## Data Management

### Tile-Based Systems
- Use `Dictionary` with `Vector2i` keys for grid data storage
- Implement lazy initialization for memory efficiency
```gdscript
var tile_data: Dictionary = {}  # Vector2i -> TileData

func get_tile_data(pos: Vector2i) -> TileData:
    if not tile_data.has(pos):
        tile_data[pos] = TileData.new()
    return tile_data[pos]
```

### Serialization
- Use `to_dict()` and `from_dict()` methods for custom classes
- Use `JSON.stringify()` and `JSON.parse()` for file I/O
- Handle parse errors properly

## Performance Considerations

### Mesh Generation
- Use `ArrayMesh` and `PackedVector3Array` for dynamic geometry
- Batch geometry updates when possible
- Use appropriate primitive types (`PRIMITIVE_LINES`, `PRIMITIVE_TRIANGLES`)

### Material Management
- Reuse materials when possible
- Set material properties once during initialization
- Use `flags_unshaded = true` for UI overlays

## Error Prevention

### File Operations
- Always check if `FileAccess.open()` returns null
- Close files properly with `file.close()`
- Use absolute paths for file operations

### Null Checks
- Check node references before use
- Validate mesh and material references
- Handle empty collections gracefully

### Scene Tree Access
- Don't access child nodes in `_init()`
- Use `_ready()` for scene tree dependent initialization
- Check if nodes exist before accessing them

## Project Organization

### File Structure
- Keep scripts close to their scene files
- Use meaningful file names
- Create separate classes for complex data structures

### Code Comments
- Comment enum value mappings when using integers
- Explain complex algorithms and raycasting logic
- Document public API methods

## Common Pitfalls to Avoid

1. **Enum Access**: Cannot access `ClassName.EnumName.VALUE` from outside class
2. **World Access**: Use `get_viewport().get_world_3d()` not `get_world_3d()` from Control nodes
3. **Node Timing**: Don't access child nodes before `_ready()`
4. **Type Safety**: Always use type annotations for better error detection
5. **Resource Cleanup**: Free unused nodes with `queue_free()`

## Testing & Debugging

### Console Output
- Use descriptive print statements for debugging
- Include relevant data in debug messages
- Remove debug prints in production code

### Scene Testing
- Test node hierarchy in simple scenes first
- Verify input handling with print statements
- Check material and mesh assignments visually

## Memory Management

### Node Lifecycle
- Use `queue_free()` instead of direct deletion
- Clear large dictionaries when no longer needed
- Avoid circular references in custom classes

### Resource Loading
- Cache frequently used resources
- Use resource preloading for critical assets
- Unload unused resources to free memory