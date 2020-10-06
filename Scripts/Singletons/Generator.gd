extends Node

onready var noise = OpenSimplexNoise.new()

func _ready():
	randomize()
	noise.seed = randi()
	# noise.octaves = 4
	# noise.period = 20.0
	# noise.persistence = 0.8

func sample(x: float, y: float, z: float) -> float:
	var sample = (noise.get_noise_3d(x, y, z) + 1)/2

	var magnitude = Vector3(x, y, z).length()

	return sample/(magnitude / 4)
