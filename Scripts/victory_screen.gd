extends CanvasLayer


@onready var main_menu_button = $CenterContainer/VBoxContainer/MainMenu
@onready var quit_button = $CenterContainer/VBoxContainer/Quit
@onready var content_container = $CenterContainer/VBoxContainer

func _ready():	
	animate_entry()

func animate_entry():
	# Empezamos con escala 0 (invisible)
	content_container.scale = Vector2.ZERO
	
	# Creamos un Tween para animar la escala
	var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS) # Importante porque el juego está en pausa
	
	
	tween.tween_property(content_container, "scale", Vector2.ONE, 0.5)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

# Señales botones
func _on_main_menu_pressed():
	get_tree().paused = false # Despausar antes de salir
	get_tree().change_scene_to_file("res://Escenas/menu_inicio.tscn")

func _on_quit_pressed():
	get_tree().quit()
