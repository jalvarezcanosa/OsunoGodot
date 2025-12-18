# TODO ESTO SACADO DE MI PROYECTO DE GODOT, USAR COMO REFERENCIA 
extends Control
@onready var música: VBoxContainer = $Música

func _ready() -> void:
	música.hide()
	
func _on_jugar_pressed() -> void:
	get_tree().change_scene_to_file("res://Escenas/menú_sala2D.tscn")

func _on_salir_pressed() -> void:
	get_tree().quit()

func _on_volver_pressed() -> void:
	música.hide()

func _on_nueva_partida_pressed() -> void:
	get_tree().change_scene_to_file("res://Escenas/menú_sala.tscn")

func _on_slider_música_value_changed(value: float) -> void:
	var bus: int = AudioServer.get_bus_index("Música")
	AudioServer.set_bus_volume_db(bus, linear_to_db(value))

func _on_slider_efectos_value_changed(value: float) -> void:
	var bus: int = AudioServer.get_bus_index("Efectos")
	AudioServer.set_bus_volume_db(bus, linear_to_db(value))


func _on_musica_toggled(toggled_on: bool) -> void:
	if toggled_on:
		música.show()
	else:
		música.hide()


func _on_ajustes_toggled(toggled_on: bool) -> void:
	if toggled_on:
		música.show()
	else:
		música.hide()
