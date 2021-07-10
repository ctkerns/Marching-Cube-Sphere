extends Spatial

func _ready():
	var earth = get_node("Planet")
	earth.init(200.0)
	earth.draw()
