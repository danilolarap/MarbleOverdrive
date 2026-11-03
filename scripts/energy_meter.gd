class_name EnergyMeter
extends Control
## Six energy cells: spent cells glow, the rest stay hollow, overspend turns red.
var spent := 0
var budget := GameCatalog.BUDGET
var tint := Color("d2df79")

func _ready() -> void:
	custom_minimum_size = Vector2(220, 22)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_spent(value: int) -> void:
	spent = value
	queue_redraw()

func _draw() -> void:
	var gap := 5.0
	var cell := (size.x - gap * (budget - 1)) / budget
	for i in range(budget):
		var rect := Rect2(i * (cell + gap), 2, cell, size.y - 4)
		var color := Color("d35172") if spent > budget else tint
		if i < spent:
			draw_rect(rect, color)
		else:
			draw_rect(rect, Color(color, 0.12))
			draw_rect(rect, Color(color, 0.5), false, 1.5)
