extends TextureRect

@export var atlas_offset: Vector2 = Vector2.ZERO
@export var card_size: Vector2 = Vector2(168, 260)

func _ready():
	if texture != null:
		_initialize_shader()
		
func _initialize_shader():
	if material == null:
		return
		
	var tex := texture
	if tex == null:
		return
	
	material.set_shader_parameter("rect_size", size)
	material.set_shader_parameter("card_size", card_size)
	material.set_shader_parameter("atlas_size", tex.get_size())
	material.set_shader_parameter("atlas_offset", atlas_offset)
