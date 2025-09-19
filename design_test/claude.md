# Godot 4 GDScript Best Practices

## Code Style and Formatting

### Naming Conventions
- **Variables and functions**: `snake_case`
- **Constants**: `SCREAMING_SNAKE_CASE`
- **Classes**: `PascalCase`
- **Signals**: `snake_case` (past tense verbs preferred)
- **Private members**: prefix with underscore `_private_var`

### File Organization
```gdscript
# Class declaration at top
class_name PlayerController
extends CharacterBody3D

# Signals
signal health_changed(new_health: int)
signal died

# Enums
enum State { IDLE, WALKING, RUNNING, JUMPING }

# Constants
const MAX_HEALTH: int = 100
const JUMP_VELOCITY: float = 4.5

# Exported variables
@export var speed: float = 5.0
@export_group("Combat")
@export var damage: int = 10

# Public variables
var current_state: State = State.IDLE

# Private variables
var _health: int = MAX_HEALTH
var _is_invulnerable: bool = false
```

## Node References and Onready

### Use @onready for node references
```gdscript
@onready var health_bar: ProgressBar = $UI/HealthBar
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
```

### Group related @onready variables
```gdscript
# UI nodes
@onready var health_bar: ProgressBar = $UI/HealthBar
@onready var mana_bar: ProgressBar = $UI/ManaBar

# Audio nodes
@onready var audio_player: AudioStreamPlayer = $AudioPlayer
@onready var footstep_audio: AudioStreamPlayer = $FootstepAudio
```

## Input Handling

### Use Input.get_vector() for movement
```gdscript
func _physics_process(delta: float) -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_dir != Vector2.ZERO:
		velocity.x = input_dir.x * speed
		velocity.z = input_dir.y * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
```

### Handle input events properly
```gdscript
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("jump") and is_on_floor():
		jump()
		get_viewport().set_input_as_handled()
```

## Physics and Movement

### Use CharacterBody3D for player movement
```gdscript
func _physics_process(delta: float) -> void:
	# Add gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get input direction
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	move_and_slide()
```

## Signal Best Practices

### Declare signals at the top
```gdscript
signal health_changed(new_health: int)
signal inventory_updated(item: Resource, quantity: int)
signal player_died
```

### Connect signals in code
```gdscript
func _ready() -> void:
	health_changed.connect(_on_health_changed)
	player.died.connect(_on_player_died)
```

### Use proper signal naming
```gdscript
# Good - describes what happened
signal door_opened
signal item_collected(item: Item)
signal health_depleted

# Avoid - describes what will happen
signal open_door
signal collect_item
```

## Resource Management

### Use typed resources
```gdscript
class_name Item
extends Resource

@export var name: String
@export var icon: Texture2D
@export var value: int
@export var stack_size: int = 1
```

### Preload resources
```gdscript
const PlayerScene := preload("res://player/Player.tscn")
const ExplosionEffect := preload("res://effects/Explosion.tscn")
```

## Error Handling and Validation

### Validate parameters and state
```gdscript
func take_damage(amount: int) -> void:
	if amount <= 0:
		push_warning("Damage amount must be positive")
		return

	if _is_invulnerable:
		return

	_health = max(0, _health - amount)
	health_changed.emit(_health)

	if _health <= 0:
		die()
```

### Use assert for debugging
```gdscript
func _ready() -> void:
	assert(health_bar != null, "HealthBar node not found")
	assert(MAX_HEALTH > 0, "MAX_HEALTH must be positive")
```

## Performance Optimization

### Cache frequently accessed nodes
```gdscript
var _cached_player: Player
var _cached_camera: Camera3D

func get_player() -> Player:
	if not _cached_player:
		_cached_player = get_tree().get_first_node_in_group("player")
	return _cached_player
```

### Use object pooling for frequent spawning
```gdscript
var _bullet_pool: Array[Bullet] = []

func spawn_bullet() -> Bullet:
	var bullet: Bullet
	if _bullet_pool.is_empty():
		bullet = BulletScene.instantiate()
	else:
		bullet = _bullet_pool.pop_back()

	add_child(bullet)
	return bullet

func return_bullet_to_pool(bullet: Bullet) -> void:
	bullet.get_parent().remove_child(bullet)
	_bullet_pool.push_back(bullet)
```

## State Management

### Use enums for states
```gdscript
enum PlayerState { IDLE, WALKING, RUNNING, JUMPING, FALLING, ATTACKING }

var current_state: PlayerState = PlayerState.IDLE

func change_state(new_state: PlayerState) -> void:
	if current_state == new_state:
		return

	_exit_state(current_state)
	current_state = new_state
	_enter_state(current_state)
```

### Implement state machines cleanly
```gdscript
func _enter_state(state: PlayerState) -> void:
	match state:
		PlayerState.IDLE:
			animation_player.play("idle")
		PlayerState.WALKING:
			animation_player.play("walk")
		PlayerState.ATTACKING:
			animation_player.play("attack")
			_is_attacking = true

func _exit_state(state: PlayerState) -> void:
	match state:
		PlayerState.ATTACKING:
			_is_attacking = false
```

## Scene Organization

### Use clear node hierarchy
```
Player (CharacterBody3D)
├── MeshInstance3D
├── CollisionShape3D
├── AnimationPlayer
├── UI (CanvasLayer)
│   ├── HealthBar (ProgressBar)
│   └── Inventory (Control)
└── Audio (Node)
    ├── FootstepPlayer (AudioStreamPlayer)
    └── VoicePlayer (AudioStreamPlayer)
```

### Use groups for easy node finding
```gdscript
func _ready() -> void:
	add_to_group("player")
	add_to_group("damageable")

# Later, find all damageable entities
var damageable_entities = get_tree().get_nodes_in_group("damageable")
```

## Common Anti-patterns to Avoid

### Don't use get_node() repeatedly
```gdscript
# Bad
func _process(delta: float) -> void:
	get_node("HealthBar").value = health
	get_node("ManaBar").value = mana

# Good
@onready var health_bar: ProgressBar = $HealthBar
@onready var mana_bar: ProgressBar = $ManaBar

func _process(delta: float) -> void:
	health_bar.value = health
	mana_bar.value = mana
```

### Don't modify position/rotation directly in _process
```gdscript
# Bad - causes jittery movement
func _process(delta: float) -> void:
	position += velocity * delta

# Good - use _physics_process for physics
func _physics_process(delta: float) -> void:
	velocity += acceleration * delta
	move_and_slide()
```

### Don't hardcode node paths
```gdscript
# Bad
var player = get_node("/root/Main/Player")

# Good
var player = get_tree().get_first_node_in_group("player")
# or use proper scene organization and relative paths
```

## Documentation and Comments

### Document public APIs
```gdscript
## Applies damage to this entity
## @param amount: The amount of damage to apply
## @param damage_type: The type of damage (optional)
func take_damage(amount: int, damage_type: DamageType = DamageType.PHYSICAL) -> void:
	pass
```

### Use type hints consistently
```gdscript
func calculate_distance(from: Vector3, to: Vector3) -> float:
	return from.distance_to(to)

func get_items_by_type(item_type: Item.Type) -> Array[Item]:
	return items.filter(func(item: Item) -> bool: return item.type == item_type)
```