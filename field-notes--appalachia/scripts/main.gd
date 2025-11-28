extends Node3D

@onready var tp_cam: Camera3D = $Camera3D
@onready var robo_cam: Camera3D = $Player/third_p_controller/Robot/SpringArm3D/RoboCam
@onready var robot: Node3D = $Player/third_p_controller/Robot


func _ready() -> void:
	tp_cam.make_current()
	
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("toggle_camera"):
		if tp_cam.is_current():
			robo_cam.make_current()
			robot.hide()
		else:
			tp_cam.make_current()
			robot.show()
	
