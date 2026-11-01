extends Node

var race: DuelRace
var ui: Control
var audio: Node
var backdrop: Control
var bloom: ColorRect

func _ready() -> void:
	var backdrop_layer := CanvasLayer.new()
	backdrop_layer.layer = -10
	add_child(backdrop_layer)
	backdrop = Control.new()
	backdrop.set_script(preload("res://scripts/backdrop.gd"))
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop_layer.add_child(backdrop)
	var effects_layer := CanvasLayer.new()
	effects_layer.layer = 3
	add_child(effects_layer)
	bloom = ColorRect.new()
	bloom.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bloom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var effect := ShaderMaterial.new()
	effect.shader = preload("res://shaders/bloom.gdshader")
	bloom.material = effect
	bloom.visible = false
	effects_layer.add_child(bloom)
	audio = Node.new()
	audio.set_script(preload("res://scripts/audio.gd"))
	add_child(audio)
	var ui_layer := CanvasLayer.new()
	ui_layer.layer = 10
	add_child(ui_layer)
	ui = Control.new()
	ui.set_script(preload("res://scripts/interface.gd"))
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.host = self
	ui_layer.add_child(ui)

func start_race(course_seed: int) -> void:
	for player in Session.players:
		if not GameCatalog.valid_loadout(player.items):
			ui.show_error("LOADOUT_ERROR")
			return
	Session.save()
	clear_race()
	race = DuelRace.new()
	if not race.initialize(course_seed):
		race.free()
		race = null
		ui.show_error("COURSE_ERROR")
		return
	race.audio = audio
	add_child(race)
	backdrop.visible = false
	bloom.visible = false
	race.completed.connect(ui.show_results)
	race.notification.connect(ui.show_error)
	ui.show_hud()

func _process(_delta: float) -> void:
	# Tactical diagrams and daylight stay crisp; only night racing uses glow.
	if is_instance_valid(bloom):
		bloom.visible = is_instance_valid(race) and race.phase == "race" and not Session.light and Session.quality != "economy"

func clear_race() -> void:
	get_tree().paused = false
	if is_instance_valid(backdrop):
		backdrop.visible = true
	if is_instance_valid(bloom):
		bloom.visible = false
	if is_instance_valid(race):
		race.queue_free()
		race = null

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_F11:
			Session.fullscreen = not Session.fullscreen
			Session.update_preferences()
			get_viewport().set_input_as_handled()
