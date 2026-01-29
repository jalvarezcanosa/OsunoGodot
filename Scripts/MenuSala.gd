extends Node2D
@onready var codigo_sala_unir: LineEdit = $"Botonera/BotonesMenú/Crear Sala/Código Sala Unir"
@onready var codigo_sala_crear: Label = $"Botonera/BotonesMenú/Unirse Sala/Código Sala Crear"
@onready var click_1: AudioStreamPlayer = $Click1
@onready var click_2: AudioStreamPlayer = $Click2
@onready var http_request: HTTPRequest = $HTTPRequest
@onready var crear_sala: Button = $"Botonera/BotonesMenú/Crear Sala"

var url := "http://localhost:8000/room"

func _ready() -> void:
	codigo_sala_crear.hide()
	codigo_sala_unir.hide()
#func _on_jugar_pressed() -> void:
	#get_tree().change_scene_to_file("res://Escenas/Partida.tscn")

func _on_crear_sala_pressed() -> void:
	click_1.play()
	codigo_sala_crear.text = ""

	var headers = ["Content-Type: application/json"]

	var body_dict = {
	}

	var body_json = JSON.stringify(body_dict)

	var err = http_request.request(
		url,
		headers,
		HTTPClient.METHOD_POST,
		body_json
	)

	if err != OK:
		codigo_sala_crear.text = "No se pudo enviar la solicitud"

	codigo_sala_crear.show()
	codigo_sala_unir.hide()

func _on_unirse_sala_pressed() -> void:
	codigo_sala_crear.hide()
	codigo_sala_unir.show()
	click_1.play()
func _on_volver_pressed() -> void:
	click_2.play()
	await get_tree().create_timer(0.2).timeout
	get_tree().change_scene_to_file("res://Escenas/menu_inicio.tscn")

func _on_http_request_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	var body_str = body.get_string_from_utf8()
	print("STATUS:", response_code)
	print("BODY:", body_str)

	if response_code != 200:
		codigo_sala_crear.text = "Usuario o contraseña incorrectos"
		return

	var data = JSON.parse_string(body_str)
	if data == null:
		codigo_sala_crear.text = "Respuesta inválida del servidor"
		return

	var token = data["token"]
	get_tree().change_scene_to_file("res://Escenas/partida.tscn")
