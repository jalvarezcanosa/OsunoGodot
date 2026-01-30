extends Node2D
@onready var jugar_carta: HTTPRequest = $"Jugar Carta"
@onready var robar_carta: HTTPRequest = $"Robar Carta"
@onready var game_state: HTTPRequest = $"Game State"
#var room_code := codigo_sala_unir.text.strip_edges()
	#Session.token = data["sessionToken"]
	#print("TOKEN GUARDADO:", Session.room_code)
# var url_game_state : String = "http://127.0.0.1:8000/game/" + room_code
# var url_robo := "http://127.0.0.1:8000/game/" + room_code + "/deck"
# var url_game_state : String = "http://127.0.0.1:8000/game/" + room_code + "/play"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
