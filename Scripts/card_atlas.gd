extends Node

const ATLAS_PATH := "res://Texturas/Atlas Uno Clásicas.png"
const COORDS_PATH := "res://Texturas/cards_coords.json"

const CARD_WIDTH := 166
const CARD_HEIGHT := 258

var atlas_texture: Texture2D
var coords := {}

func _ready():
	atlas_texture = load(ATLAS_PATH)
	_load_coords()

func _load_coords():
	var file = FileAccess.open(COORDS_PATH, FileAccess.READ)
	if file == null:
		push_error("No se pudo abrir cards_coords.json")
		return

	var json = JSON.parse_string(file.get_as_text())
	if json == null:
		push_error("JSON de cartas inválido")
		return

	coords = json

func get_card_texture(code: String) -> Texture2D:
	var key = code.to_lower()

	if not coords.has(key):
		push_error("Carta no encontrada en atlas: " + key)
		return null

	var pos = coords[key]

	var atlas := AtlasTexture.new()
	atlas.atlas = atlas_texture
	atlas.region = Rect2i(
		pos["x"],
		pos["y"],
		CARD_WIDTH,
		CARD_HEIGHT
	)

	return atlas
