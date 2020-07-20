extends Object
# Adjusted Spherical Cube Projection

func forward(th, phi):
	var x = th*4/PI
	var y = atan(tan(phi)/cos(th))*4/PI
	
	return Vector2(x, y)
	
func inverse(x, y):
	var th = x*PI/4
	var phi = atan(tan(PI*y/4)*cos(th))
	
	return Vector2(th, phi)
