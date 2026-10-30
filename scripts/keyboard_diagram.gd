class_name KeyboardDiagram
extends Control
## A native, localized keyboard illustration that follows saved race bindings.
var player_index := 0
var mode := "placement"
var font: Font
var _draw_state: Array = []

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(350, 275 if mode == "both" else 150)
	font = ThemeDB.fallback_font

func _process(_delta: float) -> void:
	var codes := [KEY_W, KEY_A, KEY_S, KEY_D, KEY_SPACE] if player_index == 0 else [KEY_UP, KEY_LEFT, KEY_DOWN, KEY_RIGHT, KEY_ENTER]
	codes.append(int(Session.keys["p%d_power" % (player_index + 1)]))
	codes.append(int(Session.keys["p%d_brake" % (player_index + 1)]))
	var pressed := 0
	for i in range(codes.size()):
		if Input.is_physical_key_pressed(codes[i]):
			pressed |= 1 << i
	var current := [pressed, codes, Session.light, Session.language, Session.players[player_index].color, size]
	if current != _draw_state:
		_draw_state = current
		queue_redraw()

func _ink() -> Color:
	return Color("173249") if Session.light else Color("edf6ff")

func _tint() -> Color:
	var color: Color = Session.players[player_index].color
	return color.darkened(0.48) if Session.light else color

func _text(at: Vector2, text: String, font_size: int = 14, color: Color = Color.TRANSPARENT) -> void:
	draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, _ink() if color == Color.TRANSPARENT else color)

func _key(rect: Rect2, caption: String, code: int) -> void:
	var pressed := Input.is_physical_key_pressed(code)
	var style := StyleBoxFlat.new()
	style.bg_color = _tint() if pressed else Color("f6f9fc") if Session.light else Color("162c42")
	style.border_color = _tint()
	style.set_border_width_all(2)
	style.set_corner_radius_all(7)
	style.shadow_color = Color(0, 0, 0, 0.15)
	style.shadow_offset = Vector2(0, 3)
	style.shadow_size = 1
	draw_style_box(style, rect)
	var font_size := 18 if caption.length() < 4 else 14
	var width := font.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	_text(rect.position + Vector2((rect.size.x - width) / 2, rect.size.y / 2 + 6), caption, font_size, Color("071925") if pressed and not Session.light else Color.WHITE if pressed else _ink())

func _draw() -> void:
	if font == null:
		return
	if mode != "race":
		var codes := [KEY_W, KEY_A, KEY_S, KEY_D] if player_index == 0 else [KEY_UP, KEY_LEFT, KEY_DOWN, KEY_RIGHT]
		var captions := ["W", "A", "S", "D"] if player_index == 0 else ["↑", "←", "↓", "→"]
		for i in range(4):
			var at := Vector2(58, 5) if i == 0 else Vector2(10 + (i - 1) * 48, 50)
			_key(Rect2(at, Vector2(40, 37)), captions[i], codes[i])
		_key(Rect2(10, 100, 136, 34), tr("SPACE_KEY") if player_index == 0 else tr("ENTER_KEY"), KEY_SPACE if player_index == 0 else KEY_ENTER)
		_text(Vector2(170, 30), tr("KEY_ALONG%d" % (player_index + 1)), 16)
		_text(Vector2(170, 51), tr("KEY_ACROSS%d" % (player_index + 1)), 16)
		_text(Vector2(170, 82), tr("KEY_PLACE"), 16, _tint())
		_text(Vector2(170, 105), tr("KEY_ORDER"), 14)
		_text(Vector2(170, 126), tr("KEY_SAFE"), 14)
	if mode in ["race", "both"]:
		var top := 182.0 if mode == "both" else 25.0
		if mode == "both":
			_text(Vector2(10, 165), tr("RACE_KEYS"), 15, _tint())
		for i in range(2):
			var action := "p%d_%s" % [player_index + 1, "power" if i == 0 else "brake"]
			var x := 10.0 + i * 190
			_key(Rect2(x, top, 54, 43), Session.key_label(action), int(Session.keys[action]))
			_text(Vector2(x + 65, top + 17), tr("POWER") if i == 0 else tr("BRAKE"), 16)
			_text(Vector2(x + 65, top + 39), tr("TAP_KEY") if i == 0 else tr("HOLD_KEY"), 13)
		_text(Vector2(10, top + 76), tr("BRAKE_HELP"), 13)
