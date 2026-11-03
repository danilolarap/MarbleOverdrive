extends Button

func _ready() -> void:
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)
	pressed.connect(queue_redraw)


func _draw() -> void:
	var cyan := Color("20cfe0") if not Session.light else Color("168b9b")
	var magenta := Color("ec3d91") if not Session.light else Color("b34d83")
	var yellow := Color("cbd878") if not Session.light else Color("829344")

	var active := is_hovered() or has_focus()
	var pressed_now := is_pressed()

	var accent := cyan

	if pressed_now:
		accent = yellow
	elif active:
		accent = magenta

	# Fine upper highlight.
	draw_line(
		Vector2(12, 2),
		Vector2(size.x - 12, 2),
		Color(accent, 0.8 if active else 0.35),
		2.0,
		true
	)

	# Futuristic corner details.
	var corner := 10.0
	var detail := Color(accent, 0.85 if active else 0.5)

	draw_line(Vector2(2, corner), Vector2(2, 2), detail, 2.0)
	draw_line(Vector2(2, 2), Vector2(corner, 2), detail, 2.0)

	draw_line(
		Vector2(size.x - corner, size.y - 2),
		Vector2(size.x - 2, size.y - 2),
		detail,
		2.0
	)
	draw_line(
		Vector2(size.x - 2, size.y - corner),
		Vector2(size.x - 2, size.y - 2),
		detail,
		2.0
	)

	# Pilot-inspired signal indicator.
	draw_circle(
		Vector2(10, size.y / 2),
		3.0 if active else 2.0,
		Color(accent, 0.95)
	)

	if active:
		draw_line(
			Vector2(18, size.y - 4),
			Vector2(size.x - 18, size.y - 4),
			Color(accent, 0.9),
			2.0,
			true
		)
