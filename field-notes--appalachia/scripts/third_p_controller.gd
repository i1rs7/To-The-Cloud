extends CharacterBody3D

@export_group("Movement")
@export var move_speed := 50.0
@export var acceleration := 20.0
@export var jump_impulse := 12.0
@export var rotation_speed := 12.0
@export var stopping_speed := 1.0


var _gravity : = -45.0
var _was_on_floor_last_frame := true


## The last movement or aim direction input by the player. We use this to orient
## the character model.
@onready var _last_input_direction := global_basis.z
# We store the initial position of the player to reset to it when the player falls off the map.
@onready var _start_position := global_position
@onready var _skin = $Robot
@onready var AnimPlayer = $Robot/AnimationPlayer
@onready var robo_cam: Camera3D = $RoboCam
@onready var head_pos: Marker3D = $Robot/Marker3D



func _ready() -> void:
	pass

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += _gravity * delta
	
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	_last_input_direction = Vector3(input_dir.x, 0, input_dir.y)
	if direction:
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed
		var target_angle := Vector3.BACK.signed_angle_to(_last_input_direction, Vector3.UP)
		_skin.global_rotation.y = lerp_angle(_skin.rotation.y, target_angle, rotation_speed * delta)
		#robo_cam.rotation = _skin.global_rotation
		#robo_cam.rotation.y = _skin.global_rotation.y + 180.0
	else:
		velocity.x = move_toward(velocity.x, 0, move_speed)
		velocity.z = move_toward(velocity.z, 0, move_speed)
	

	# Character animations and visual effects.
	var ground_speed := Vector2(velocity.x, velocity.z).length()
	var is_just_jumping := Input.is_action_just_pressed("jump") and is_on_floor()
	if is_just_jumping:
		velocity.y += jump_impulse
		AnimPlayer.play("Robot_Jump")
	elif is_on_floor():
		if ground_speed > 0.0:
			AnimPlayer.play("Robot_Walking")
		else:
			AnimPlayer.play("Robot_Idle")

	#_dust_particles.emitting = is_on_floor() && ground_speed > 0.0

	if is_on_floor() and not _was_on_floor_last_frame:
		pass

	_was_on_floor_last_frame = is_on_floor()
	move_and_slide()
