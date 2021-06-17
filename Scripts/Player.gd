extends KinematicBody

var _mouse_sensitivity = 0.1
var _velocity = Vector3()
var _grounded = false
var _friction = 0.35 # Grass coefficient of friction.
var _gravity = 9.8 # Earth gravitational acceleration.
var _jump = 5.0

# These are for the animation.
var _stride = 2.0
var _stride_frequency = 3.0

var _speed = _stride*_stride_frequency
var _acceleration = 9.5

var _flying = false

onready var pitch = $PitchRotator
onready var camera = $PitchRotator/Camera
onready var camera_animation = $PitchRotator/Camera/AnimationPlayer

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	self.set_rotation(Vector3())
	
func _process(_delta):
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
	
	var jump = _jump
	if _flying:
		jump *= 4.0
	
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
			_velocity += up*jump
		if Input.is_action_pressed("move_down") and _flying:
			up = self.get_translation().normalized()
			_velocity -= up*jump
	
		# Walk or run.
		var speed = _speed
		var acceleration = _acceleration
		var frequency = _stride_frequency
		if Input.is_action_pressed("sprint"):
			speed *= 1.618
			acceleration *= 1.618
			frequency *= 1.618

		# Fast flying.
		if _flying:
			acceleration *= 4.0
			speed *= 4.0

		direction = direction.normalized()*speed
		_velocity = _velocity.linear_interpolate(direction, acceleration*delta)

		# Play walk animation.
		camera_animation.playback_speed = _stride_frequency
		if not _flying and direction != Vector3():
			camera_animation.play("HeadBob")
	
	# Do the gravity.
	if not _grounded and not _flying:
		_velocity -= up*_gravity*delta
	
	# Collide.
	var collision = move_and_collide(_velocity*delta)
	_grounded = false
	if collision != null:
		var normal = _velocity.project(-collision.normal)
		_velocity -= normal
		_grounded = true

		# Friction. Only calculate while walking.
		if direction == Vector3():
			_velocity = _velocity.linear_interpolate(-_velocity.normalized(), _friction*_gravity*delta)

func _input(event):
	# Rotate the camera.
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		pitch.rotate_object_local(Vector3(1, 0, 0), deg2rad(event.relative.y*_mouse_sensitivity*-1))
		self.rotate_object_local(Vector3(0, 1, 0), deg2rad(event.relative.x*_mouse_sensitivity*-1))

		var clamped_rotation = pitch.rotation_degrees
		clamped_rotation.x = clamp(clamped_rotation.x, -90, 90)
		pitch.rotation_degrees = clamped_rotation
