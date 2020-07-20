extends Spatial

var _speed = 5
var _mouse_sensitivity = 0.1
var rotator
var camera

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	rotator = get_node("Rotator")
	camera = get_node("Rotator/Camera")
	
func _process(delta):
	# Free the mouse.
	if Input.is_action_just_pressed("free_mouse"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	if Input.is_action_pressed("move_forward"):
		translate(Vector3(0, 0, -_speed*delta))
	if Input.is_action_pressed("move_backward"):
		translate(Vector3(0, 0, _speed*delta))
	if Input.is_action_pressed("move_left"):
		translate(Vector3(-_speed*delta, 0, 0))
	if Input.is_action_pressed("move_right"):
		translate(Vector3(_speed*delta, 0, 0))
	if Input.is_action_pressed("move_up"):
		translate(Vector3(0, _speed*delta, 0))
	if Input.is_action_pressed("move_down"):
		translate(Vector3(0, -_speed*delta, 0))

func _input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotator.rotate_x(deg2rad(event.relative.y*_mouse_sensitivity*-1))
		self.rotate_y(deg2rad(event.relative.x*_mouse_sensitivity*-1))
		
		var clamped_rotation = rotator.rotation_degrees
		clamped_rotation.x = clamp(clamped_rotation.x, -90, 90)
		rotator.rotation_degrees = clamped_rotation
