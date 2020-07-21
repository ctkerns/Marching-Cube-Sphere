extends Node

var projection = preload("res://Scripts/CubeSphere Projections/ProjectionASC.gd").new()

var _ax1 = Vector3(0, 0, 1)
var _ax2

func cube2sphere(x, y, z):
	# Establish starting vertex.
	var vert = Vector3(0, 1, 0)
	
	# Project point to spherical coordinates. Sans radius.
	var ang = projection.inverse(x, y)
	
	# Perform first quaternion rotation.
	var quat1 = Quat(_ax1, ang.x)
	vert = quat1.xform(vert)
	
	# Perform second quaterion rotation.
	_ax2 = Vector3(cos(ang.x), sin(ang.x), 0)
	var quat2 = Quat(_ax2, ang.y)
	vert = quat2.xform(vert)
	
	# Scale normalized vert to appropriate radius.
	vert *= z
	
	return vert
