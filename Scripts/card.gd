extends Button

# --- Audio ---
@onready var sonido_click: AudioStreamPlayer = $"Sonido Click"
@onready var sonido_pick: AudioStreamPlayer = $"Sonido Pick"
@onready var sonido_release: AudioStreamPlayer = $"Sonido Release"

# --- Animación ---
@export var angle_x_max: float = 15.0
@export var angle_y_max: float = 15.0
@export var max_offset_shadow: float = 50.0
@export_category("Oscillator")
@export var spring: float = 150.0
@export var damp: float = 10.0
@export var velocity_multiplier: float = 1.5

# --- Estado ---
var displacement: float = 0.0
var oscillator_velocity: float = 0.0

var tween_rot: Tween
var tween_hover: Tween
var tween_destroy: Tween
var tween_handle: Tween

var last_pos: Vector2
var velocity: Vector2
var following_mouse: bool = false
var arrastrando: bool = false
var dentro: bool = false
var puede_pickear: bool = true
var card_code: String = ""

signal card_clicked(card_code: String)
signal carta_soltada(card)

@onready var shadow: TextureRect = $Shadow
@onready var collision_shape: CollisionShape2D = $DestroyArea/CollisionShape2D

# -------------------
func set_rival() -> void:
	puede_pickear = false
	arrastrando = false
	following_mouse = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	disabled = true

# -------------------
func set_codigo(c: String) -> void:
	card_code = c
	text = card_code  # muestra el valor por defecto

	if card_code == null or card_code == "":
		following_mouse = false
		arrastrando = false
		puede_pickear = false
		scale = Vector2.ONE
		rotation = 0
		if shadow:
			shadow.self_modulate.a = 0.4
		# Color neutro
		var style := StyleBoxFlat.new()
		style.bg_color = Color.DIM_GRAY
		style.corner_radius_top_left = 10
		style.corner_radius_top_right = 10
		style.corner_radius_bottom_left = 10
		style.corner_radius_bottom_right = 10
		add_theme_stylebox_override("normal", style)
		add_theme_stylebox_override("hover", style)
		add_theme_stylebox_override("pressed", style)
		return

	# Parsea color y valor
	var color_code := card_code.substr(0, 1).to_lower()
	var value := card_code.substr(1)
	text = value

	# Asignar color
	var style := StyleBoxFlat.new()
	match color_code:
		"r":
			style.bg_color = Color.RED
		"g":
			style.bg_color = Color.GREEN
		"b":
			style.bg_color = Color.DODGER_BLUE
		"y":
			style.bg_color = Color.GOLD
		_:
			style.bg_color = Color.DIM_GRAY

	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10

	add_theme_stylebox_override("normal", style)
	add_theme_stylebox_override("hover", style)
	add_theme_stylebox_override("pressed", style)

	# Texto siempre visible
	add_theme_color_override("font_color", Color.WHITE)
	add_theme_color_override("font_color_hover", Color.WHITE)
	add_theme_color_override("font_color_pressed", Color.WHITE)

	# Estado inicial
	following_mouse = false
	arrastrando = false
	puede_pickear = true
	scale = Vector2.ONE
	rotation = 0
	if shadow:
		shadow.self_modulate.a = 0.4

# -------------------
func _ready() -> void:
	if shadow:
		shadow.self_modulate.a = 0.4
	angle_x_max = deg_to_rad(angle_x_max)
	angle_y_max = deg_to_rad(angle_y_max)
	if collision_shape:
		collision_shape.set_deferred("disabled", true)

# -------------------
func _process(delta: float) -> void:
	rotate_velocity(delta)
	follow_mouse(delta)
	handle_shadow(delta)

# -------------------
func rotate_velocity(delta: float) -> void:
	if not following_mouse:
		return

	velocity = (position - last_pos) / delta
	last_pos = position

	if velocity.length() != 0:
		oscillator_velocity += velocity.normalized().x * velocity_multiplier

	var force = -spring * displacement - damp * oscillator_velocity
	oscillator_velocity += force * delta
	displacement += oscillator_velocity * delta
	rotation = displacement

# -------------------
func handle_shadow(delta: float) -> void:
	if not shadow:
		return
	var center: Vector2 = get_viewport_rect().size / 2.0
	var distance: float = global_position.x - center.x
	shadow.position.x = lerp(0.0, -sign(distance) * max_offset_shadow, abs(distance / center.x))

# -------------------
func follow_mouse(delta: float) -> void:
	if not following_mouse:
		return
	global_position = get_global_mouse_position() - (size / 2.0)

# -------------------
func handle_mouse_click(event: InputEvent) -> void:
	if arrastrando or Session.is_dragging_card:
		return

	if not event is InputEventMouseButton:
		return
	if event.button_index != MOUSE_BUTTON_LEFT:
		return

	if event.is_pressed():
		if not puede_pickear:
			return
		arrastrando = true
		Session.is_dragging_card = true
		puede_pickear = false
		following_mouse = true
		if sonido_click:
			sonido_click.play()
		if collision_shape:
			collision_shape.set_deferred("disabled", false)
	else:
		arrastrando = false
		Session.is_dragging_card = false
		following_mouse = false
		if collision_shape:
			collision_shape.set_deferred("disabled", false)
		emit_signal("carta_soltada", self)
		if dentro and sonido_release:
			sonido_release.play()
		reset_rotation_scale()

# -------------------
func reset_rotation_scale() -> void:
	if tween_rot and tween_rot.is_running():
		tween_rot.kill()
	tween_rot = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK).set_parallel(true)
	tween_rot.tween_property(self, "rotation", 0.0, 0.3)
	if tween_hover and tween_hover.is_running():
		tween_hover.kill()
	tween_hover = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	tween_hover.tween_property(self, "scale", Vector2.ONE, 0.55)
	if shadow:
		shadow.self_modulate.a = 0.4

# -------------------
func _on_gui_input(event: InputEvent) -> void:
	handle_mouse_click(event)

# -------------------
func _on_mouse_entered() -> void:
	dentro = true
	if arrastrando or not puede_pickear:
		return
	if sonido_pick:
		sonido_pick.play()
	if tween_hover and tween_hover.is_running():
		tween_hover.kill()
	tween_hover = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	tween_hover.tween_property(self, "scale", Vector2(1.2, 1.2), 0.5)

# -------------------
func _on_mouse_exited() -> void:
	dentro = false
	puede_pickear = true
	if arrastrando:
		return
	reset_rotation_scale()
