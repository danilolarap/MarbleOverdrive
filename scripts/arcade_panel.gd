extends PanelContainer
## Layered chrome, corner circuits and a restrained accent line for every card.
func _draw() -> void:
	var accent := Color("738344", 0.65) if Session.light else Color("cad675", 0.6)
	for band in range(7):
		draw_rect(Rect2(12, 4 + band * 4, maxf(0, size.x - 24), 4), Color(accent, 0.022 * (1 - band / 7.0)))
	draw_line(Vector2(18, 2), Vector2(minf(size.x - 20, 110), 2), accent, 2, true)
	for i in range(3):
		var x := size.x - 22 - i * 7
		draw_line(Vector2(x - 3, size.y - 8), Vector2(x, size.y - 14), Color(accent, 0.4), 1, true)
	draw_line(Vector2(3, 22), Vector2(3, minf(size.y - 18, 48)), accent, 2, true)
