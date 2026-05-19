extends CharacterBody3D

# 3rd person camera
@export var camera_3d: Camera3D
@export var visual_for_camera: Node3D
@export var state_machine: Node

# Move
@export_group("Move logic")
@export var speed: float = 4.0
@export var rotate_speed: float = 10.0
var move_input_dir: Vector2 = Vector2.ZERO
var can_player_move: bool = false

# Jump
@export_group("Jump logic")
@export var jump_height: float = 2.25
@export var jump_time_to_peak: float = 0.4
@export var jump_time_to_descent: float = 0.3
@onready var jump_velocity: float = (2.0 * jump_height) / jump_time_to_peak
@onready var jump_gravity: float = ((-2.0 * jump_height) / (jump_time_to_peak * jump_time_to_peak)) * -1.0
@onready var fall_gravity: float = ((-2.0 * jump_height) / (jump_time_to_descent * jump_time_to_descent)) * -1.0


func _physics_process(delta: float) -> void:
	move_logic(delta)
	jump_logic(delta)
	move_and_slide()

	
func move_logic(delta: float) -> void:
	move_input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down").rotated(-camera_3d.global_rotation.y)

	velocity.x = move_input_dir.x * speed
	velocity.z = move_input_dir.y * speed

	if is_on_floor():
		if move_input_dir.length() > 0:
			can_player_move = true
			state_machine.set_move_state("Running")
		else:
			can_player_move = false
			state_machine.set_move_state("Idle")

	if move_input_dir.length() > 0:
		var face_angle: float = -move_input_dir.angle() + PI / 2
		visual_for_camera.rotation.y = rotate_toward(visual_for_camera.rotation.y, face_angle, rotate_speed * delta)
func jump_logic(delta: float) -> void:
	if is_on_floor():
		if Input.is_action_just_pressed("Jump"):
			velocity.y = jump_velocity
	else:
		state_machine.set_move_state("Jump")
		# 處理重力
	var gravity: float = jump_gravity if velocity.y > 0.0 else fall_gravity
	velocity.y -= gravity * delta
