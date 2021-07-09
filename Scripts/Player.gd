extends KinematicBody

var _mouse_sensitivity = 0.1
var _velocity = Vector3()
var _grounded = false
var _swimming = false
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
onready var ray_cast = $PitchRotator/Camera/RayCast

signal carve_terrain(intersection)
signal place_terrain(intersection)
signal underwater(point, caller)

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
	
	# Modify the environment.
	if ray_cast.is_colliding() and ray_cast.is_enabled():
		if Input.is_action_just_pressed("left_click"):
			emit_signal("carve_terrain", ray_cast.get_collision_point())
		if Input.is_action_just_pressed("right_click"):
			emit_signal("place_terrain", ray_cast.get_collision_point())
	
	# Check if underwater.
	emit_signal("underwater", self.get_translation(), self)

# Find the player's intended direction.
func get_direction(use_vertical):
	var forward = self.get_global_transform().basis
	var direction = Vector3()

	if Input.is_action_pressed("move_forward"):
		direction -= forward.z
	if Input.is_action_pressed("move_backward"):
		direction += forward.z
	if Input.is_action_pressed("move_left"):
		direction -= forward.x
	if Input.is_action_pressed("move_right"):
		direction += forward.x
	if (use_vertical):
		if Input.is_action_pressed("move_up"):
			direction += forward.y
		if Input.is_action_pressed("move_down"):
			direction -= forward.y

	return direction.normalized()

func move_in_direction(delta, direction, speed, acceleration):
	var movement = direction*speed;
	_velocity = _velocity.linear_interpolate(movement, acceleration*delta)

# A singular change in velocity.
func jump(jump):
	var up = self.get_translation().normalized()

	if Input.is_action_just_pressed("move_up"):
		up = self.get_translation().normalized()
		_velocity += up*jump
	if Input.is_action_just_pressed("move_down") and _flying:
		up = self.get_translation().normalized()
		_velocity -= up*jump

func friction(delta, coeffF):
	_velocity = _velocity.linear_interpolate(-_velocity.normalized(), coeffF*_gravity*delta)

func gravity(delta, G):
	var up = self.get_translation().normalized()
	_velocity -= up*G*delta

func walk(delta):
	# Walk and jump.
	var direction = get_direction(false)
	var mult = 1.0
	if Input.is_action_pressed("sprint"):
		mult *= 1.618
	move_in_direction(delta, direction, _speed*mult, _acceleration*mult)
	jump(_jump)

	# Play walk animation.
	camera_animation.playback_speed = _stride_frequency*mult
	if direction != Vector3():
		camera_animation.play("HeadBob")
	# Apply friction when not walking.
	else:
		friction(delta, _friction)

func fly(delta):
	var direction = get_direction(true)
	var mult = 4.0
	if Input.is_action_pressed("sprint"):
		mult *= 1.618
	move_in_direction(delta, direction, _speed*mult, _acceleration*mult)

func swim(delta):
	var direction = get_direction(true)
	var mult = 1.0
	if Input.is_action_pressed("sprint"):
		mult *= 1.618
	move_in_direction(delta, direction, _speed*mult, _acceleration*mult)
	
	# Float.
	gravity(delta, -9.8)

func _physics_process(delta):
	# Player movement.
	if _flying:
		fly(delta)
	elif _swimming:
		swim(delta)
	elif _grounded:
		walk(delta)
	else:
		gravity(delta, _gravity)
	
	# Collide.
	var collision = move_and_collide(_velocity*delta)
	_grounded = false
	if collision != null:
		var normal = _velocity.project(-collision.normal)
		_velocity -= normal
		_grounded = true

func _input(event):
	# Rotate the camera.
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		pitch.rotate_object_local(Vector3(1, 0, 0), deg2rad(event.relative.y*_mouse_sensitivity*-1))
		self.rotate_object_local(Vector3(0, 1, 0), deg2rad(event.relative.x*_mouse_sensitivity*-1))

		var clamped_rotation = pitch.rotation_degrees
		clamped_rotation.x = clamp(clamped_rotation.x, -90, 90)
		pitch.rotation_degrees = clamped_rotation
		
func underwater(underwater):
	_swimming = underwater
