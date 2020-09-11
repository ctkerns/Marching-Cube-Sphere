extends Object

class Octnode:
	var _volume

	func _init(vol):
		_volume = vol
	
	func get_volume():
		return _volume

	func set_volume(vol):
		_volume = vol
