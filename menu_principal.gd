# TODO ESTO SACADO DE MI PROYECTO DE GODOT, USAR COMO REFERENCIA 

extends Control

@onready var opciones_menu: Control = $VBoxContainer/Opciones
@onready var ajustes_menu: Control = $Control/Ajustes
@onready var runs_label: Label = $Marcador/VBoxContainer/RunsLabel

func _ready() -> void:
	ajustes_menu.hide()
	opciones_menu.show()
	mostrar_marcador()   # cargar marcador al iniciar menú

func _on_jugar_pressed() -> void:
	get_tree().change_scene_to_file("res://Escenas/Main.tscn")

func _on_opciones_pressed() -> void:
	opciones_menu.hide()
	ajustes_menu.show()

func _on_salir_pressed() -> void:
	get_tree().quit()

func _on_volver_pressed() -> void:
	ajustes_menu.hide()
	opciones_menu.show()

func _on_musica_slider_value_changed(value: float) -> void:
	var bus: int = AudioServer.get_bus_index("Música")
	AudioServer.set_bus_volume_db(bus, linear_to_db(value))

func _on_efectos_slider_value_changed(value: float) -> void:
	var bus: int = AudioServer.get_bus_index("Efectos")
	AudioServer.set_bus_volume_db(bus, linear_to_db(value))

# --- Marcador ---
func mostrar_marcador() -> void:
	if FileAccess.file_exists("user://runs.json"):
		var file: FileAccess = FileAccess.open("user://runs.json", FileAccess.READ)
		var content: String = file.get_as_text()
		file.close()
		var data = JSON.parse_string(content)

		if typeof(data) == TYPE_ARRAY and data.size() > 0:
			# últimas 5 runs
			var ultimas: Array = data.slice(max(data.size() - 5, 0), data.size())
			var texto: String = "Últimas 5 runs:\n"
			for run in ultimas:
				var tiempo: float = run["tiempo"]
				var muertes: int = run["muertes"]
				texto += "Tiempo: %.1f s, Muertes: %d\n" % [tiempo, muertes]

			# mejor run
			var mejor: Dictionary = data[0]
			for run in data:
				if run["tiempo"] < mejor["tiempo"]:
					mejor = run
			texto += "\nMejor run:\nTiempo: %.1f s, Muertes: %d" % [mejor["tiempo"], mejor["muertes"]]

			runs_label.text = texto
		else:
			runs_label.text = "No hay runs guardadas todavía."
	else:
		runs_label.text = "No hay runs guardadas todavía."
