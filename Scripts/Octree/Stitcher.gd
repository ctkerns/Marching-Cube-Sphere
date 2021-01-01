extends Object

class Stitcher:
	var _dual_verts
	var _surface_verts
	var _surface_normals

	func init():
		_dual_verts = PoolVector3Array()
		_surface_verts = PoolVector3Array()
		_surface_normals = PoolVector3Array()

	func get_dual_verts():
		return _dual_verts

	func get_surface_verts():
		return _surface_verts

	func get_surface_normals():
		return _surface_normals

	func draw(chunk1, chunk2, chunk3):
		pass