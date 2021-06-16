extends Object

var _noise
var _radius

func _init(radius):
	_radius = radius
	
	_noise = OpenSimplexNoise.new()
	randomize()
	_noise.seed = randi()

func sample(x: float, y: float, z: float) -> float:
	var vol = _noise.get_noise_3d(x, y, z)

	var magnitude = Vector3(x, y, z).length()

	vol = magnitude/-_radius + 1.0 + vol/1.0 + (randf()*2.0 - 1.0)/48.0 

	if vol > 1.0:
		vol = 1.0
	elif vol < 0.0:
		vol = 0.0

	return vol
