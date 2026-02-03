extends MeshInstance2D

func _process(delta):
	var global_mouse: Vector2 = get_viewport().get_mouse_position()
	var local_mouse: Vector2 = to_local(global_mouse)

	var mat: ShaderMaterial = material
	if mat:
		mat.set_shader_parameter("mouse_pos", local_mouse)
