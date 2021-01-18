extends Node

var _grav_acc = 9.8

# Restrict use to movable components.
@onready var parent = get_parent()

func _physics_process(delta):
	var up = parent.get_up_vector()
	
	parent.update_velocity(-up*_grav_acc*delta)
