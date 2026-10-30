class_name TacticalMap
extends Control
## A lighting-independent planning chart of the actual generated 3D course.
## Width is exaggerated so legal lateral positions remain readable at any zoom.
var race: DuelRace
var cells: Array[Dictionary] = []
var cached_count := -1
var font: Font
const HALF_ROAD := 23.0
var _layout_size := Vector2(-1, -1)
var _path := PackedVector2Array()
var _bands: Array[PackedVector2Array] = []
var _hazards := PackedVector2Array()
var _items := PackedVector2Array()
var _draw_state: Array = []

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(600, 260)
	font = ThemeDB.fallback_font

func _process(_delta: float) -> void:
	if is_instance_valid(race):
		if cached_count != race.items.size():
			cache_validity()
		var state := [size, race.cursor_distances.duplicate(), race.cursor_offsets.duplicate(), race.placed.duplicate(), race.items.size(), Session.light, Session.language, Session.players[0].color, Session.players[1].color]
		if state != _draw_state:
			_draw_state = state
			queue_redraw()

func cache_validity() -> void:
	cells.clear()
	cached_count = race.items.size()
	_layout_size = Vector2(-1, -1)
	for distance in range(6, int(race.track.total_length), 6):
		var sample := race.track.sample_at(distance)
		for offset in [-2.6, 0.0, 2.6]:
			var point: Vector3 = sample.position + sample.normal * offset
			var first := race.can_place(point, 0)
			var second := race.can_place(point, 1)
			cells.append({"distance": float(distance), "offset": offset, "valid": first or second, "owner": 0 if first else 1})

func _prepare_geometry() -> void:
	if _layout_size == size:
		return
	_layout_size = size
	_path.clear()
	_bands.clear()
	_hazards.clear()
	_items.clear()
	for point in race.track.points:
		_path.append(center_position(point))
	for lane in range(2):
		var band := PackedVector2Array()
		for distance in range(0, int(race.track.total_length), 4):
			band.append(chart_position(distance, -2.4 if lane == 0 else 2.4))
		_bands.append(band)
	for cell in cells:
		cell.point = chart_position(cell.distance, cell.offset)
	for hazard in race.track.hazards:
		_hazards.append(world_position(hazard.position))
	for item in race.items:
		_items.append(world_position(item.position))

func _ink() -> Color:
	return Color("18334b") if Session.light else Color("e6f3ff")

func _text(at: Vector2, text: String, font_size: int = 15, color: Color = Color.TRANSPARENT) -> void:
	draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, _ink() if color == Color.TRANSPARENT else color)

func center_position(point: Vector3) -> Vector2:
	var horizontal_scale := (size.x - 130) / absf(race.track.points[-1].z)
	return Vector2(65 - point.z * horizontal_scale, size.y * 0.46 + point.x * horizontal_scale * 0.8)

func chart_position(distance: float, offset: float = 0) -> Vector2:
	var sample := race.track.sample_at(distance)
	var screen_normal := Vector2(-sample.normal.z, sample.normal.x).normalized()
	return center_position(sample.position) + screen_normal * offset * HALF_ROAD / 5

func world_position(point: Vector3) -> Vector2:
	var sample := race.track.closest(point)
	var offset: float = (point - sample.position).dot(sample.normal)
	return chart_position(sample.distance, offset)

func _item_symbol(at: Vector2, kind: String, color: Color) -> void:
	draw_circle(at, 10, Color("102438"))
	draw_arc(at, 10, 0, TAU, 24, color, 2, true)
	if kind == "BOOST":
		draw_polyline(PackedVector2Array([at + Vector2(-4, -5), at + Vector2(3, 0), at + Vector2(-4, 5)]), color, 2, true)
	elif kind == "MAGNET":
		draw_arc(at - Vector2(2, 0), 5, -PI / 2, PI / 2, 12, color, 3, true)
	elif kind == "REPAIR":
		draw_line(at - Vector2(0, 6), at + Vector2(0, 6), color, 3, true)
		draw_line(at - Vector2(6, 0), at + Vector2(6, 0), color, 3, true)
	elif kind == "SHIELD":
		draw_polyline(PackedVector2Array([at + Vector2(-5, -5), at + Vector2(5, -5), at + Vector2(5, 1), at + Vector2(0, 6), at + Vector2(-5, 1), at + Vector2(-5, -5)]), color, 2, true)
	elif kind == "GRIP":
		for offset in [-4, 0, 4]:
			draw_line(at + Vector2(-5, offset), at + Vector2(5, offset), color, 2, true)
	elif kind == "SHOCK":
		draw_polyline(PackedVector2Array([at + Vector2(2, -6), at + Vector2(-3, 0), at + Vector2(3, 0), at + Vector2(-2, 6)]), color, 2, true)
	elif kind == "OIL":
		draw_circle(at, 5, Color(color, 0.7))
	else:
		draw_line(at + Vector2(-4, 5), at + Vector2(1, -5), color, 3, true)
		draw_line(at + Vector2(1, 5), at + Vector2(6, -5), color, 3, true)

func _draw() -> void:
	if not is_instance_valid(race) or font == null:
		return
	if cached_count != race.items.size():
		cache_validity()
	_prepare_geometry()
	# Opaque surfaces and dark outlines never depend on scene lighting/bloom.
	draw_polyline(_path, Color("163149") if Session.light else Color("7197b1"), HALF_ROAD * 2 + 5, true)
	draw_polyline(_path, Color("354c60") if Session.light else Color("223b50"), HALF_ROAD * 2, true)
	for lane in range(2):
		draw_polyline(_bands[lane], Color(Session.players[lane].color, 0.17), 17, true)
	for cell in cells:
		var at: Vector2 = cell.point
		var color: Color = Session.players[cell.owner].color if cell.valid else Color("d08489")
		draw_circle(at, 2.2, color)
	for distance in range(0, int(race.track.total_length), 10):
		if distance < 26 or distance > race.track.total_length - 24:
			var at := chart_position(distance)
			draw_line(at + Vector2(-4, -19), at + Vector2(4, 19), Color("edb37b"), 2, true)
	for at in _hazards:
		draw_circle(at, 17, Color("e65d73", 0.2))
		_text(at + Vector2(-4, 6), "!", 22, Color("ffbdc6"))
	for i in range(race.items.size()):
		var item := race.items[i]
		var at := _items[i]
		_item_symbol(at, item.kind, GameCatalog.ITEMS[item.kind].color)
		_text(at + Vector2(-6, -14), str(item.owner_index + 1), 13, Color("123048") if Session.light else Color.WHITE)
	var start := chart_position(0)
	var finish := chart_position(race.track.total_length)
	_text(start + Vector2(-22, 45), tr("START_LINE"), 14)
	_text(finish + Vector2(-20, 45), tr("FINISH"), 14)
	for i in range(2):
		var at := chart_position(race.cursor_distances[i], race.cursor_offsets[i])
		var valid: bool = race.can_place(race.cursor_location(i), i) and race.placed[i] < 3
		var player_color: Color = Session.players[i].color.darkened(0.4) if Session.light else Session.players[i].color
		draw_circle(at, 14, Color("f7fbff") if Session.light else Color("081725"))
		draw_arc(at, 15, 0, TAU, 32, player_color, 3, true)
		var status_color := Color("126441") if Session.light else Color("88efb6")
		if not valid:
			status_color = Color("a22340") if Session.light else Color("ff8da2")
		_text(at + Vector2(-8, 5), "OK" if valid else "X", 12, status_color)
		var tag_position := at + Vector2(-30, -40 if i == 0 else 55)
		_text(tag_position, ("J%d" if Session.language == "es" else "P%d") % (i + 1), 18, player_color)
		draw_line(at + Vector2(0, -17 if i == 0 else 17), at + Vector2(0, -30 if i == 0 else 38), player_color, 2, true)
	# Explicit legend: valid dots, blocked crosshatch and already placed items.
	var legend_y := size.y - 13
	draw_circle(Vector2(18, legend_y - 5), 4, Color("27805c") if Session.light else Color("88efb6"))
	_text(Vector2(30, legend_y), tr("MAP_VALID"), 14)
	_text(Vector2(285, legend_y), "X  " + tr("MAP_BLOCKED"), 14, Color("a22340") if Session.light else Color("ff9db0"))
	_text(Vector2(650, legend_y), tr("MAP_ITEMS"), 14)
	_text(start + Vector2(12, -12), Session.player_name(0).left(10), 12, Color.WHITE)
	_text(start + Vector2(12, 16), Session.player_name(1).left(10), 12, Color.WHITE)
