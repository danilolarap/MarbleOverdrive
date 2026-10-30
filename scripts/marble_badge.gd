class_name MarbleBadge
extends ColorRect
var player_index := 0
var _appearance: Array = []

func _ready() -> void:
	custom_minimum_size = Vector2(100, 100)
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var appearance := ShaderMaterial.new()
	appearance.shader = preload("res://shaders/marble_badge.gdshader")
	material = appearance

func _process(_delta: float) -> void:
	var player: Dictionary = Session.players[player_index]
	var current := [player.color, player.secondary, player.pattern]
	if current == _appearance:
		return
	_appearance = current
	material.set_shader_parameter("primary_color", player.color)
	material.set_shader_parameter("secondary_color", player.secondary)
	material.set_shader_parameter("pattern", GameCatalog.PATTERNS.find(player.pattern))
