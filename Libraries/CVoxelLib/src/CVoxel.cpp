#include "Octnode.hpp"
#include "Octree.hpp"
#include "Generator.hpp"
#include "OctreeChunk.hpp"
#include "MarchingCubes.hpp"

extern "C" void GDN_EXPORT godot_gdnative_init(godot_gdnative_init_options *o) {
	godot::Godot::gdnative_init(o);
}

extern "C" void GDN_EXPORT godot_gdnative_terminate(godot_gdnative_terminate_options *o) {
	godot::Godot::gdnative_terminate(o);
}

extern "C" void GDN_EXPORT godot_nativescript_init(void *handle) {
	godot::Godot::nativescript_init(handle);

	godot::register_class<Octnode>();
	godot::register_class<Octree>();
	godot::register_class<Generator>();
	godot::register_class<OctreeChunk>();
	godot::register_class<MarchingCubes>();
}
