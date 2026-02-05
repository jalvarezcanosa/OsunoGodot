extends Node
const ATLAS_UNO_CLÁSICAS = preload("uid://dikoacdmoam83")

const ATLAS_PATH := "res://Texturas/Atlas Uno Clásicas.png"
const COORDS_PATH := "res://Texturas/card_coords.json"

const CARD_WIDTH := 166
const CARD_HEIGHT := 258

var atlas_texture: Texture2D
var coords := {}

func _ready():
	atlas_texture = load(ATLAS_PATH)
	if atlas_texture == null:
		push_error("❌ Atlas no cargado")
	_load_coords()

func _load_coords():
	var file = FileAccess.open(COORDS_PATH, FileAccess.READ)
	if file == null:
		push_error("❌ No se pudo abrir card_coords.json")
		return

	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("❌ JSON inválido")
		return

	coords = parsed

func get_card_texture(code: String) -> Texture2D:
	if code == "":
		return null

	var key := code.to_lower()
	if not coords.has(key):
		push_error("❌ Carta no existe en atlas: " + key)
		return null

	var pos : Vector2 = coords[key]

	var atlas := AtlasTexture.new()
	atlas.atlas = atlas_texture
	atlas.region = Rect2i(
		pos["x"],
		pos["y"],
		CARD_WIDTH,
		CARD_HEIGHT
	)

	return atlas
