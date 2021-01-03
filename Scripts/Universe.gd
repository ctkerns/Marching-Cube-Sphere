extends Node3D

func _ready():
	var earth = get_node("Planet")
	earth.init()
	earth._draw()
