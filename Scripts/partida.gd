extends Node2D
@onready var game_state: HTTPRequest = $"Game State"
@onready var mano_jugador: GridContainer = $"Cartas usuario"
@onready var estado_juego: Label = $"UI/Estado juego"
@onready var carta_mesa: Label = $"UI/CartaMesa(temporal)"
@onready var timer: Timer = $Timer
@onready var http_draw_card = $"POST robar"
@onready var boton_robar = $UI/Robar

var card_scene = preload("res://Escenas/Card.tscn")
var url_game_state := "http://127.0.0.1:8000/game/" + Session.room_code
var url_draw_card := "http://127.0.0.1:8000/game/%s/deck" % Session.room_code
var is_my_turn: bool = true
	
func _ready() -> void:
	timer.timeout.connect(_on_timer_timeout)
	game_state.request_completed.connect(_on_game_state_request_completed)
	http_draw_card.request_completed.connect(_on_draw_card_completed)
	boton_robar.pressed.connect(robar_carta)
	request_game_state()
	timer.start()

func _on_timer_timeout() -> void:
	request_game_state()

func request_game_state() -> void:
	var headers = [
		"Session: %s" % Session.token
	]
	var err = game_state.request(
		url_game_state,
		headers,
		HTTPClient.METHOD_GET
	)
	if err != OK:
		print("Error al pedir game state")

func _on_game_state_request_completed(
	result: int,
	response_code: int,
	headers: PackedStringArray,
	body: PackedByteArray
) -> void:
	if response_code != 200:
		print("Game state error:", response_code)
		return
	var body_str = body.get_string_from_utf8()
	var data = JSON.parse_string(body_str)
	if data == null:
		print("JSON inválido")
		return
	update_ui(data)

func update_ui(data: Dictionary) -> void:
	is_my_turn = data["isYourTurn"]
	estado_juego.text = "Tu turno: %s | Cartas en mazo: %d" % [
		str(data["isYourTurn"]),
	]
	carta_mesa.text = "Carta en mesa: " + data["tableCard"]
	for child in mano_jugador.get_children():
		child.queue_free()
	for carta in data["yourHand"]:
		var card = card_scene.instantiate()
		card.set_codigo(carta)
		mano_jugador.add_child(card)

func robar_carta() -> void:
	var headers = [
		"Content-Type: application/json",
		"Session: %s" % Session.token
	]
	var err = http_draw_card.request(url_draw_card, headers, HTTPClient.METHOD_POST, "")
	if err != OK:
		push_error("Error al enviar petición de robar carta: " + str(err))

func _on_draw_card_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	var body_str = body.get_string_from_utf8()
	print("ROBAR CARTA - STATUS:", response_code)
	print("ROBAR CARTA - BODY:", body_str)
	
	if response_code == 200:
		print("Carta robada correctamente")
		request_game_state()
		
	elif response_code == 403:
		var data = JSON.parse_string(body_str)
		if data and data.has("error"):
			print("Error: ", data["error"])
		else:
			print("No se puede robar carta (mazo vacío o no es tu turno)")
	
	else:
		print("Error al robar carta. Código: ", response_code)


func _on_robar_pressed() -> void:
	robar_carta()
