class_name MarbleBadge
extends ColorRect
## Live preview of a pilot's marble. `design` previews another finish with the pilot's colours.
var player_index := 0
var design := ""
var spin := 0.35
var badge_size := 100.0
var _appearance: Array = []

func _ready() -> void:
	custom_minimum_size = Vector2(badge_size, badge_size)
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var appearance := ShaderMaterial.new()
	appearance.shader = preload("res://shaders/marble_badge.gdshader")
	appearance.set_shader_parameter("spin", spin)
	appearance.set_shader_parameter("phase", player_index * 1.7 + GameCatalog.PATTERNS.find(design) * 0.9)
	material = appearance

func _process(_delta: float) -> void:
	var player: Dictionary = Session.players[player_index]
	var current := [player.color, player.secondary, design if design != "" else player.pattern]
	if current == _appearance:
		return
	_appearance = current
	material.set_shader_parameter("primary_color", player.color)
	material.set_shader_parameter("secondary_color", player.secondary)
	material.set_shader_parameter("pattern", GameCatalog.PATTERNS.find(current[2]))
