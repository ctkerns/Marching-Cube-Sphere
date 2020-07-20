extends Spatial

func _ready():
	var earth = get_node("Planet")
	earth.init(0)
	earth._draw()
