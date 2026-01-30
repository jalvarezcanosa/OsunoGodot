extends Control

@onready var usuario_LineEdit = $line_edit_usuario
@onready var contrasenha_LineEdit = $line_edit_contrasenha
@onready var confirmar_contrasenha_LineEdit = $line_edit_confirmar_usuario
@onready var boton_registrar = $Boton_Registro
@onready var boton_volver_login = $Boton_volver_login

# URLs de la API Django
const BASE_URL = "http://127.0.0.1:8000"  # AJUSTA ESTA URL
const REGISTER_URL = BASE_URL + "/users"  # path('users', endpoints.create_user)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	boton_registrar.connect("pressed", _boton_registro_presionado)
	boton_volver_login.connect("pressed", _boton_volver_login_presionado)
	
	# Opcional: Conectar para validar en tiempo real
	contrasenha_LineEdit.text_changed.connect(_validar_contrasenhas)
	confirmar_contrasenha_LineEdit.text_changed.connect(_validar_contrasenhas)
	
	# Limpiar mensajes de error al inicio
	_limpiar_mensaje_error()

func _boton_registro_presionado():
	# Obtener valores de los campos
	var usuario = usuario_LineEdit.text.strip_edges()
	var contrasenha = contrasenha_LineEdit.text
	var confirmar_contrasenha = confirmar_contrasenha_LineEdit.text
	
	# Limpiar mensajes de error previos
	_limpiar_mensaje_error()
	
	print("=== INTENTANDO REGISTRO ===")
	print("Usuario:", usuario)
	
	# Validaciones locales antes de enviar al servidor
	if not _validar_campos(usuario, contrasenha, confirmar_contrasenha):
		return
	
	# Crear datos según lo que espera Django create_user()
	var datos_registro = {
		"username": usuario,      # Django espera 'username' según tu modelo
		"password": contrasenha   # Django espera 'password'
	}
	

	
	# Enviar petición HTTP de registro
	_enviar_peticion_registro(datos_registro)

func _validar_campos(usuario: String, contrasenha: String, confirmar_contrasenha: String) -> bool:
	# Validar usuario no vacío
	if usuario == "":
		_mostrar_error("El nombre de usuario es requerido")
		return false
	
	# Validar longitud de usuario (opcional, según tu modelo)
	if usuario.length() < 3:
		_mostrar_error("El usuario debe tener al menos 3 caracteres")
		return false
	
	if usuario.length() > 30:  # Según tu modelo: max_length=30
		_mostrar_error("El usuario no puede tener más de 30 caracteres")
		return false
	
	# Validar que la contraseña no esté vacía
	if contrasenha == "":
		_mostrar_error("La contraseña es requerida")
		return false
	
	# Validar longitud mínima de contraseña (recomendado)
	if contrasenha.length() < 6:
		_mostrar_error("La contraseña debe tener al menos 6 caracteres")
		return false
	
	# Validar que las contraseñas coincidan
	if contrasenha != confirmar_contrasenha:
		_mostrar_error("Las contraseñas no coinciden")
		return false
	return true
	
func _validar_contrasenhas(new_text: String = ""):
	# Validación en tiempo real mientras el usuario escribe
	var contrasenha = contrasenha_LineEdit.text
	var confirmar = confirmar_contrasenha_LineEdit.text
	
	if contrasenha != "" and confirmar != "" and contrasenha != confirmar:
		# Puedes mostrar un mensaje suave o cambiar el color del borde
		# Por ejemplo, cambiar el color del LineEdit
		confirmar_contrasenha_LineEdit.add_theme_color_override("font_color", Color(1, 0.2, 0.2))
	else:
		confirmar_contrasenha_LineEdit.remove_theme_color_override("font_color")

func _enviar_peticion_registro(datos: Dictionary):
	# Crear petición HTTP
	var http_request = HTTPRequest.new()
	add_child(http_request)
	
	# Conectar señal para recibir respuesta
	http_request.request_completed.connect(_on_registro_completado.bind(http_request))
	
	# Convertir datos a JSON
	var json_string = JSON.stringify(datos)
	
	# Configurar headers
	var headers = ["Content-Type: application/json"]
	
	print("Enviando POST a:", REGISTER_URL)
	print("Datos:", json_string)
	
	# Enviar petición POST
	var error = http_request.request(REGISTER_URL, headers, HTTPClient.METHOD_POST, json_string)
	
	if error != OK:
		
		_mostrar_error("Error al crear la petición HTTP: " + str(error))
		http_request.queue_free()

func _on_registro_completado(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray, http_request: HTTPRequest):
	# Limpiar nodo HTTPRequest
	http_request.queue_free()
	
	
	print("=== RESPUESTA REGISTRO ===")
	print("Código:", response_code)
	
	# Verificar conexión
	if result != HTTPRequest.RESULT_SUCCESS:
		_mostrar_error("Error de conexión con el servidor")
		print("Asegúrate de que Django esté corriendo en:", BASE_URL)
		return
	
	# Convertir respuesta
	var response_body = body.get_string_from_utf8()
	print("Respuesta:", response_body)
	
	# Procesar según código de respuesta
	match response_code:
		201:  # Registro exitoso - 201 Created según tu endpoint
			_procesar_registro_exitoso(response_body)
		400:  # Bad Request - parámetros faltantes/mal formados
			_mostrar_error("Error: Faltan parámetros o están mal formados")
			print("Respuesta:", response_body)
		409:  # Conflict - usuario ya existe
			_mostrar_error("El nombre de usuario ya está en uso")
		405:  # Method Not Allowed
			_mostrar_error("Error del servidor: Método no permitido")
		500:  # Internal Server Error
			_mostrar_error("Error interno del servidor")
			print("Respuesta del servidor:", response_body)
		_:
			_mostrar_error("Error desconocido: Código " + str(response_code))
			print("Respuesta completa:", response_body)

func _procesar_registro_exitoso(response_body: String):
	# Parsear JSON
	var json = JSON.new()
	var parse_error = json.parse(response_body)
	
	if parse_error != OK:
		_mostrar_error("Error al procesar respuesta del servidor")
		print("Error parse JSON:", json.get_error_message())
		return
	
	var respuesta = json.get_data()
	print("Registro exitoso. Respuesta:", respuesta)
	
	# Verificar estructura de respuesta según tu endpoint create_user()
	# En tu Django: return JsonResponse({"success": True, "username": username}, status=201)
	
	var success = respuesta.get("success", false)
	var username = respuesta.get("username", "")
	
	if success and username != "":
		print("¡REGISTRO EXITOSO!")
		print("Usuario creado:", username)
		
		# Mostrar mensaje de éxito
		_mostrar_exito("¡Usuario registrado exitosamente!")
		
		# Opción 1: Limpiar campos y mostrar mensaje
		_limpiar_campos()
	else:
		print("ERROR: Respuesta inesperada del servidor")
		print("Respuesta completa:", respuesta)
		_mostrar_error("Error en la respuesta del servidor")
		
func _mostrar_error(mensaje: String):
	print("ERROR:", mensaje)
func _mostrar_exito(mensaje: String):
	print("ÉXITO:", mensaje)
func _limpiar_mensaje_error():
	pass

func _limpiar_campos():
	usuario_LineEdit.text = ""
	contrasenha_LineEdit.text = ""
	confirmar_contrasenha_LineEdit.text = ""
	confirmar_contrasenha_LineEdit.remove_theme_color_override("font_color")
func _boton_volver_login_presionado():
	print("Volviendo a la pantalla de login...")
	# Cambiar a la escena de login
	# Ajusta la ruta según tu proyecto
	get_tree().change_scene_to_file("res://login.tscn")

	
