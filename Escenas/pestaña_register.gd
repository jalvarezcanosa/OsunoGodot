extends Control
@onready var http = $HTTPRequest
@onready var confirmar_input: LineEdit = $CanvasLayer/VBoxContainer/confir
@onready var contrasenha_input: LineEdit = $CanvasLayer/VBoxContainer/con
@onready var usuario_input: LineEdit = $CanvasLayer/VBoxContainer/usuario
@onready var boton_registrar: Button = $CanvasLayer/VBoxContainer/Reg
@onready var boton_volver: Button = $CanvasLayer/VBoxContainer/volver
@onready var error: Label = $CanvasLayer/Error

const SERVER_URL = "http://127.0.0.1:8000"
const REGISTER_URL = SERVER_URL + "/users"

func _ready():
	boton_registrar.pressed.connect(_boton_registro_presionado)
	boton_volver.pressed.connect(_boton_volver_login_presionado)

	# Conectar validación en tiempo real
	contrasenha_input.text_changed.connect(_validar_contrasenhas)
	confirmar_input.text_changed.connect(_validar_contrasenhas)

func _boton_registro_presionado():
	var usuario = usuario_input.text.strip_edges()
	var contrasenha = contrasenha_input.text
	var confirmar_contrasenha = confirmar_input.text

	print("=== INTENTANDO REGISTRO ===")
	print("Usuario:", usuario)

	if not _validar_campos(usuario, contrasenha, confirmar_contrasenha):
		return

	var datos_registro = {
		"username": usuario,
		"password": contrasenha
	}

	_enviar_peticion_registro(datos_registro)

func _validar_campos(usuario: String, contrasenha: String, confirmar_contrasenha: String) -> bool:
	if usuario == "":
		error.text = ("El nombre de usuario es requerido")
		return false

	if usuario.length() < 3:
		error.text = ("El usuario debe tener al menos 3 caracteres")
		return false

	if usuario.length() > 30:
		error.text = ("El usuario no puede tener más de 30 caracteres")
		return false

	if contrasenha == "":
		error.text = ("La contraseña es requerida")
		return false

	if contrasenha.length() < 1:
		error.text = ("La contraseña debe tener al menos 6 caracteres")
		return false

	if contrasenha != confirmar_contrasenha:
		error.text = ("Las contraseñas no coinciden")
		return false
	
	return true

func _validar_contrasenhas(new_text: String = ""):
	var contrasenha = contrasenha_input.text
	var confirmar = confirmar_input.text

	if contrasenha != "" and confirmar != "" and contrasenha != confirmar:
		confirmar_input.add_theme_color_override("font_color", Color(1, 0.2, 0.2))
	else:
		confirmar_input.remove_theme_color_override("font_color")

func _enviar_peticion_registro(datos: Dictionary):
	var json_string = JSON.stringify(datos)
	var headers = ["Content-Type: application/json"]

	print("Enviando POST a:", REGISTER_URL)
	print("Datos:", json_string)

	if not http.request_completed.is_connected(_on_registro_completado):
		http.request_completed.connect(_on_registro_completado)
	
	var error = http.request(REGISTER_URL, headers, HTTPClient.METHOD_POST, json_string)

	if error != OK:
		_mostrar_error("Error al crear la petición HTTP: " + str(error))

func _on_registro_completado(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	print("=== RESPUESTA REGISTRO ===")
	print("Código:", response_code)

	if result != HTTPRequest.RESULT_SUCCESS:
		error.text = ("Error de conexión con el servidor")
		print("Asegúrate de que Django esté corriendo en:", SERVER_URL)
		return

	var response_body = body.get_string_from_utf8()
	print("Respuesta:", response_body)

	match response_code:
		201:  # Registro exitoso
			_procesar_registro_exitoso(response_body)
		400:  # Bad Request
			error.text = ("Error: Faltan parámetros o están mal formados")
			print("Respuesta:", response_body)
		409:  # Conflict
			error.text = ("El nombre de usuario ya está en uso")
		405:  # Method Not Allowed
			error.text = ("Error del servidor: Método no permitido")
		_:  # Otros códigos
			error.text = ("Error del servidor: código " + str(response_code))
			print("Respuesta completa:", response_body)

func _procesar_registro_exitoso(response_body: String):
	var json = JSON.new()
	var parse_error = json.parse(response_body)
	
	if parse_error != OK:
		error.text = ("Error al procesar respuesta del servidor")
		return
	
	var respuesta = json.get_data()
	print("Registro exitoso. Respuesta:", respuesta)

	var success = respuesta.get("success", false)
	var username = respuesta.get("username", "")

	if success and username != "":
		print("¡REGISTRO EXITOSO!")
		error.text = "Usuario creado: " + str(username)
		_mostrar_exito("¡Usuario registrado exitosamente!")
		_limpiar_campos()
		
		# Volver al login después de 2 segundos
		await get_tree().create_timer(2.0).timeout
		_boton_volver_login_presionado()
	else:
		print("ERROR: Respuesta inesperada del servidor")
		print("Respuesta completa:", respuesta)
		_mostrar_error("Error en la respuesta del servidor")
		
func _mostrar_error(mensaje: String):
	print("ERROR:", mensaje)


func _mostrar_exito(mensaje: String):
	print("ÉXITO:", mensaje)


func _limpiar_campos():
	usuario_input.text = ""
	contrasenha_input.text = ""
	confirmar_input.text = ""
	confirmar_input.remove_theme_color_override("font_color")

func _boton_volver_login_presionado():
	print("Volviendo a la pantalla de login...")
	get_tree().change_scene_to_file("res://Escenas/menu_inicio.tscn")
