extends Spatial

func _ready():
	var earth = get_node("Planet")
	earth.init(8)
	earth._draw()
