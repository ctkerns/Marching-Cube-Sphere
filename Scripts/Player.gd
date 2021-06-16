extends KinematicBody

# Usain Bolt's max speed and acceleration while running.
# Divided by two when walking.
var _walk_speed = 12.42771/2
var _walk_acceleration = 9.5/2
var _mouse_sensitivity = 0.1
var _velocity = Vector3()
var _grounded = false
var _friction = 1.0
var _jump = 5.0

var _flying = false

onready var pitch = $PitchRotator
onready var camera = $PitchRotator/Camera

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	self.set_rotation(Vector3())
	
func _process(delta):
	# Fly mode.
	if Input.is_action_just_pressed("fly"):
		_flying = not _flying

	# Free the mouse.
	if Input.is_action_just_pressed("free_mouse"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		
	# Update player rotation to spherical tangent.
	var prev_forward = -self.get_transform().basis.z
	var look_up = self.get_translation().normalized()
	var look_forward = look_up.cross(prev_forward.cross(look_up)).normalized()
	self.look_at(self.get_translation() + look_forward, look_up)
	
func _physics_process(delta):
	var up = self.get_translation().normalized()
	var direction = Vector3()
	var forward = self.get_global_transform().basis
	
	# Find the player's intended direction.
	if _grounded or _flying:
		if Input.is_action_pressed("move_forward"):
			direction -= forward.z
		if Input.is_action_pressed("move_backward"):
			direction += forward.z
		if Input.is_action_pressed("move_left"):
			direction -= forward.x
		if Input.is_action_pressed("move_right"):
			direction += forward.x
		if Input.is_action_pressed("move_up"):
			up = self.get_translation().normalized()
			_velocity += up*_jump
		if Input.is_action_pressed("move_down") and _flying:
			up = self.get_translation().normalized()
			_velocity -= up*_jump
	
		# Walk or run.
		var speed
		var acceleration
		if Input.is_action_pressed("sprint"):
			speed = _walk_speed*2
			acceleration = _walk_acceleration*2
		else:
			speed = _walk_speed
			acceleration = _walk_acceleration

		# Fast flying.
		if _flying:
			acceleration = acceleration*4
			speed = speed*4

		direction = direction.normalized()*speed
		_velocity = _velocity.linear_interpolate(direction, acceleration*delta)

		# Friction.
		if direction == Vector3():
			var horizontal = _velocity - _velocity.project(-up)
			_velocity = _velocity.linear_interpolate(-horizontal, _friction*delta)
	
	# Do the gravity.
	if !_grounded and !_flying:
		_velocity -= up*9.8*delta
	
	# Collide.
	var collision = move_and_collide(_velocity*delta)
	_grounded = false
	if collision != null:
		var vertical = _velocity.project(-collision.normal)
		_velocity -= vertical
		_grounded = true

func _input(event):
	# Rotate the camera.
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		pitch.rotate_object_local(Vector3(1, 0, 0), deg2rad(event.relative.y*_mouse_sensitivity*-1))
		self.rotate_object_local(Vector3(0, 1, 0), deg2rad(event.relative.x*_mouse_sensitivity*-1))

		var clamped_rotation = pitch.rotation_degrees
		clamped_rotation.x = clamp(clamped_rotation.x, -90, 90)
		pitch.rotation_degrees = clamped_rotation
