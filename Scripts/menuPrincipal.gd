extends Control
@onready var volúmen: VBoxContainer = $"Volúmen"
@onready var inicio: VBoxContainer = $"Inicio de sesión"
@onready var click_1: AudioStreamPlayer = $Click1
@onready var click_2: AudioStreamPlayer = $Click2
@onready var http_request: HTTPRequest = $HTTPRequest
@onready var iniciar_sesión: Button = $"Inicio de sesión/Iniciar Sesión"
@onready var errores_login: Label = $"Inicio de sesión/Errores login"
var url : String = "http://localhost:8000/sessions"
# String ip.resolve_hostname (http://localhost:8000/sessions: Type = 3)
func _ready() -> void:
	http_request.request_completed.connect(_on_http_request_request_completed)
	volúmen.hide()
	inicio.hide()
func _on_salir_pressed() -> void:
	click_2.play()
	await get_tree().create_timer(0.2).timeout
	get_tree().quit()
func _on_volver_pressed() -> void:
	volúmen.hide()
	click_2.play()
func _on_slider_música_value_changed(value: float) -> void:
	var bus: int = AudioServer.get_bus_index("Música")
	AudioServer.set_bus_volume_db(bus, linear_to_db(value))

func _on_slider_efectos_value_changed(value: float) -> void:
	var bus: int = AudioServer.get_bus_index("Efectos")
	AudioServer.set_bus_volume_db(bus, linear_to_db(value))

func _on_musica_toggled(toggled_on: bool) -> void:
	if toggled_on:
		volúmen.show()
		click_1.play()
	else:
		volúmen.hide()

func _on_ajustes_toggled(toggled_on: bool) -> void:
	if toggled_on:
		volúmen.show()
		click_1.play()
	else:
		volúmen.hide()
		click_1.play()

func _on_nueva_partida_toggled(toggled_on: bool) -> void:
	if toggled_on:
		inicio.show()
		click_1.play()
	else:
		inicio.hide()

func _on_iniciar_sesión_pressed() -> void:
	click_2.play()
	errores_login.text = ""

	var headers = ["Content-Type: application/json"]

# Body del login
	var body_dict = {
		"username": "user_1769592142695",
		"password": "tu_password"
	}
	var body_json = JSON.stringify(body_dict)

	# Enviar request POST
	var err = http_request.request(
		url,
		headers,
		HTTPClient.METHOD_POST,
		body_json
	)

	if err != OK:
		errores_login.text = "No se pudo enviar la solicitud"

func _on_http_request_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	var body_str = body.get_string_from_utf8()
	print("STATUS:", response_code)
	print("BODY:", body_str)
	
	if response_code != 200 and response_code != 201:
		errores_login.text = "Usuario o contraseña incorrectos"
		return

	var data = JSON.parse_string(body_str)
	if typeof(data) != TYPE_DICTIONARY or not data.has("sessionToken"):
		errores_login.text = "Respuesta inválida del servidor"
		return

	Session.token = data["sessionToken"]
	print("TOKEN GUARDADO:", Session.token)
	
	errores_login.text = "Sesión iniciada"
	await get_tree().create_timer(0.2).timeout
	get_tree().change_scene_to_file("res://Escenas/menú_sala.tscn")
