class_name ItemIcon
extends Control
## A square badge with an item or power symbol on a tinted plate.
var kind := ""
var tint := Color.WHITE
var icon_size := 44.0
var dimmed := false:
	set(value):
		dimmed = value
		queue_redraw()

func _ready() -> void:
	custom_minimum_size = Vector2(icon_size, icon_size)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, Vector2(icon_size, icon_size))
	var plate := Color(tint, 0.12 if dimmed else 0.2)
	draw_rect(rect, plate)
	draw_rect(rect, Color(tint, 0.35 if dimmed else 0.9), false, 2.0)
	ItemGlyph.draw(self, rect.get_center(), kind, Color(tint, 0.45) if dimmed else tint, icon_size / 26.0)
