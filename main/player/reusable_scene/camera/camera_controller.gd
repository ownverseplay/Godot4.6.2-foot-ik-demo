extends SpringArm3D

@export var mouse_sensitivity: float = 0.002
@export var min_camera_limit_x: float = -1.0
@export var max_camera_limit_x: float = 1.0

@export var horizontal_acceleration: float = 2.0
@export var vertical_acceleration: float = 1.0

@export var zoom_speed: float = 0.5
@export var min_zoom: float = 0.7
@export var max_zoom: float = 3.0

# --- Adjust the height of camera ---
@export var height_speed: float = 0.05
@export var min_height: float = 0.1
@export var max_height: float = 1.5
# -----------------------

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):  # ESC for escape mouse mode
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	var shift_is_on: bool = Input.is_key_pressed(KEY_SHIFT)

	if event.is_action_pressed("zoom_in"):
		if shift_is_on:
			position.y = clamp(position.y + height_speed, min_height, max_height)
			print("Height increaded:", position.y)
		else:
			spring_length = clamp(spring_length - zoom_speed, min_zoom, max_zoom)

	if event.is_action_pressed("zoom_out"):
		if shift_is_on:
			position.y = clamp(position.y - height_speed, min_height, max_height)
			print("Height decreased:", position.y)
		else:
			spring_length = clamp(spring_length + zoom_speed, min_zoom, max_zoom)


	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			rotate_from_vector(event.relative * mouse_sensitivity)

func rotate_from_vector(vector: Vector2) -> void:
	if vector.length() == 0:
		return
	rotation.y -= vector.x
	rotation.x -= vector.y
	rotation.x = clamp(rotation.x, min_camera_limit_x, max_camera_limit_x)
