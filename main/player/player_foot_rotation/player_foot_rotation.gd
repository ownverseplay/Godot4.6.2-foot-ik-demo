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

# Foot IK
@export_group("Foot IK")
@export var visual_for_IK: Node3D
@export var ik_leg_left: TwoBoneIK3D
@export var ik_leg_right: TwoBoneIK3D
@export var ray_leg_left_front: RayCast3D
@export var ray_leg_left_back: RayCast3D
@export var ray_leg_right_front: RayCast3D
@export var ray_leg_right_back: RayCast3D
@export var target_leg_left: Marker3D
@export var target_leg_right: Marker3D
@export var ik_is_enabled: bool = false
@export_range(0.0, 1.0, 0.05) var front_ray_weight: float = 0.5
@export_range(-1, 1, 0.01) var pos_y_height_up: float = 0.11  
@export_range(-1, 1, 0.01) var pos_y_height_flat: float = 0.11 
@export_range(-1, 1, 0.01) var pos_y_height_down: float = 0.1 
@export_range(-1, 1, 0.01) var slope_threshold: float = -0.02
@export_range(0, 100, 1.0) var ik_lerp_speed: float = 10.0
@export_range(0, 1, 0.01) var active_ik_influence: float = 1.0
var inactive_ik_influence: float = 0.0
var last_offset_l: float = 0.0
var last_offset_r: float = 0.0

# Foot Rotation
@export_group("Foot rotation")
@export var rotate_foot_active: bool = true
@export var copy_left_foot: SkeletonModifier3D
@export var copy_right_foot: SkeletonModifier3D
@export var copy_rotate_left: Marker3D
@export var copy_rotate_right: Marker3D
@export var ray_foot_left_front: RayCast3D
@export var ray_foot_left_back: RayCast3D
@export var ray_foot_right_front: RayCast3D
@export var ray_foot_right_back: RayCast3D
@export var rotation_speed: float = 10.0
@export var rotation_influence: float = 1.0
@export var left_foot_rotate_offset: Vector3 = Vector3(1, 0, 0)
@export var right_foot_rotate_offset: Vector3 = Vector3(-5, 5, 0)

func _physics_process(delta: float) -> void:
	move_logic(delta)
	jump_logic(delta)
	move_and_slide()
	handle_leg_ik(delta)
	handle_foot_rotation(delta)

	
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
		
	var gravity: float = jump_gravity if velocity.y > 0.0 else fall_gravity
	velocity.y -= gravity * delta


func handle_leg_ik(delta: float) -> void:

	var should_ik_be_active: bool = is_on_floor() and (ik_is_enabled or !can_player_move)

	ik_leg_left.active = should_ik_be_active
	ik_leg_right.active = should_ik_be_active

	if should_ik_be_active:
		last_offset_l = _process_leg_ik(ray_leg_left_front, ray_leg_left_back, target_leg_left, ik_leg_left, delta)
		last_offset_r = _process_leg_ik(ray_leg_right_front, ray_leg_right_back, target_leg_right, ik_leg_right, delta)
		#print("Left: ", last_offset_l, "    | Right: ", last_offset_r)
		choose_lowest_gap(delta)

	else:
		visual_for_IK.position.y = lerp(visual_for_IK.position.y, 0.0, 15.0 * delta)
		ik_leg_left.influence = 0.0
		ik_leg_right.influence = 0.0

func _process_leg_ik(ray_f: RayCast3D, ray_b: RayCast3D, target_marker: Marker3D, ik: TwoBoneIK3D, delta: float) -> float:
	var is_f_colliding: bool = ray_f.is_colliding()
	var is_b_colliding: bool = ray_b.is_colliding()

	if not (is_f_colliding or is_b_colliding):
		ik.influence = lerpf(ik.influence, inactive_ik_influence, ik_lerp_speed * delta)
		return 0.0

	var avg_hit_y: float

	if ray_f.is_colliding() and ray_b.is_colliding():
		var w_f: float = front_ray_weight
		var w_b: float = 1.0 - front_ray_weight

		avg_hit_y = (ray_f.get_collision_point().y * w_f) + (ray_b.get_collision_point().y * w_b)
	elif is_f_colliding:
		avg_hit_y = ray_f.get_collision_point().y
	else:
		avg_hit_y = ray_b.get_collision_point().y

	var height_diff: float = avg_hit_y - global_position.y

	var current_pos_y: float = 0.0
	
	if height_diff > slope_threshold:
		# 1. Climbing up
		current_pos_y = pos_y_height_up
	elif height_diff < -slope_threshold:
		# 2. Climbing down
		current_pos_y = pos_y_height_down
	else:
		# 3. Walk on flat surface
		current_pos_y = pos_y_height_flat

	target_marker.global_position.y = avg_hit_y + current_pos_y

	ik.influence = lerpf(ik.influence, active_ik_influence, ik_lerp_speed * delta)

	return height_diff

func choose_lowest_gap(delta: float) -> void:
	var lowest_gap: float = min(last_offset_l, last_offset_r)

	if lowest_gap < 0.0:
		visual_for_IK.position.y = lerp(visual_for_IK.position.y, lowest_gap, 10.0 * delta)
	else:
		visual_for_IK.position.y = lerp(visual_for_IK.position.y, 0.0, 10.0 * delta)

func handle_foot_rotation(delta: float) -> void:
	if rotate_foot_active:
		copy_left_foot.active = true
		copy_right_foot.active = true

		var is_idle_or_ik_forced: bool = is_on_floor() and (ik_is_enabled or !can_player_move)

		if is_idle_or_ik_forced:
			# Calculate left foot rotation based on the average of two raycasts
			_process_foot_alignment(delta, ray_foot_left_front, ray_foot_left_back, copy_rotate_left, left_foot_rotate_offset)
			# Calculate right foot rotation based on the average of two raycasts
			_process_foot_alignment(delta, ray_foot_right_front, ray_foot_right_back, copy_rotate_right, right_foot_rotate_offset)

			# Toggle CopyTransformModifier3D influence: 0.0 when running, 1.0 when idle
			_update_influence(delta, rotation_influence)
		else:
			_update_influence(delta, 0.0)
	else:
		copy_left_foot.active = false
		copy_right_foot.active = false


func _update_influence(delta: float, target: float) -> void:
	copy_left_foot.influence = lerpf(copy_left_foot.influence, target, 15.0 * delta)
	copy_right_foot.influence = lerpf(copy_right_foot.influence, target, 15.0 * delta)


# Calculating the rotation of Foot (Target node)
func _process_foot_alignment(delta: float, ray_front: RayCast3D, ray_back: RayCast3D, target_box: Node3D, offset: Vector3) -> void:
	var is_f_colliding: bool = ray_front.is_colliding()
	var is_b_colliding: bool = ray_back.is_colliding()

	if not (is_f_colliding or is_b_colliding):
		return  # If RayCast3D touch nothing, return no value

	# --- 1. Calculate the average value ---
	var final_normal: Vector3
	var final_hit_y: float

	if is_f_colliding and is_b_colliding:
		final_normal = (ray_front.get_collision_normal() + ray_back.get_collision_normal()).normalized()
		final_hit_y = (ray_front.get_collision_point().y + ray_back.get_collision_point().y) / 2.0
	elif is_f_colliding:
		final_normal = ray_front.get_collision_normal().normalized()
		final_hit_y = ray_front.get_collision_point().y
	else:
		final_normal = ray_back.get_collision_normal().normalized()
		final_hit_y = ray_back.get_collision_point().y

	# --- 2. Apply rotation on foot (Target node) ---
	target_box.global_position.y = lerp(target_box.global_position.y, final_hit_y, delta * 20.0)

	var real_foot_forward: Vector3 = -visual_for_camera.global_transform.basis.z.normalized()
	var lateral_right_axis: Vector3 = real_foot_forward.cross(final_normal).normalized()
	if abs(real_foot_forward.dot(final_normal)) > 0.99:
		lateral_right_axis = visual_for_camera.global_transform.basis.x.normalized()

	var final_forward_z: Vector3 = final_normal.cross(lateral_right_axis).normalized()
	var target_basis: Basis = Basis(lateral_right_axis, final_normal, final_forward_z).orthonormalized()

	# --- 3. Rotation offset for foot due to different rig has different offset ---
	var target_quat: Quaternion = target_basis.get_rotation_quaternion()
	var current_quat: Quaternion = target_box.global_transform.basis.orthonormalized().get_rotation_quaternion()
	var smoothed_quat: Quaternion = current_quat.slerp(target_quat, 15.0 * delta)
	var offset_quat: Quaternion = Quaternion.from_euler(Vector3(deg_to_rad(offset.x), deg_to_rad(offset.y), deg_to_rad(offset.z)))

	target_box.global_transform.basis = Basis(smoothed_quat * offset_quat)
