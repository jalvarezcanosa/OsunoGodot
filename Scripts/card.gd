extends Button

@onready var sonido_click: AudioStreamPlayer = $"Sonido Click"
@onready var sonido_pick: AudioStreamPlayer = $"Sonido Pick"
@onready var sonido_release: AudioStreamPlayer = $"Sonido Release"

@export var angle_x_max: float = 15.0
@export var angle_y_max: float = 15.0
@export var max_offset_shadow: float = 50.0

@export_category("Oscillator")
@export var spring: float = 150.0
@export var damp: float = 10.0
@export var velocity_multiplier: float = 1.5

var displacement: float = 0.0
var oscillator_velocity: float = 0.0

var tween_rot: Tween
var tween_hover: Tween
var tween_destroy: Tween
var tween_handle: Tween

var last_mouse_pos: Vector2
var mouse_velocity: Vector2
var following_mouse: bool = false
var last_pos: Vector2
var velocity: Vector2

var arrastrando: bool = false
var dentro: bool = false
var puede_pickear: bool = true
var card_code: String = ""
var original_position: Vector2

signal card_clicked(card_code: String)

@onready var card_texture: TextureRect = $CardTexture
@onready var shadow = $Shadow
@onready var collision_shape = $DestroyArea/CollisionShape2D


# Set codigo seguro y carta inicial

func set_codigo(c: String) -> void:
	card_code = c

	if card_code == null or card_code == "":
		# Carta inicial o sin código → sin animaciones ni follow
		following_mouse = false
		arrastrando = false
		puede_pickear = false
		scale = Vector2.ONE
		rotation = 0
		shadow.self_modulate.a = 0.4
		# si quieres poner textura por defecto, descomenta:
		# card_texture.texture = CardAtlas.get_card_texture("R0")
		return

	if card_texture == null:
		push_error("CardTexture es NULL")
		return

	var tex := CardAtlas.get_card_texture(card_code)
	if tex == null:
		push_error("Textura NULL para carta: " + card_code)
		return

	card_texture.texture = tex

	# refrescar shader si existe
	if card_texture.material != null:
		card_texture.material.set_shader_parameter("atlas_size", tex.get_size())
		card_texture.material.set_shader_parameter("atlas_size", tex.get_size())
		card_texture.material.set_shader_parameter("rect_size", card_texture.size)
		card_texture.material.set_shader_parameter("card_size", card_texture.card_size)
		card_texture.material.set_shader_parameter("atlas_offset", card_texture.atlas_offset)

func _ready() -> void:
	shadow.self_modulate.a = 0.4
	angle_x_max = deg_to_rad(angle_x_max)
	angle_y_max = deg_to_rad(angle_y_max)
	collision_shape.set_deferred("disabled", true)
	original_position = position
	
	if has_node("DestroyArea"):
		var destroy_area = get_node("DestroyArea")

func _process(delta: float) -> void:
	rotate_velocity(delta)
	follow_mouse(delta)
	handle_shadow(delta)

func destroy() -> void:
	card_texture.use_parent_material = true
	if tween_destroy and tween_destroy.is_running():
		tween_destroy.kill()
	tween_destroy = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	tween_destroy.tween_property(material, "shader_parameter/dissolve_value", 0.0, 2.0).from(1.0)
	tween_destroy.parallel().tween_property(shadow, "self_modulate:a", 0.0, 1.0)

func rotate_velocity(delta: float) -> void:
	if not following_mouse:
		return

	velocity = (position - last_pos) / delta
	last_pos = position

	oscillator_velocity += velocity.normalized().x * velocity_multiplier
	var force = -spring * displacement - damp * oscillator_velocity
	oscillator_velocity += force * delta
	displacement += oscillator_velocity * delta
	rotation = displacement

func handle_shadow(delta: float) -> void:
	var center: Vector2 = get_viewport_rect().size / 2.0
	var distance: float = global_position.x - center.x
	shadow.position.x = lerp(0.0, -sign(distance) * max_offset_shadow, abs(distance / center.x))

func follow_mouse(delta: float) -> void:
	if not following_mouse:
		return
	global_position = get_global_mouse_position() - (size / 2.0)

func handle_mouse_click(event: InputEvent) -> void:
	shadow.self_modulate.a = 0.8
	if not event is InputEventMouseButton:
		return
	if event.button_index != MOUSE_BUTTON_LEFT:
		return

	if event.is_pressed():
		original_position = position
		arrastrando = true
		puede_pickear = false
		following_mouse = true
		sonido_click.play()
		collision_shape.set_deferred("disabled", true)
	else:
		arrastrando = false
		following_mouse = false
		collision_shape.set_deferred("disabled", false)

		if dentro:
			sonido_release.play()

		if tween_rot and tween_rot.is_running():
			tween_rot.kill()
		tween_rot = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK).set_parallel(true)
		tween_rot.tween_property(card_texture.material, "shader_parameter/x_rot", 0.0, 0.5)
		tween_rot.tween_property(card_texture.material, "shader_parameter/y_rot", 0.0, 0.5)

		if tween_hover and tween_hover.is_running():
			tween_hover.kill()
		tween_hover = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
		tween_hover.tween_property(self, "scale", Vector2.ONE, 0.55)

		shadow.self_modulate.a = 0.4

		if tween_handle and tween_handle.is_running():
			tween_handle.kill()
		tween_handle = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
		tween_handle.tween_property(self, "rotation", 0.0, 0.3)

func _on_gui_input(event: InputEvent) -> void:
	handle_mouse_click(event)
	if following_mouse:
		return
	if not event is InputEventMouseMotion:
		return

	var mouse_pos: Vector2 = get_local_mouse_position()
	var lerp_val_x: float = remap(mouse_pos.x, 0.0, size.x, 0, 1)
	var lerp_val_y: float = remap(mouse_pos.y, 0.0, size.y, 0, 1)

	var rot_x: float = rad_to_deg(lerp_angle(-angle_x_max, angle_x_max, lerp_val_x))
	var rot_y: float = rad_to_deg(lerp_angle(angle_y_max, -angle_y_max, lerp_val_y))

	card_texture.material.set_shader_parameter("x_rot", rot_y)
	card_texture.material.set_shader_parameter("y_rot", rot_x)

func _on_mouse_entered() -> void:
	dentro = true
	if arrastrando or not puede_pickear:
		return
	sonido_pick.play()

	if tween_hover and tween_hover.is_running():
		tween_hover.kill()
	tween_hover = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	tween_hover.tween_property(self, "scale", Vector2(1.2, 1.2), 0.5)

func _on_mouse_exited() -> void:
	dentro = false
	puede_pickear = true
	if arrastrando:
		return

	shadow.self_modulate.a = 0.4

	if tween_rot and tween_rot.is_running():
		tween_rot.kill()
	#tween_rot = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK).set_parallel(true)
	#tween_rot.tween_property(card_texture.material, "shader_parameter/x_rot", 0.0, 0.5)
	#tween_rot.tween_property(card_texture.material, "shader_parameter/y_rot", 0.0, 0.5)

	if tween_hover and tween_hover.is_running():
		tween_hover.kill()
	tween_hover = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	tween_hover.tween_property(self, "scale", Vector2.ONE, 0.55)
	
func _check_dropped_on_nothing():
	# Si seguimos existiendo y no fuimos destruidos por una jugada válida
	# Volvemos a la mano
	if is_instance_valid(self):
		return_to_hand()
		
func return_to_hand() -> void:
	collision_shape.set_deferred("disabled", true)
	
	if tween_handle and tween_handle.is_running():
		tween_handle.kill()

	tween_handle = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	tween_handle.tween_property(self, "position", original_position, 0.5)
	tween_handle.parallel().tween_property(self, "rotation", 0.0, 0.5)
