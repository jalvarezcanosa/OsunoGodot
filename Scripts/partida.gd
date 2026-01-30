extends Node2D
@onready var jugar_carta: HTTPRequest = $"Jugar Carta"
@onready var robar_carta: HTTPRequest = $"Robar Carta"
@onready var game_state: HTTPRequest = $"Game State"
@onready var estado_juego: Label = $"UI/UI usuario/Estado juego"

#var room_code := codigo_sala_unir.text.strip_edges()


var url_game_state : String = "http://127.0.0.1:8000/game/" + Session.room_code
# var url_robo := "http://127.0.0.1:8000/game/" + room_code + "/deck"
# var url_jugar_carta : String = "http://127.0.0.1:8000/game/" + room_code + "/play"

func _ready() -> void:
	var headers = [
		"Session: %s" % Session.token
		]
	var body_dict = {
	}
	var body_json = JSON.stringify(body_dict)
	var err = game_state.request(
		url_game_state,
		headers,
		HTTPClient.METHOD_POST,
		body_json
	)
	if err != OK:
		estado_juego.text = "No se pudo enviar la solicitud"

func _process(delta: float) -> void:
	pass


func _on_game_state_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	pass # Replace with function body.


func _on_robar_carta_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	pass # Replace with function body.


func _on_jugar_carta_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	pass # Replace with function body.
