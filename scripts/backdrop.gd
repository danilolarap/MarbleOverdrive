extends Control
## Static technical paper. Redraw only on resize/theme changes.
func _ready() -> void:
	resized.connect(queue_redraw)
	Session.preferences_changed.connect(queue_redraw)

func _draw() -> void:
	var paper := Color("e4e8e3") if Session.light else Color("0c151c")
	draw_rect(Rect2(Vector2.ZERO, size), paper)
	var rule := Color("7c928c", 0.11) if Session.light else Color("7c928c", 0.07)
	for x in range(0, int(size.x), 96):
		draw_line(Vector2(x, 0), Vector2(x, size.y), rule)
	for y in range(0, int(size.y), 96):
		draw_line(Vector2(0, y), Vector2(size.x, y), rule)
	var signal_color := Color("7c8a4a", 0.2) if Session.light else Color("cbd878", 0.1)
	for i in range(7):
		var x := size.x - 150 + i * 24
		draw_line(Vector2(x, size.y), Vector2(x + 85, size.y - 85), signal_color, 9)
	draw_line(Vector2(30, 9), Vector2(size.x - 30, 9), rule, 1)