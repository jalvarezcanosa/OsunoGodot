extends Node2D
@onready var codigo_sala_unir: LineEdit = $"Botonera/BotonesMenú/Crear Sala/Código Sala Unir"
@onready var codigo_sala_crear: Label = $"Botonera/BotonesMenú/Unirse Sala/Código Sala Crear"
@onready var click_1: AudioStreamPlayer = $Click1
@onready var click_2: AudioStreamPlayer = $Click2

func _ready() -> void:
	codigo_sala_crear.hide()
	codigo_sala_unir.hide()
#func _on_jugar_pressed() -> void:
	#get_tree().change_scene_to_file("res://Escenas/Partida.tscn")

func _on_crear_sala_pressed() -> void:
	codigo_sala_crear.show()
	codigo_sala_unir.hide()
	click_1.play()

func _on_unirse_sala_pressed() -> void:
	codigo_sala_crear.hide()
	codigo_sala_unir.show()
	click_1.play()
func _on_volver_pressed() -> void:
	click_2.play()
	await get_tree().create_timer(0.2).timeout
	get_tree().change_scene_to_file("res://Escenas/menu_inicio.tscn")
