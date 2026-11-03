extends Control

## Atmospheric arcade background. Redraw only on resize/theme changes.

func _ready() -> void:
	resized.connect(queue_redraw)
	Session.preferences_changed.connect(queue_redraw)


func _draw() -> void:
	var light_mode := Session.light

	var base := Color("e8ece8") if light_mode else Color("080f16")
	var upper_glow := Color("d5e4df") if light_mode else Color("10212c")
	var cyan := Color("168b9b", 0.13) if light_mode else Color("20d9ee", 0.10)
	var magenta := Color("b34d83", 0.08) if light_mode else Color("ec3d91", 0.09)
	var line_color := Color("829995", 0.12) if light_mode else Color("91b6c2", 0.07)
	var signal_color := Color("71833d", 0.24) if light_mode else Color("cbd878", 0.16)

	draw_rect(Rect2(Vector2.ZERO, size), base)

	# Soft atmospheric light.
	draw_circle(
		Vector2(size.x * 0.12, size.y * 0.12),
		size.x * 0.42,
		upper_glow
	)
	draw_circle(
		Vector2(size.x * 0.92, size.y * 0.82),
		size.x * 0.34,
		magenta
	)
	draw_circle(
		Vector2(size.x * 0.08, size.y * 0.88),
		size.x * 0.28,
		cyan
	)

	# Large diagonal architectural shapes.
	var points := PackedVector2Array([
		Vector2(size.x * 0.68, 0),
		Vector2(size.x, 0),
		Vector2(size.x, size.y * 0.42),
		Vector2(size.x * 0.88, size.y * 0.34)
	])
	draw_colored_polygon(points, line_color)

	var second_shape := PackedVector2Array([
		Vector2(0, size.y * 0.68),
		Vector2(size.x * 0.22, size.y),
		Vector2(0, size.y)
	])
	draw_colored_polygon(second_shape, cyan)

	# Restrained technical diagonal lines.
	for i in range(6):
		var offset := float(i) * 34.0
		draw_line(
			Vector2(size.x * 0.72 + offset, 0),
			Vector2(size.x * 0.42 + offset, size.y),
			line_color,
			1.0,
			true
		)

	# Arcade signal detail.
	for i in range(5):
		var x := size.x - 145 + i * 23
		draw_line(
			Vector2(x, size.y),
			Vector2(x + 65, size.y - 65),
			signal_color,
			5.0,
			true
		)

	# Fine top and bottom borders.
	draw_line(
		Vector2(30, 9),
		Vector2(size.x - 30, 9),
		line_color,
		1.0
	)
	draw_line(
		Vector2(30, size.y - 9),
		Vector2(size.x - 30, size.y - 9),
		line_color,
		1.0
	)
