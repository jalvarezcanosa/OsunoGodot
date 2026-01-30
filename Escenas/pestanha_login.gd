extends Control
@onready var usuario_LineEdit = $Etrada_usuario
@onready var contrasenha_LineEdit = $Entrada_contrasenha
@onready var boton_envio = $Enviar
@onready var boton_registro = $Registrarse
var usuario = ""
var contrasenha = ""
#Urls de la Api
const BASE_URL = "http://127.0.0.1:8000"
const LOGIN_URL = BASE_URL + "/sessions"

#token de sesion del servidor
var session_token = ""




# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	boton_envio.connect("pressed", _boton_login_presionado)
	contrasenha_LineEdit.connect("text_changed", _on_contrasenha_changed)
	usuario_LineEdit.connect("text_changed", _on_usuario_changed)
	boton_registro.connect("pressed", _boton_registro_presionado)
	pass # Replace with function body.

func _on_usuario_changed(new_text: String):
	usuario = new_text
	print("Texto cambiado: ", usuario)
func _on_contrasenha_changed(new_text: String):
	contrasenha = new_text
	print("Texto cambiado: ", contrasenha)

func _boton_login_presionado():
	print(usuario)
	usuario = usuario_LineEdit.text.strip_edges()
	print(contrasenha)
	contrasenha = contrasenha_LineEdit.text.strip_edges()
	
	print("Intentando login para usuario " , usuario)
	
	#validacion basica
	if usuario == "":
		print("Error: El usuario esta vacio")
		return
	if contrasenha == "":
		print("Error: la contraseña esta vacia")
		return
	
	#crear el JSON que esera Django
	var datos_login = {
		"username": usuario,
		"password": contrasenha
	}
	
	_enviar_peticion_login(datos_login)

func _enviar_peticion_login(datos: Dictionary):
	var http_request = HTTPRequest.new()
	add_child(http_request)
	
	#conectar la señal
	http_request.request_completed.connect(_on_login_completado.bind(http_request))
	
	#convirtiendo datos a JSON string
	var json_string = JSON.stringify(datos)
	
	#configurar headers
	var headers = ["Content-Type: application/json"]
	
	#enviar peticion a login
	print("Enviando POST a: ", LOGIN_URL)
	print("Datos enviados ", json_string)
	
	var error = http_request.request(LOGIN_URL, headers, HTTPClient.METHOD_POST, json_string)
	
	if error != OK:
		print("Error al crear la peticion HTTP: ", error)
		http_request.queue_free()
		
		
		
func _on_login_completado(result: int, response_code: int, headers:PackedStringArray,body: PackedByteArray, http_request: HTTPRequest):
		http_request.queue_free()
		print("-------------------------Respuesta del servidor--------------------------------")
		print(result)
		print(response_code)
		
		#verificar si hubo algun error en la conexion
		if result != HTTPRequest.RESULT_SUCCESS:
			print("Error de conexion")
			return
			
		#convertir respuesta de bytes a string
		var response_body = body.get_string_from_utf8()
		print("Respuesta: " + response_body)
		
		#procesar segun codigo de respuesta
		match response_code:
			201:
				_procesar_login_exitoso(response_body)
			404:
				print("Error 404: Usuario no encontrado")
				_mostrar_error("Usuario no encontrado")
			401:
				print("Error 401: Contraseña incorrecta")
			400:
				print("Error 400: faltan parametros en la peticion")
			405:
				print("error 405: metodo HTTP no permitido")
				_mostrar_error("Error en la configuracion del servidor")
			500:
				print("error interno del servidor")
				_mostrar_error("Error del servidor")
			_:
				print("Error, codigo de respuesta no esperado", response_code)
				print("respuesta: ", response_body)
				_mostrar_error("Error desconocido: " + str(response_code))
		
func _procesar_login_exitoso(response_body: String):
		var json = JSON.new()
		var parse_error = json.parse(response_body)
			
		if parse_error != OK:
			print("ERROR: No se pudo parsear la respuesta JSON")
			print("Error: ", json.get_error_message())
			print("Respuesta: ", response_body)
			_mostrar_error("Error en la respuesta del servidor")
			return
		var respuesta = json.get_data()
		print("Respuesta parseada: ", respuesta)
		
		if respuesta.has("sessionToken"):
			session_token = respuesta["session_token"]
			print("¡LOGIN EXITOSO!")
			print("Token de sesión recibido: ", session_token)
			
			_guardar_sesion(usuario, session_token)
			usuario_LineEdit.text = ""
			contrasenha_LineEdit.text = ""
		#en esta zona es donde se puede poner luego para ir al menú principal
		# get_tree().change_scene_to_file("res:")
		else:
			print("ERROR: La respuesta no contiene 'sessionToken'")
			print("Respuesta completa: ", respuesta)
			_mostrar_error("Error en la respuesta del servidor")
			
func _mostrar_error(mensaje: String):
	# Aquí puedes implementar cómo mostrar errores al usuario
	# Por ejemplo, usando un Label o un popup
	print("ERROR PARA USUARIO: ", mensaje)
	
func _guardar_sesion(nombre_usuario: String, token: String):
	# Guardar en ConfigFile para persistencia
	var config = ConfigFile.new()
	
	# Intentar cargar configuración existente
	var err = config.load("user://config.cfg")
	if err != OK:
		print("Creando nuevo archivo de configuración")
	
	# Guardar datos de sesión
	config.set_value("sesion", "usuario", nombre_usuario)
	config.set_value("sesion", "token", token)
	config.set_value("sesion", "fecha_login", Time.get_datetime_string_from_system())
	
	# Guardar archivo
	config.save("user://config.cfg")
	print("Sesión guardada en configuración")
	
	# También puedes usar un Autoload/Singleton para acceso global
	if Engine.has_singleton("Global"):
		var global = Engine.get_singleton("Global")
		global.usuario = nombre_usuario
		global.session_token = token
		print("Datos guardados en singleton Global")
func _obtener_informacion_usuario():
	if session_token == "":
		print("No hay token de sesión para obtener información")
		return
	
	# Endpoint get_me según tu Django
	var url = BASE_URL + "/me"
	var headers = ["Content-Type: application/json", "Session: " + session_token]
	
	var http_request = HTTPRequest.new()
	add_child(http_request)
	
	http_request.request_completed.connect(_on_info_usuario_completada.bind(http_request))
	
	var error = http_request.request(url, headers, HTTPClient.METHOD_GET)
	
	if error != OK:
		print("Error al obtener información del usuario")
		http_request.queue_free()

func _on_info_usuario_completada(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray, http_request: HTTPRequest):
	http_request.queue_free()
	
	if result == HTTPRequest.RESULT_SUCCESS:
		var response_body = body.get_string_from_utf8()
		print("Información del usuario: ", response_body)
		
		if response_code == 200:
			var json = JSON.new()
			if json.parse(response_body) == OK:
				var datos = json.get_data()
				print("Username: ", datos.get("username", ""))
				print("Games Won: ", datos.get("gamesWon", 0))
				print("Games Played: ", datos.get("gamesPlayed", 0))

func _boton_registro_presionado():
	print("tiene rima muejejej")
	get_tree().change_scene_to_file("res://Escenas/Pestanha_register.tscn")
	 
	
