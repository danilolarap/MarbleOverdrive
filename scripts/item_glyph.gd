class_name ItemGlyph
extends RefCounted
## Vector symbols for the eight items and three powers, shared by the tactical map,
## the strategy cards and the placement panel. `s` scales the 20 px design grid.

static func draw(canvas: CanvasItem, at: Vector2, kind: String, color: Color, s: float = 1.0) -> void:
	var w := 2.0 * s
	match kind:
		"BOOST":
			canvas.draw_polyline(PackedVector2Array([at + Vector2(-6, -6) * s, at + Vector2(1, 0) * s, at + Vector2(-6, 6) * s]), color, w + s, true)
			canvas.draw_polyline(PackedVector2Array([at + Vector2(0, -6) * s, at + Vector2(7, 0) * s, at + Vector2(0, 6) * s]), color, w + s, true)
		"MAGNET":
			canvas.draw_arc(at - Vector2(1, 0) * s, 6 * s, PI / 2, PI * 1.5, 16, color, 3 * s, true)
			canvas.draw_line(at + Vector2(-1, -6) * s, at + Vector2(6, -6) * s, color, 3 * s, true)
			canvas.draw_line(at + Vector2(-1, 6) * s, at + Vector2(6, 6) * s, color, 3 * s, true)
		"REPAIR":
			canvas.draw_line(at - Vector2(0, 7) * s, at + Vector2(0, 7) * s, color, 3.5 * s, true)
			canvas.draw_line(at - Vector2(7, 0) * s, at + Vector2(7, 0) * s, color, 3.5 * s, true)
		"SHIELD":
			canvas.draw_polyline(PackedVector2Array([at + Vector2(-6, -6) * s, at + Vector2(6, -6) * s, at + Vector2(6, 1) * s, at + Vector2(0, 7) * s, at + Vector2(-6, 1) * s, at + Vector2(-6, -6) * s]), color, w, true)
		"GRIP":
			for offset in [-5, 0, 5]:
				canvas.draw_line(at + Vector2(-6, offset) * s, at + Vector2(6, offset) * s, color, w, true)
		"SHOCK":
			canvas.draw_polyline(PackedVector2Array([at + Vector2(2, -8) * s, at + Vector2(-4, 1) * s, at + Vector2(3, 1) * s, at + Vector2(-2, 8) * s]), color, w + s * 0.5, true)
		"OIL":
			canvas.draw_circle(at + Vector2(0, 2) * s, 5 * s, Color(color, 0.8))
			canvas.draw_polyline(PackedVector2Array([at + Vector2(-4, 0) * s, at + Vector2(0, -8) * s, at + Vector2(4, 0) * s]), Color(color, 0.8), w, true)
		"BARRIER":
			canvas.draw_line(at + Vector2(-5, 6) * s, at + Vector2(0, -6) * s, color, 3 * s, true)
			canvas.draw_line(at + Vector2(1, 6) * s, at + Vector2(6, -6) * s, color, 3 * s, true)
			canvas.draw_line(at + Vector2(-8, 6) * s, at + Vector2(8, 6) * s, color, w, true)
		"EMP":
			canvas.draw_circle(at, 2.5 * s, color)
			canvas.draw_arc(at, 5.5 * s, 0, TAU, 24, color, w, true)
			canvas.draw_arc(at, 9 * s, -0.6, 0.6, 8, color, w, true)
			canvas.draw_arc(at, 9 * s, PI - 0.6, PI + 0.6, 8, color, w, true)
		"JUMP":
			canvas.draw_arc(at + Vector2(0, 6) * s, 8 * s, PI, TAU, 16, color, w, true)
			canvas.draw_polyline(PackedVector2Array([at + Vector2(4, -1) * s, at + Vector2(8, 6) * s, at + Vector2(11, -1) * s]), color, w, true)
			canvas.draw_circle(at + Vector2(-8, 6) * s, 2.5 * s, color)
		"PHASE":
			canvas.draw_circle(at + Vector2(4, 0) * s, 4.5 * s, color)
			for k in range(3):
				var y := (k - 1) * 4.0
				canvas.draw_line(at + Vector2(-10 + k, y) * s, at + Vector2(-3, y) * s, Color(color, 0.5 + 0.2 * k), w, true)
		_:
			canvas.draw_circle(at, 4 * s, color)
