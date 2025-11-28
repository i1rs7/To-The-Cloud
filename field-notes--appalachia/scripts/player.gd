extends Node3D

@onready var tp_cam: Camera3D = $Camera3D
@onready var robo_cam: Camera3D = $third_p_controller/Robot/Head/SpringArm3D/RoboCam
@onready var robo_cam_2: Camera3D = $third_p_controller/Robot/Head/SubViewport/RoboCam2
@onready var robot: Node3D = $third_p_controller/Robot
@onready var cam_ui: Control = $third_p_controller/CamUI
@onready var head: Node3D = $third_p_controller/Robot/Head
@onready var zoom_label: Label = $third_p_controller/CamUI/ZoomLabel
@onready var recent_pic: Sprite2D = $third_p_controller/CamUI/RecentPic
@onready var sub_viewport: SubViewport = $third_p_controller/Robot/Head/SubViewport
@onready var pic_view_timer: Timer = $third_p_controller/CamUI/PicView

@export var tilt_upper_limit := PI / 4.0
@export var tilt_lower_limit := -PI / 7.0

@export_range(0.0, 1.0) 
var mouse_sensitivity := 0.05
var zoom_sensitivity := 0.1
var zoom_amount = 0.0
var zoom_max = 4.0

var camera_open : bool = false
var mouse_captured : bool = false
var look_rotation : Vector2
var move_speed : float = 0.0
var freeflying : bool = false
var look_speed : float = 0.002
var can_move : bool = true

var _camera_input_direction := Vector2.ZERO

enum Cam_States {FIRST_PERSON, THIRD_PERSON}
var cam_state : Cam_States = Cam_States.THIRD_PERSON

func _ready() -> void:
	enter_third_person()

func _unhandled_input(event: InputEvent) -> void:
	# Mouse capturing
	if Input.is_action_just_pressed("left_click") and cam_state == Cam_States.FIRST_PERSON:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		mouse_captured = true
	elif Input.is_action_just_pressed("ui_cancel") or cam_state == Cam_States.THIRD_PERSON:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		mouse_captured = false
	
	#help rotation
	var player_is_using_mouse := (
		event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
	)
	if player_is_using_mouse:
		_camera_input_direction.x = -event.relative.x * mouse_sensitivity
		_camera_input_direction.y = -event.relative.y * mouse_sensitivity

	if Input.is_action_just_pressed("toggle_camera"):
		if cam_state == Cam_States.THIRD_PERSON:
			enter_first_person()
		else:
			enter_third_person()

func _physics_process(delta: float) -> void:
	robo_cam_2.transform = robo_cam.global_transform
	
	# first person properties
	if cam_state == Cam_States.FIRST_PERSON:
		#rotate look
		if InputEventMouseMotion:
			head.rotation.x += _camera_input_direction.y * delta
			head.rotation.x = clamp(head.rotation.x, tilt_lower_limit, tilt_upper_limit)
			head.rotation.y += _camera_input_direction.x * delta
			_camera_input_direction = Vector2.ZERO
			
		#zoom
		if (Input.is_action_just_pressed("zoom in")):
			if zoom_amount < zoom_max:
				zoom_amount += zoom_sensitivity
				robo_cam.fov -= zoom_amount
				robo_cam_2.fov -= zoom_amount
		if (Input.is_action_just_pressed("zoom out")):
			if zoom_amount > 0.0:
				zoom_amount -= zoom_sensitivity
				robo_cam.fov += zoom_amount
				robo_cam_2.fov += zoom_amount
		zoom_label.set_text("Zoom: "+ str(int(zoom_amount*100)) + "%")
		
		#taking picture
		if (Input.is_action_just_pressed("shoot")):
			#saving pic to sprite and assets
			var img = sub_viewport.get_texture().get_image()
			var texture = ImageTexture.new()
			texture = ImageTexture.create_from_image(img)
			recent_pic.texture = texture
			# showing pic in corner
			#recent_pic.show()
			#pic_view_timer.start()
			#await pic_view_timer.timeout
			#print("timed out")
			#recent_pic.hide()


func enter_first_person():
	cam_state = Cam_States.FIRST_PERSON
	robo_cam.make_current()
	cam_ui.show()
	robot.hide()
	Globals.can_move = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	mouse_captured = true
	#recent_pic.hide()
	
func enter_third_person():
	cam_state = Cam_States.THIRD_PERSON
	tp_cam.make_current()
	#cam_ui.hide()
	robot.show()
	Globals.can_move = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	mouse_captured = false
	#recent_pic.hide()

func rotate_look(rot_input : Vector2):
	look_rotation.x -= rot_input.y * look_speed
	look_rotation.x = clamp(look_rotation.x, deg_to_rad(-80), deg_to_rad(80))
	look_rotation.y -= rot_input.x * look_speed
	transform.basis = Basis()
	rotate_y(look_rotation.y)
	head.transform.basis = Basis()
	head.rotate_x(look_rotation.x)
