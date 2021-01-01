extends Spatial

var _faces = []

func _ready():
	_faces.append(get_node("PlanetFace1")) # y +
	_faces.append(get_node("PlanetFace2")) # z +
	_faces.append(get_node("PlanetFace3")) # x +
	_faces.append(get_node("PlanetFace4")) # z -
	_faces.append(get_node("PlanetFace5")) # x -
	_faces.append(get_node("PlanetFace6")) # y -

func init():
	for face in _faces:
		face.init(3, 1, 3)

func _draw():
	for face in _faces:
		face.draw()
