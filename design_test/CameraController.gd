class_name CameraController
extends Node3D

@export var camera: Camera3D
@export var pan_speed: float = 5.0
@export var rotation_speed: float = 2.0
@export var zoom_speed: float = 2.0
@export var zoom_smoothing: float = 10.0
@export var min_zoom_distance: float = 2.0
@export var max_zoom_distance: float = 50.0
@export var pan_smoothing: float = 8.0
@export var rotation_smoothing: float = 6.0

var target_position: Vector3
var target_rotation_y: float = 0.0
var target_zoom_distance: float = 10.0
var current_zoom_distance: float = 10.0

var is_mouse_captured: bool = false
var mouse_sensitivity: float = 0.002

func _ready() -> void:
	if not camera:
		camera = get_node_or_null("Camera3D")
		if not camera:
			camera = Camera3D.new()
			add_child(camera)

	target_position = global_position
	target_rotation_y = rotation.y
	target_zoom_distance = current_zoom_distance

	_update_camera_position()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		_handle_mouse_button(event)
	elif event is InputEventMouseMotion and is_mouse_captured:
		_handle_mouse_motion(event)
	elif event.is_action_pressed("ui_cancel"):
		_release_mouse()

func _handle_mouse_button(event: InputEventMouseButton) -> void:
	if event.button_index == MOUSE_BUTTON_WHEEL_UP:
		_zoom_in()
	elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		_zoom_out()
	elif event.button_index == MOUSE_BUTTON_MIDDLE:
		if event.pressed:
			_capture_mouse()
		else:
			_release_mouse()

func _handle_mouse_motion(event: InputEventMouseMotion) -> void:
	if is_mouse_captured:
		target_rotation_y -= event.relative.x * mouse_sensitivity

func _process(delta: float) -> void:
	_handle_keyboard_input(delta)
	_smooth_camera_movement(delta)

func _handle_keyboard_input(delta: float) -> void:
	var input_vector := Vector2.ZERO

	# Use WASD keys directly
	if Input.is_key_pressed(KEY_A):
		input_vector.x -= 1.0
	if Input.is_key_pressed(KEY_D):
		input_vector.x += 1.0
	if Input.is_key_pressed(KEY_W):
		input_vector.y -= 1.0
	if Input.is_key_pressed(KEY_S):
		input_vector.y += 1.0

	# Also support arrow keys via UI actions
	if Input.is_action_pressed("ui_left"):
		input_vector.x -= 1.0
	if Input.is_action_pressed("ui_right"):
		input_vector.x += 1.0
	if Input.is_action_pressed("ui_up"):
		input_vector.y -= 1.0
	if Input.is_action_pressed("ui_down"):
		input_vector.y += 1.0

	if Input.is_key_pressed(KEY_Q):
		target_rotation_y += rotation_speed * delta
	if Input.is_key_pressed(KEY_E):
		target_rotation_y -= rotation_speed * delta

	if input_vector.length() > 0:
		input_vector = input_vector.normalized()
		var movement := Vector3(input_vector.x, 0, input_vector.y) * pan_speed * delta
		movement = movement.rotated(Vector3.UP, target_rotation_y)
		target_position += movement

func _smooth_camera_movement(delta: float) -> void:
	global_position = global_position.lerp(target_position, pan_smoothing * delta)

	var current_rotation_y: float = rotation.y
	var rotation_diff: float = _angle_difference(target_rotation_y, current_rotation_y)
	current_rotation_y += rotation_diff * rotation_smoothing * delta
	rotation.y = current_rotation_y

	current_zoom_distance = lerp(current_zoom_distance, target_zoom_distance, zoom_smoothing * delta)
	current_zoom_distance = clampf(current_zoom_distance, min_zoom_distance, max_zoom_distance)

	_update_camera_position()

func _update_camera_position() -> void:
	if camera:
		camera.position = Vector3(0, current_zoom_distance * 0.7, current_zoom_distance)
		camera.look_at(global_position, Vector3.UP)

func _zoom_in() -> void:
	target_zoom_distance = maxf(target_zoom_distance - zoom_speed, min_zoom_distance)

func _zoom_out() -> void:
	target_zoom_distance = minf(target_zoom_distance + zoom_speed, max_zoom_distance)

func _capture_mouse() -> void:
	is_mouse_captured = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _release_mouse() -> void:
	is_mouse_captured = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _angle_difference(target: float, current: float) -> float:
	var diff: float = target - current
	while diff > PI:
		diff -= TAU
	while diff < -PI:
		diff += TAU
	return diff

func set_target_position(pos: Vector3) -> void:
	target_position = pos

func set_target_rotation(rot_y: float) -> void:
	target_rotation_y = rot_y

func set_zoom_distance(distance: float) -> void:
	target_zoom_distance = clampf(distance, min_zoom_distance, max_zoom_distance)

func get_camera() -> Camera3D:
	return camera
