extends Control
@onready var volúmen: VBoxContainer = $"Volúmen"
@onready var inicio: VBoxContainer = $"Inicio de sesión"
@onready var click_1: AudioStreamPlayer = $Click1
@onready var click_2: AudioStreamPlayer = $Click2

func _ready() -> void:
	volúmen.hide()
	inicio.hide()
func _on_salir_pressed() -> void:
	click_2.play()
	await get_tree().create_timer(0.2).timeout
	get_tree().quit()
	
func _on_volver_pressed() -> void:
	volúmen.hide()
	click_2.play()
func _on_slider_música_value_changed(value: float) -> void:
	var bus: int = AudioServer.get_bus_index("Música")
	AudioServer.set_bus_volume_db(bus, linear_to_db(value))

func _on_slider_efectos_value_changed(value: float) -> void:
	var bus: int = AudioServer.get_bus_index("Efectos")
	AudioServer.set_bus_volume_db(bus, linear_to_db(value))

func _on_musica_toggled(toggled_on: bool) -> void:
	if toggled_on:
		volúmen.show()
		click_1.play()
	else:
		volúmen.hide()

func _on_ajustes_toggled(toggled_on: bool) -> void:
	if toggled_on:
		volúmen.show()
		click_1.play()
	else:
		volúmen.hide()
		click_1.play()

func _on_nueva_partida_toggled(toggled_on: bool) -> void:
	if toggled_on:
		inicio.show()
		click_1.play()
	else:
		inicio.hide()
		
func _on_iniciar_sesión_pressed() -> void:
	click_2.play()
	await get_tree().create_timer(0.2).timeout
	get_tree().change_scene_to_file("res://Escenas/menú_sala.tscn")
