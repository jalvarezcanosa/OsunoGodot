extends TextureRect

@export var atlas_offset: Vector2 = Vector2.ZERO
@export var card_size: Vector2 = Vector2(168, 260)

func _ready():
	if material == null:
		return

	material.set_shader_parameter("rect_size", size)
	material.set_shader_parameter("card_size", card_size)

	var tex := texture
	if tex is Texture2D:
		material.set_shader_parameter("atlas_size", tex.get_size())
		material.set_shader_parameter("atlas_offset", atlas_offset)
