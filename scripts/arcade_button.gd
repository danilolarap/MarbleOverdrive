extends Button
func _draw() -> void:
	var color := Color("43616a", 0.7) if Session.light else Color("cbd878", 0.7)
	if is_hovered() or has_focus():
		draw_line(Vector2(15, size.y - 3), Vector2(size.x - 15, size.y - 3), color, 2, true)
	draw_circle(Vector2(10, size.y / 2), 1.5, color)
