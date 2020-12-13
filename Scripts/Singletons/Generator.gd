extends Node

onready var noise = OpenSimplexNoise.new()

func _ready():
	randomize()
	noise.seed = randi()
	# noise.octaves = 4
	# noise.period = 20.0
	# noise.persistence = 0.8

func sample(x: float, y: float, z: float, base, top) -> float:
	var vol = noise.get_noise_3d(x, y, z)

	var magnitude = Vector3(x, y, z).length()

	vol = (magnitude - top)/(base - top) + vol/2.0

	if vol > 1.0:
		vol = 1.0
	elif vol < 0.0:
		vol = 0.0

	return vol
