extends Node2D

@onready var game_state: HTTPRequest = $"Game State"
@onready var mano_jugador: GridContainer = $"Cartas usuario"
@onready var estado_juego: Label = $"UI/Estado juego"
@onready var carta_mesa: Label = $"UI/CartaMesa(temporal)"
@onready var timer: Timer = $Timer
@onready var label_mias: Label = $"UI/LabelMisCartas"
@onready var label_rival: Label = $"UI/LabelCartasRival"
@onready var label_mazo: Label = $"UI/LabelMazo"

const TOTAL_CARTAS := 76
const CARTAS_INICIALES := 7

var card_scene = preload("res://Escenas/Card.tscn")
var url_game_state := "http://127.0.0.1:8000/game/" + Session.room_code

func update_counters(data: Dictionary) -> void:
	var mis_cartas : int = data["yourHand"].size()
	var mazo : int = data["deckCount"]

	var cartas_en_mesa := 1
	var rival : int = TOTAL_CARTAS - mis_cartas - mazo - cartas_en_mesa

	label_mias.text = "Tus cartas: %d" % mis_cartas
	label_rival.text = "Rival: %d" % max(rival, 0)
	label_mazo.text = "Mazo: %d" % mazo

func _ready() -> void:
	timer.timeout.connect(_on_timer_timeout)
	game_state.request_completed.connect(_on_game_state_request_completed)

	# Primera llamada inmediata
	request_game_state()

	# Empezar polling
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
	estado_juego.text = "Tu turno: %s | Cartas en mazo: %d" % [
		str(data["isYourTurn"]),
	]

	carta_mesa.text = "Carta en mesa: " + data["tableCard"]

	# Limpiar mano
	for child in mano_jugador.get_children():
		child.queue_free()

	# Crear cartas
	for carta in data["yourHand"]:
		var card = card_scene.instantiate()   # Button
		card.set_codigo(carta)
		mano_jugador.add_child(card)
	update_counters(data)
