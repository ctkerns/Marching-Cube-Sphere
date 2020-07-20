extends Spatial

var _initialized = false

var _faces = []

func _ready():
	_faces.append(get_node("Face1")) # y +
	_faces.append(get_node("Face2")) # z +
	_faces.append(get_node("Face3")) # x +
	_faces.append(get_node("Face4")) # z -
	_faces.append(get_node("Face5")) # x -
	_faces.append(get_node("Face6")) # y -

func init(octree_depth):
	_initialized = true
	
	for face in _faces:
		face.init(octree_depth)

func _draw():
	if not _initialized:
		print("You need to initialize this planet before drawing")
		return
	
	_faces[0].draw()
	# for face in _faces:
	# 	face.draw()
