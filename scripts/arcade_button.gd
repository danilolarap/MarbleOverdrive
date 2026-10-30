extends Button
func _draw() -> void:
	var color := Color("17829b", 0.65) if Session.light else Color("63e8f4", 0.65)
	if is_hovered() or has_focus():
		draw_line(Vector2(15, size.y - 3), Vector2(size.x - 15, size.y - 3), color, 2, true)
	draw_circle(Vector2(10, size.y / 2), 1.5, color)
