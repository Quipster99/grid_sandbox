extends Node3D

@export var pan_speed: float = 10.0
@export var rotation_speed: float = 2.0
@export var zoom_speed: float = 2.0
@export var min_zoom: float = 5.0
@export var max_zoom: float = 50.0

@onready var camera: Camera3D = $Camera3D
var current_zoom: float = 20.0

func _ready():
	if not camera:
		camera = Camera3D.new()
		add_child(camera)

	position_camera()

func position_camera():
	camera.position = Vector3(0, current_zoom, current_zoom * 0.7)
	camera.look_at(Vector3.ZERO, Vector3.UP)

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_in()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_out()

func _process(delta):
	handle_movement(delta)
	handle_rotation(delta)

func handle_movement(delta):
	var input_vector = Vector2.ZERO

	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		input_vector.y -= 1
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		input_vector.y += 1
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		input_vector.x -= 1
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		input_vector.x += 1

	if input_vector != Vector2.ZERO:
		var forward = -transform.basis.z
		var right = transform.basis.x

		forward.y = 0
		right.y = 0
		forward = forward.normalized()
		right = right.normalized()

		var movement = (forward * input_vector.y + right * input_vector.x) * pan_speed * delta
		global_position += movement

func handle_rotation(delta):
	var rotation_input = 0.0

	if Input.is_key_pressed(KEY_Q):
		rotation_input -= 1
	if Input.is_key_pressed(KEY_E):
		rotation_input += 1

	if rotation_input != 0:
		rotate_y(rotation_input * rotation_speed * delta)

func zoom_in():
	current_zoom = max(current_zoom - zoom_speed, min_zoom)
	update_camera_position()

func zoom_out():
	current_zoom = min(current_zoom + zoom_speed, max_zoom)
	update_camera_position()

func update_camera_position():
	var current_rotation = rotation.y
	camera.position = Vector3(0, current_zoom, current_zoom * 0.7)
	camera.look_at(Vector3.ZERO, Vector3.UP)