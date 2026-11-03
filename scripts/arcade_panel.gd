extends PanelContainer

## Minimal arcade panel: clean surfaces without repeated decorative frames.

func _draw() -> void:
	var accent := Color("126678", 0.42) if Session.light else Color("cad675", 0.42)
	draw_line(Vector2(16, 2), Vector2(minf(size.x - 16, 64), 2), accent, 2, true)
