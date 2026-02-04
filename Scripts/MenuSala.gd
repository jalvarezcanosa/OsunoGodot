extends Node2D
@onready var click_1: AudioStreamPlayer = $Click1
@onready var click_2: AudioStreamPlayer = $Click2
@onready var crear_sala: Button = $"Botonera/BotonesMenú/Crear Sala"
@onready var codigo_sala_crear: Label = $"Botonera/Código Sala Crear"
@onready var codigo_sala_unir: LineEdit = $"Botonera/BotonesMenú/Código Sala Unir"
@onready var post_crear_sala: HTTPRequest = $PostCrearSala
@onready var post_unir_sala: HTTPRequest = $PostUnirSala
@onready var get_estado_sala: HTTPRequest = $GetEstadoSala
@onready var room_status_timer: Timer = $Timer
var polling_en_curso: bool = false

var url_stats : String = "http://127.0.0.1:8000/users/me"
var url_crear_room : String = "http://127.0.0.1:8000/room"

func _ready() -> void:
	codigo_sala_crear.hide()
	post_crear_sala.request_completed.connect(_on_post_crear_sala_request_completed)
	get_estado_sala.request_completed.connect(_on_get_estado_sala_request_completed)

func _on_crear_sala_pressed() -> void:
	click_1.play()
	codigo_sala_crear.text = ""
	
	var headers = [
		"Content-Type: application/json",
		"Session: %s" % Session.token
	]	
	var body_dict = {
	}
	var body_json = JSON.stringify(body_dict)
	var err = post_crear_sala.request(
		url_crear_room,
		headers,
		HTTPClient.METHOD_POST,
		body_json
	)
	if err != OK:
		codigo_sala_crear.text = "No se pudo enviar la solicitud"
	codigo_sala_crear.show()

func _on_unirse_sala_pressed() -> void:
	codigo_sala_crear.hide()
	click_1.play()
	
	var room_code := codigo_sala_unir.text.strip_edges()
	var url_unir := url_crear_room + "/" + room_code
	
	var headers = [
		"Content-Type: application/json",
		"Session: %s" % Session.token
	]	
	var body_dict = {
	}
	var body_json = JSON.stringify(body_dict)
	var err = post_unir_sala.request(
		url_unir,
		headers,
		HTTPClient.METHOD_POST,
		body_json
	)

	
	if err != OK:
		codigo_sala_unir.text = "No se pudo enviar la solicitud"

func _on_volver_pressed() -> void:
	click_2.play()
	await get_tree().create_timer(0.2).timeout
	get_tree().change_scene_to_file("res://Escenas/menu_inicio.tscn")

func _on_post_crear_sala_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	var body_str = body.get_string_from_utf8()
	print("STATUS:", response_code)
	print("BODY:", body_str)

	if response_code != 200 and response_code != 201:
		codigo_sala_crear.text = "Usuario o contraseña incorrectos"
		return

	var data = JSON.parse_string(body_str)
	if data == null:
		codigo_sala_crear.text = "Respuesta inválida del servidor"
		return
		
	codigo_sala_crear.text = data ["roomCode"]
	Session.room_code = codigo_sala_crear.text.strip_edges()
	room_status_timer.start()
	
func _on_post_unir_sala_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	var body_str = body.get_string_from_utf8()
	print("STATUS:", response_code)
	print("BODY:", body_str)
	
	if response_code != 200:
		if response_code == 404:
			codigo_sala_unir.text = "Sala no encontrada"
		elif response_code == 400:
			codigo_sala_unir.text = "No te puedes unir a tu propia sala"
		elif response_code == 409:
			codigo_sala_unir.text = "Sala llena"
		elif response_code == 401:
			codigo_sala_unir.text = "Sesión inválida"
		else:
			codigo_sala_unir.text = "Error al unirse a la sala"
		return
	var data = JSON.parse_string(body_str)
	
	if data == null:
		codigo_sala_unir.text = "Respuesta inválida del servidor"
		return
		
	Session.room_code = codigo_sala_unir.text.strip_edges()
	print("Room code guardado:", Session.room_code)
	
	codigo_sala_unir.text = "Sesión iniciada"
	room_status_timer.start()


func _on_get_estado_sala_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code != 200:
		return
	polling_en_curso = false
	var body_str := body.get_string_from_utf8()
	var data : Dictionary = JSON.parse_string(body_str)
	if data == null:
		return

	if not data.has("status"):
		return

	if data["status"] == "gameStarted":
		room_status_timer.stop()
		get_tree().change_scene_to_file("res://Escenas/partida.tscn")

func _on_timer_timeout() -> void:
	if Session.room_code == "":
		return

	if polling_en_curso:
		return

	var url_roomstatus := url_crear_room + "/" + Session.room_code

	var headers = [
		"Content-Type: application/json",
		"Session: %s" % Session.token
	]
	
	polling_en_curso = true

	get_estado_sala.request(
		url_roomstatus,
		headers,
		HTTPClient.METHOD_GET
	)
