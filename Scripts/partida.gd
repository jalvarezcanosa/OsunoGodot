extends Node2D

const CARD = preload("uid://ccpeukrdsfbkm")


@onready var game_state: HTTPRequest = $"Game State"
@onready var mano_jugador: GridContainer = $"Cartas usuario"
@onready var mano_rival: GridContainer = $"Cartas rival"
@onready var estado_juego: Label = $"UI/Estado juego"
@onready var carta_mesa: Label = $"UI/CartaMesa(temporal)"
@onready var timer: Timer = $Timer

var last_hand: Array = []
var rival_cards: int = 0

var card_scene = preload("res://Escenas/Card.tscn")
var url_game_state := "http://127.0.0.1:8000/game/" + Session.room_code



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


func _on_game_state_request_completed(result: int,response_code: int,headers: PackedStringArray,body: PackedByteArray) -> void:

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
	if Session.is_dragging_card:
		return

	estado_juego.text = "Tu turno: %s | Cartas en mazo: %d" % [
		str(data["isYourTurn"]),
	]

	carta_mesa.text = "Carta en mesa: " + data["tableCard"]

	var new_hand: Array = data["yourHand"]
	if new_hand == last_hand:
		return
		
	last_hand = new_hand.duplicate()
	_update_hand(new_hand)
		
	# Limpiar mano
	for child in mano_jugador.get_children():
		child.queue_free()

	# --- CARTAS RIVAL ---
	for child in mano_rival.get_children():
		child.queue_free()

	# --- CALCULO CARTAS RIVAL ---
	rival_cards = 7 * 2                # total inicial (2 jugadores, 7 cartas cada uno)
	rival_cards -= data["yourHand"].size()
	rival_cards -= data["cardsLeftInDeck"]
	rival_cards -= 1  # carta en mesa
	
	for i in rival_cards:
		var card = card_scene.instantiate()
		card.set_rival()
		card.text = "??" # MVP
		mano_rival.add_child(card)
	# Crear cartas
	for carta in data["yourHand"]:
		var card = card_scene.instantiate()   # Button
		card.set_codigo(carta)
		mano_jugador.add_child(card)

func _update_hand(hand: Array) -> void:
	for child in mano_jugador.get_children():
		child.queue_free()

	for carta in hand:
		var card = card_scene.instantiate()
		card.set_codigo(carta)
		mano_jugador.add_child(card)
