extends Object

class Octnode:
	var _children = []

	func _init():
		pass
	
	func _split():
		for _i in range(8):
			_children.append(get_script().new())
			
	func _get_child(idx):
		if (_children.size() > idx):
			return _children[idx]

	func _is_leaf():
		return _children.size() == 0
