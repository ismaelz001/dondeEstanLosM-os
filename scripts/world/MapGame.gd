extends Node2D

# Lightweight visual map layer for the vertical slice.
# Gameplay collisions stay in barrio_demo.tscn; this node owns visual density.

const MAP_SIZE := Vector2(1280, 960)
const ROAD := Color(0.20, 0.21, 0.20, 1.0)
const ROAD_DARK := Color(0.16, 0.17, 0.16, 1.0)
const SIDEWALK := Color(0.54, 0.50, 0.38, 1.0)
const CURB := Color(0.72, 0.67, 0.50, 1.0)
const LOT := Color(0.31, 0.33, 0.28, 1.0)
const MARKING := Color(0.78, 0.70, 0.38, 1.0)
const SHADOW := Color(0.04, 0.04, 0.04, 0.33)

@export var houses_texture: Texture2D
@export var r5_texture: Texture2D

func _ready() -> void:
	_build_ground()
	_build_road_markings()
	_build_building_shadows()
	_build_props()

func _build_ground() -> void:
	_rect("BaseAsfalto", Rect2(Vector2.ZERO, MAP_SIZE), ROAD)
	_rect("AceraNorte", Rect2(0, 0, MAP_SIZE.x, 184), SIDEWALK)
	_rect("AceraSur", Rect2(0, 688, MAP_SIZE.x, 272), SIDEWALK)
	_rect("Avenida", Rect2(0, 384, MAP_SIZE.x, 192), ROAD_DARK)
	_rect("CalleVertical", Rect2(544, 0, 176, MAP_SIZE.y), ROAD_DARK)
	_rect("PlazaBar", Rect2(400, 216, 360, 160), Color(0.35, 0.34, 0.29, 1.0))
	_rect("Solar", Rect2(880, 704, 260, 160), LOT)
	_rect("BordilloNorte", Rect2(0, 184, MAP_SIZE.x, 8), CURB)
	_rect("BordilloSur", Rect2(0, 680, MAP_SIZE.x, 8), CURB)
	_rect("BordilloAvenidaTop", Rect2(0, 384, MAP_SIZE.x, 6), Color(0.62, 0.59, 0.48, 1.0))
	_rect("BordilloAvenidaBottom", Rect2(0, 570, MAP_SIZE.x, 6), Color(0.62, 0.59, 0.48, 1.0))

func _build_road_markings() -> void:
	for x in range(24, 1280, 72):
		_rect("LineaAvenida_%d" % x, Rect2(x, 476, 38, 4), MARKING)
	for y in range(40, 940, 72):
		_rect("LineaVertical_%d" % y, Rect2(630, y, 4, 34), Color(0.62, 0.62, 0.56, 1.0))
	for i in range(0, 7):
		_rect("PasoBar_%d" % i, Rect2(430 + i * 18, 372, 10, 42), Color(0.78, 0.76, 0.66, 1.0))
		_rect("PasoTaller_%d" % i, Rect2(720 + i * 18, 626, 10, 42), Color(0.78, 0.76, 0.66, 1.0))
	for x in range(24, 1280, 96):
		_rect("Mancha_%d" % x, Rect2(x, 518 + (x % 3) * 10, 18, 6), Color(0.10, 0.11, 0.10, 0.28))

func _build_building_shadows() -> void:
	_rect("SombraBloque", Rect2(136, 114, 210, 112), SHADOW)
	_rect("SombraBar", Rect2(438, 282, 150, 96), SHADOW)
	_rect("SombraTaller", Rect2(688, 742, 166, 104), SHADOW)
	_rect("SombraLocal", Rect2(774, 118, 126, 94), SHADOW)
	_build_house("CasaExtraA", Vector2(820, 140), Rect2(48, 0, 48, 48), Vector2(1.5, 1.5))
	_build_house("CasaExtraB", Vector2(1010, 720), Rect2(96, 0, 48, 48), Vector2(1.5, 1.5))

func _build_props() -> void:
	for pos in [Vector2(372, 356), Vector2(760, 350), Vector2(860, 620), Vector2(316, 628)]:
		_lamp(pos)
	for pos in [Vector2(280, 244), Vector2(540, 336), Vector2(932, 760)]:
		_bin(pos)
	_parked_car("CocheAparcadoA", Vector2(220, 512), 2)
	_parked_car("CocheAparcadoB", Vector2(1030, 440), 3)
	for x in range(900, 1140, 32):
		_rect("SolarPiedra_%d" % x, Rect2(x, 804 + (x % 2) * 18, 8, 5), Color(0.20, 0.22, 0.19, 1.0))

func _build_house(node_name: String, pos: Vector2, region: Rect2, sprite_scale: Vector2) -> void:
	if houses_texture == null:
		return
	var sprite := Sprite2D.new()
	sprite.name = node_name
	sprite.texture = houses_texture
	sprite.region_enabled = true
	sprite.region_rect = region
	sprite.scale = sprite_scale
	sprite.position = pos
	add_child(sprite)

func _parked_car(node_name: String, pos: Vector2, frame_index: int) -> void:
	if r5_texture == null:
		return
	var sprite := Sprite2D.new()
	sprite.name = node_name
	sprite.texture = r5_texture
	sprite.hframes = 4
	sprite.vframes = 2
	sprite.frame = frame_index
	sprite.position = pos
	add_child(sprite)

func _lamp(pos: Vector2) -> void:
	_rect("Farola", Rect2(pos, Vector2(2, 16)), Color(0.11, 0.10, 0.09, 1.0))
	_rect("FarolaLuz", Rect2(pos + Vector2(-3, -4), Vector2(8, 4)), Color(0.92, 0.78, 0.36, 1.0))

func _bin(pos: Vector2) -> void:
	_rect("Contenedor", Rect2(pos, Vector2(14, 10)), Color(0.12, 0.30, 0.23, 1.0))
	_rect("ContenedorTapa", Rect2(pos + Vector2(1, -2), Vector2(12, 3)), Color(0.08, 0.20, 0.16, 1.0))

func _rect(node_name: String, rect: Rect2, color: Color) -> void:
	var node := Polygon2D.new()
	node.name = node_name
	node.color = color
	node.polygon = PackedVector2Array([
		rect.position,
		rect.position + Vector2(rect.size.x, 0),
		rect.position + rect.size,
		rect.position + Vector2(0, rect.size.y),
	])
	add_child(node)
