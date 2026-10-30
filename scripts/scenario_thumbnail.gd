class_name ScenarioThumbnail
extends Control
var scenario_id := "CITY"

func _ready() -> void:
	custom_minimum_size = Vector2(180, 78)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	var colors: Array = GameCatalog.WORLD_COLORS[scenario_id]
	var a: Color = colors[0]
	var b: Color = colors[1]
	draw_rect(Rect2(Vector2.ZERO, size), a)
	var center := size / 2
	match scenario_id:
		"CITY", "FACTORY":
			for i in range(8):
				var h := 20 + (i * 17) % 42
				draw_rect(Rect2(10 + i * (size.x - 20) / 8, size.y - h, 15, h), b.darkened(0.5))
				for y in range(12, h, 9):
					draw_rect(Rect2(14 + i * (size.x - 20) / 8, size.y - y, 3, 3), b)
		"PLAYGROUND":
			draw_arc(center, 28, 0, TAU, 32, b, 2, true)
			for i in range(8):
				var end := center + Vector2.from_angle(i * TAU / 8) * 28
				draw_line(center, end, b, 1, true)
				draw_circle(end, 4, b)
		"ZOO":
			draw_circle(center, 17, b)
			draw_circle(center + Vector2(19, -11), 11, b)
			for x in [-12, 9]:
				draw_line(center + Vector2(x, 5), center + Vector2(x, 31), b, 6, true)
			draw_line(center + Vector2(26, -6), center + Vector2(30, 14), b, 5, true)
		"SPACEPORT":
			draw_colored_polygon(PackedVector2Array([center + Vector2(-13, 25), center + Vector2(-8, -12), center + Vector2(0, -33), center + Vector2(8, -12), center + Vector2(13, 25)]), b)
			draw_circle(center - Vector2(0, 7), 5, a)
		"VOLCANO", "ICE", "DESERT":
			for i in range(3):
				var p := Vector2(size.x * (0.2 + i * 0.3), size.y - 8)
				draw_colored_polygon(PackedVector2Array([p - Vector2(32, 0), p - Vector2(0, 45 + i % 2 * 18), p + Vector2(32, 0)]), b.darkened(i * 0.15))
		"JUNGLE", "SKY_GARDENS":
			for i in range(4):
				var p := Vector2(size.x * (0.15 + i * 0.23), 45)
				draw_line(p, p + Vector2(0, 30), b.darkened(0.4), 4)
				draw_circle(p, 17 + i % 2 * 5, b)
		"CANDY":
			for i in range(4):
				var p := Vector2(size.x * (0.15 + i * 0.23), 28 + i % 2 * 10)
				draw_line(p, p + Vector2(0, 34), Color.WHITE, 3)
				draw_circle(p, 14, b)
				draw_arc(p, 8, 0, 5, 20, a, 2, true)
		"OCEAN":
			for row in range(4):
				var line := PackedVector2Array()
				for x in range(0, int(size.x), 3):
					line.append(Vector2(x, 15 + row * 15 + sin(x * 0.07 + row) * 5))
				draw_polyline(line, b, 2, true)
	draw_line(Vector2(0, size.y - 2), Vector2(size.x, size.y - 2), b, 2)
