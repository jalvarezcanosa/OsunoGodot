extends Control

@onready var http :=  $HTTPRequest
@onready var popup := $PopupPanel
var user_data := {}

func _ready():
	http.request_completed.connect(_on_request_completed)
	get_user_data()

func get_user_data():
	var url = "http://127.0.0.1:8000/users/me"
	var headers = [
		"Session: ", Session.token,
        "Content-Type: aplication/json"
	]
	http.request(url, headers)

func _on_request_completed(result, response_code, headers, body):
	if response_code != 200:
		print("Error al obtener usuario:", response_code)
		return

	var json = JSON.parse_string(body.get_string_from_utf8())
	if json == null:
		print("JSON inválido")
		return

	user_data = json
	show_user_popup()
	
func show_user_popup():
	popup.set_user_data(user_data)
	popup.popup_centered()
	
func _on_close_button_pressed():
	hide()

func _on_ver_datos_pressed() -> void:
	if popup.visible:
		popup.hide()
	else:
		# Si aún no hay datos, obtenerlos primero
		if user_data.is_empty():
			get_user_data()
			# Esperar a que se complete la petición
			await http.request_completed
		show_user_popup()
