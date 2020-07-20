extends Object
# Tangential Spherical Cube Projection

func forward(th, phi):
	var x = tan(th)
	var y = tan(phi)/cos(th)
	
	return Vector2(x, y)
	
func inverse(x, y):
	var th = atan(x)
	var phi = atan(y*cos(th))
	
	return Vector2(th, phi)
