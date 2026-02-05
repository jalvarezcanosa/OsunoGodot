extends PopupPanel

@onready var username_label: Label = $CanvasLayer/VBoxContainer/Usuario
@onready var games_won_label: Label = $CanvasLayer/VBoxContainer/JuegosGanados
@onready var games_played_label: Label = $CanvasLayer/VBoxContainer/JuegosJugados
@onready var rango: Label = $CanvasLayer/VBoxContainer/Rango

# Variable para guardar la posición inicial del editor
var saved_position: Vector2i

func _ready():
	# Guardar la posición configurada en el editor (1400, 200)
	saved_position = position
	hide()  # Empezar oculto

func set_user_data(data: Dictionary):
	print("=== SET USER DATA ===")
	print("Datos recibidos:", data)
	
	# Verificar que existen las claves antes de acceder
	if not data.has("username") or not data.has("gamesWon") or not data.has("gamesPlayed"):
		push_error("Faltan claves en los datos del usuario")
		username_label.text = "Error: datos incompletos"
		return
	
	username_label.text = "Usuario: %s" % data["username"]
	games_won_label.text = "Partidas ganadas: %d" % data["gamesWon"]
	games_played_label.text = "Partidas jugadas: %d" % data["gamesPlayed"]
	
	if data["gamesWon"] <= 0:
		rango.text = "Rango: Sin clasificar"
		return

	var ratio := float(data["gamesPlayed"]) / float(data["gamesWon"])

	if ratio <= 2:
		rango.text = "Rango: Diamante"
	elif ratio <= 5:
		rango.text = "Rango: Dorado"
	elif ratio <= 10:
		rango.text = "Rango: Plata"
	else:
		rango.text = "Rango: Bronce"

func show_popup():
	# Restaurar la posición original (1400, 200) antes de mostrar
	position = saved_position
	show()
