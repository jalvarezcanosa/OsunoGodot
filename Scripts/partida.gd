extends Node2D

@onready var jugar_carta_req: HTTPRequest = $"Jugar Carta"
@onready var game_state: HTTPRequest = $"Game State"
@onready var mano_jugador: GridContainer = $"Cartas usuario"
@onready var mano_rival: GridContainer = $"Cartas rival"
@onready var estado_juego: Label = $"UI/Estado juego"
@onready var carta_mesa: Label = $"UI/CartaMesa(temporal)"
@onready var timer: Timer = $Timer
@onready var drop_zone: Area2D = $DropZone

# robar carta
@onready var http_draw_card = $"POST robar"
@onready var boton_robar = $UI/Robar

var last_hand: Array = []
var rival_cards: int = 0
var card_scene = preload("res://Escenas/Card.tscn")
var url_game_state := "http://127.0.0.1:8000/game/" + Session.room_code
var url_draw_card := "http://127.0.0.1:8000/game/%s/deck" % Session.room_code
var carta_en_dropzone: Node = null
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
	var headers = ["Session: %s" % Session.token]
	var err = game_state.request(url_game_state, headers, HTTPClient.METHOD_GET)
	if err != OK:
		print("Error al pedir game state")

func _on_game_state_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code != 200:
		print("Game state error:", response_code)
		return
		
	var body_str = body.get_string_from_utf8()
	var data = JSON.parse_string(body_str)
	if data == null:
		print("JSON inválido")
		return
	
	# comprobar si la partida terminó
	if data.has("gameFinished"):
		match data["gameFinished"]:
			"youWon":
				print("¡Victoria!")
				get_tree().change_scene_to_file("res://Escenas/victory_screen.tscn")
				return
			"youLost":
				print("Derrota")
				get_tree().change_scene_to_file("res://Escenas/lose_screen.tscn")
				return
			_:
				pass  # otros estados si se dan

	# Si seguimos aquí, la partida sigue
	update_ui(data)

# Actualizar interfaz
func update_ui(data: Dictionary) -> void:
	if Session.is_dragging_card:
		return

	is_my_turn = data["isYourTurn"]
	estado_juego.text = "Tu turno: %s | Cartas en mazo: %d" % [str(data["isYourTurn"]), data.get("cardsLeftInDeck", 0)]
	carta_mesa.text = "Carta en mesa: " + data["tableCard"]

	# Cartas del jugador
	var new_hand: Array = data["yourHand"]
	if new_hand != last_hand:
		last_hand = new_hand.duplicate()
		_update_hand(new_hand)

	# Cartas del rival
	for child in mano_rival.get_children():
		child.queue_free()
		
	var rival_hand = data.get("rivalHand", [])	
	for carta in rival_hand:
		var card = card_scene.instantiate()
		card.set_rival()
		mano_rival.add_child(card)

func _update_hand(hand: Array) -> void:
	for child in mano_jugador.get_children():
		child.queue_free()
	for carta in hand:
		var card = card_scene.instantiate()
		card.set_codigo(carta)
		card.carta_soltada.connect(_on_carta_mazo_carta_soltada)
		mano_jugador.add_child(card)

# Arrastre y soltar
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
	var headers = ["Content-Type: application/json", "Session: %s" % Session.token]
	var body = JSON.stringify({"cardToPlay": card_code})
	jugar_carta_req.request(url, headers, HTTPClient.METHOD_POST, body)

func _on_jugar_carta_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code == 201: 
		print("Carta jugada con éxito")
		request_game_state()
	else:
		print("Error al jugar carta: ", body.get_string_from_utf8())

func _on_carta_mazo_carta_soltada(card: Variant) -> void:
	if carta_en_dropzone == card:
		print("Jugando carta: ", card.card_code)
		enviar_jugada_backend(card.card_code)
	else:
		print("Carta soltada fuera de la zona") 

# Robar carta
func robar_carta() -> void:
	if not is_my_turn:
		estado_juego.text = ("No es tu turno, no puedes robar carta")
		return
	var headers = ["Content-Type: application/json", "Session: %s" % Session.token]
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
	elif response_code == 201:
		request_game_state()
	else:
		print("Error al robar carta. Código: ", response_code)

	# Revisar si la partida ha terminado al robar
	var data = JSON.parse_string(body_str)
	if data and data.has("gameFinished"):
		match data["gameFinished"]:
			"youWon":
				print("¡Victoria!")
				get_tree().change_scene_to_file("res://Escenas/victory_screen.tscn")
				return
			"youLost":
				print("Derrota")
				get_tree().change_scene_to_file("res://Escenas/lose_screen.tscn")
				return
