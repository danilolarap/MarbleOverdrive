extends Control

var time := 0.0

func _process(delta: float) -> void:
	time += delta
	queue_redraw()

func _draw() -> void:
	var light: bool = Session.light
	var base := Color("eef3f7") if light else Color("060e1c")
	draw_rect(Rect2(Vector2.ZERO, size), base)
	# Layered atmosphere and angular circuits, rather than a flat menu sheet.
	for band in range(40):
		var fraction := band / 40.0
		var tint := base.lightened(0.025 * sin(fraction * PI)) if light else base.lerp(Color("17304b"), sin(fraction * PI) * 0.35)
		draw_rect(Rect2(0, fraction * size.y, size.x, size.y / 40 + 1), tint)
	for i in range(6):
		draw_circle(Vector2(size.x * 0.86, size.y * 0.28), 340 - i * 35, Color("35c9d9", 0.006 if light else 0.009))
	var line_color := Color("178da3", 0.16) if light else Color("40d2e9", 0.19)
	var circuit := PackedVector2Array([Vector2(size.x * 0.57, 0), Vector2(size.x * 0.57, 45), Vector2(size.x * 0.63, 90), Vector2(size.x - 30, 90), Vector2(size.x - 10, 110), Vector2(size.x - 10, size.y * 0.73)])
	draw_polyline(circuit, line_color, 2, true)
	draw_polyline(PackedVector2Array([Vector2(0, size.y - 65), Vector2(size.x * 0.27, size.y - 65), Vector2(size.x * 0.32, size.y - 20), Vector2(size.x * 0.65, size.y - 20)]), line_color, 2, true)
	var grid := Color("b1c9d7", 0.28) if light else Color("2c4968", 0.17)
	for x in range(0, int(size.x) + 80, 64):
		draw_line(Vector2(x, 0), Vector2(x, size.y), grid, 1)
	for y in range(0, int(size.y) + 80, 64):
		draw_line(Vector2(0, y), Vector2(size.x, y), grid, 1)
	for i in range(40):
		var point := Vector2(fmod(i * 173.7 + time * (3 + i % 4), size.x), fmod(i * 97.3, size.y))
		draw_circle(point, 1.2, Color("2586a0", 0.3) if light else Color("8fbbd7", 0.2))
