extends Node

@onready var _velocity = Vector3(0.0, 0.0, 0.0)

@onready var parent = get_parent()

func _physics_process(delta):
	var collision = parent.move_and_collide(_velocity*delta)
	
func get_up_vector():
	return parent.get_translation().normalized()
	
func update_velocity(delta_velocity):
	_velocity += delta_velocity
