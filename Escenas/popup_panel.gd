extends PopupPanel

@onready var username_label := $CanvasLayer/Usuario
@onready var games_won_label := $CanvasLayer/JuegosGanados
@onready var games_played_label := $CanvasLayer/JuegosJugados

func set_user_data(data: Dictionary):
	username_label.text = "Usuario: %s" % data["username"]
	games_won_label.text = "Partidas ganadas: %d" % data["gamesWon"]
	games_played_label.text = "Partidas jugadas: %d" % data["gamesPlayed"]
