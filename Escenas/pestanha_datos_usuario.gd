extends Control

@onready var http := $HTTPRequest
@onready var popup := $PopupPanel
var user_data := {}

func _ready():
	http.request_completed.connect(_on_request_completed)

func get_user_data():
	var url = "http://127.0.0.1:8000/users/me"
	var headers = [
		"Session: " + Session.token,
		"Content-Type: application/json"
	]
	
	print("Solicitando datos de usuario...")
	var err = http.request(url, headers, HTTPClient.METHOD_GET)
	
	if err != OK:
		push_error("Error al crear petición HTTP: " + str(err))

func _on_request_completed(result, response_code, headers, body):
	print("=== RESPUESTA USER DATA ===")
	print("Código:", response_code)
	
	if response_code != 200:
		print("Error al obtener usuario. Código:", response_code)
		return
	
	var body_str = body.get_string_from_utf8()
	print("Body:", body_str)
	
	var json = JSON.parse_string(body_str)
	if json == null:
		print("JSON inválido")
		return
	
	user_data = json
	print("Datos guardados:", user_data)
	
	# Mostrar el popup automáticamente después de obtener los datos
	show_user_popup()

func show_user_popup():
	if user_data.is_empty():
		print("No hay datos para mostrar")
		return
	
	popup.set_user_data(user_data)
	popup.show_popup()

func _on_ver_datos_pressed() -> void:
	# Toggle: si está visible, ocultar; si no, mostrar
	if popup.visible:
		popup.hide()
	else:
		# Si no hay datos, obtenerlos primero
		if user_data.is_empty():
			get_user_data()
			# El popup se mostrará automáticamente en _on_request_completed
		else:
			# Si ya hay datos, mostrar directamente
			show_user_popup()
