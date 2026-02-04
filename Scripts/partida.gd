extends Node2D

const CARD = preload("uid://ccpeukrdsfbkm")


@onready var jugar_carta_req: HTTPRequest = $"Jugar Carta"
@onready var game_state: HTTPRequest = $"Game State"
@onready var mano_jugador: GridContainer = $"Cartas usuario"
@onready var mano_rival: GridContainer = $"Cartas rival"
@onready var estado_juego: Label = $"UI/Estado juego"
@onready var carta_mesa: Label = $"UI/CartaMesa(temporal)"
@onready var timer: Timer = $Timer
@onready var drop_zone: Area2D = $DropZone

var last_hand: Array = []
var rival_cards: int = 0

var card_scene = preload("res://Escenas/Card.tscn")
var url_game_state := "http://127.0.0.1:8000/game/" + Session.room_code
var carta_en_dropzone: Node = null

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

	estado_juego.text = "Tu turno: %s" % [
		str(data["isYourTurn"]),
	]

	carta_mesa.text = "Carta en mesa: " + data["tableCard"]

	var new_hand: Array = data["yourHand"]
	if new_hand != last_hand:
		last_hand = new_hand.duplicate()
		_update_hand(new_hand)

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
		

func _update_hand(hand: Array) -> void:
	for child in mano_jugador.get_children():
		child.queue_free()

	for carta in hand:
		var card = card_scene.instantiate()
		card.set_codigo(carta)
		
		card.carta_soltada.connect(_on_carta_mazo_carta_soltada)
		mano_jugador.add_child(card)
		
		
func _on_drop_zone_area_entered(area: Area2D) -> void:
	var carta = area.get_parent()
	if carta.has_method("set_codigo"):
		carta_en_dropzone = carta
		print("Carta sobre dropzone: ", carta.card_code)


func _on_drop_zone_area_exited(area: Area2D) -> void:
	var carta = area.get_parent()
	if carta_en_dropzone == carta:
		carta_en_dropzone = null
		print("Carta salió de dropzone")


func enviar_jugada_backend(card_code: String) -> void:
	var url = url_game_state + "/play"
	var headers = [
		"Content-Type: application/json",
		"Session: %s" % Session.token
	]
	var body = JSON.stringify({
		"cardToPlay": card_code
	})
	jugar_carta_req.request(url, headers, HTTPClient.METHOD_POST, body)

func _on_jugar_carta_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code == 201: 
		print("Carta jugada con éxito")
		request_game_state()
	else:
		var resp = body.get_string_from_utf8()
		print("Error al jugar carta: ", resp)
		

func _on_carta_mazo_carta_soltada(card: Variant) -> void:
	if carta_en_dropzone == card:
		print("Jugando carta: ", card.card_code)
		enviar_jugada_backend(card.card_code)
	else:
		print("Carta soltada fuera de la zona") 
