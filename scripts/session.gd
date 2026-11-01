extends Node

signal preferences_changed
const SAVE_PATH := "user://profiles.cfg"
const DEFAULT_KEYS := {"p1_power": KEY_Q, "p1_brake": KEY_E, "p2_power": KEY_O, "p2_brake": KEY_P}
const POWER_IDS := ["EMP", "JUMP", "PHASE"]
const ITEM_IDS := ["BOOST", "REPAIR", "SHIELD", "GRIP", "MAGNET", "BARRIER", "OIL", "SHOCK"]
var profiles: Dictionary = {}
var profile_slots: Array[String] = ["Guest", "Orion"]
var active := "Guest"
var language := "en"
var light := true
var quality := "balanced"
var sound := true
var fullscreen := false
var scenario := "CITY"
var keys: Dictionary = DEFAULT_KEYS.duplicate()
var save_failed := false
var players: Array[Dictionary] = [
	{"color": Color("34e4ef"), "secondary": Color("f1f6ff"), "pattern": "STRIPES", "power": "EMP", "items": ["BOOST", "MAGNET", "OIL"]},
	{"color": Color("ef69df"), "secondary": Color("f1f6ff"), "pattern": "DUAL", "power": "JUMP", "items": ["BOOST", "MAGNET", "OIL"]}
]

func _ready() -> void:
	preload("res://localization/catalog.gd").install()
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		profiles = cfg.get_value("data", "profiles", {})
		active = cfg.get_value("data", "active", "Guest")
		var saved_slots: Array = cfg.get_value("data", "slots", [active, "Orion"])
		if saved_slots.size() == 2:
			profile_slots.assign(saved_slots)
	if profiles.is_empty():
		profiles[active] = fresh_profile()
	if not profiles.has(active):
		active = str(profiles.keys()[0])
	if not profiles.has(profile_slots[0]):
		profile_slots[0] = active
	if profile_slots[1] == profile_slots[0]:
		profile_slots[1] = "Orion" if profile_slots[0] != "Orion" else "Nova"
	if not profiles.has(profile_slots[1]):
		profiles[profile_slots[1]] = fresh_profile()
	active = profile_slots[0]
	for name in profiles:
		if not profiles[name].has("wins"):
			profiles[name].wins = profiles[name].get("p1", 0)
			profiles[name].losses = profiles[name].get("p2", 0)
			profiles[name].draws = maxi(0, profiles[name].get("matches", 0) - profiles[name].wins - profiles[name].losses)
		var defaults := fresh_profile()
		for key in defaults:
			if not profiles[name].has(key):
				profiles[name][key] = defaults[key]
	load_preferences()
	for i in range(2):
		load_player(i)
	apply_keys()
	apply_display()
	get_tree().root.close_requested.connect(save)

func fresh_profile() -> Dictionary:
	return {"language": "en", "light": true, "quality": "balanced", "sound": true, "fullscreen": false,
		"keys": DEFAULT_KEYS.duplicate(), "matches": 0, "p1": 0, "p2": 0, "wins": 0, "losses": 0, "draws": 0}

func player_name(index: int) -> String:
	return profile_slots[index]

func load_player(index: int) -> void:
	var stored: Dictionary = profiles[profile_slots[index]].get("marble", {})
	for key in players[index]:
		if stored.has(key):
			players[index][key] = stored[key]
	if not GameCatalog.valid_loadout(players[index].items):
		players[index].items = GameCatalog.DEFAULT_LOADOUT.duplicate()
	if not players[index].pattern in GameCatalog.PATTERNS:
		players[index].pattern = "SOLID"
	if not players[index].power in POWER_IDS:
		players[index].power = "EMP"

func load_preferences() -> void:
	var data: Dictionary = profiles[active]
	language = data.get("language", "en")
	light = data.get("light", true)
	quality = data.get("quality", "balanced")
	if quality not in ["balanced", "economy"]:
		quality = "balanced"
	sound = data.get("sound", true)
	fullscreen = data.get("fullscreen", false)
	scenario = data.get("scenario", "CITY")
	if not scenario in GameCatalog.SCENARIOS:
		scenario = "CITY"
	keys = data.get("keys", DEFAULT_KEYS.duplicate())
	for action in DEFAULT_KEYS:
		if not keys.has(action):
			keys[action] = DEFAULT_KEYS[action]
	TranslationServer.set_locale(language)

func save() -> void:
	var data: Dictionary = profiles[active]
	data.merge({"language": language, "light": light, "quality": quality, "sound": sound, "fullscreen": fullscreen, "keys": keys, "scenario": scenario}, true)
	for i in range(2):
		profiles[profile_slots[i]].marble = players[i].duplicate(true)
	var cfg := ConfigFile.new()
	cfg.set_value("data", "profiles", profiles)
	cfg.set_value("data", "active", active)
	cfg.set_value("data", "slots", profile_slots)
	save_failed = cfg.save(SAVE_PATH) != OK

func create_profile(profile_name: String, slot: int = 0) -> bool:
	profile_name = profile_name.strip_edges()
	if profile_name.length() < 1 or profile_name.length() > 20:
		return false
	for existing in profiles:
		if str(existing).to_lower() == profile_name.to_lower():
			return false
	for character in profile_name:
		if character.unicode_at(0) < 32:
			return false
	save()
	profiles[profile_name] = fresh_profile()
	profiles[profile_name].language = language
	profiles[profile_name].light = light
	profiles[profile_name].quality = quality
	profiles[profile_name].sound = sound
	profiles[profile_name].fullscreen = fullscreen
	profiles[profile_name].keys = keys.duplicate()
	profiles[profile_name].scenario = scenario
	select_profile(profile_name, slot)
	return true

func select_profile(profile_name: String, slot: int = 0) -> bool:
	if not profiles.has(profile_name) or profile_name == profile_slots[1 - slot]:
		return false
	save()
	profile_slots[slot] = profile_name
	active = profile_slots[0]
	if slot == 0:
		load_preferences()
		apply_keys()
		apply_display()
	load_player(slot)
	save()
	preferences_changed.emit()
	return true

func update_preferences() -> void:
	TranslationServer.set_locale(language)
	apply_display()
	save()
	preferences_changed.emit()

func apply_display() -> void:
	get_viewport().msaa_3d = Viewport.MSAA_DISABLED if quality == "economy" else Viewport.MSAA_2X
	# Expand the canvas to the monitor's aspect ratio rather than letterboxing.
	get_tree().root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	var desired := DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.window_get_mode() != desired:
		DisplayServer.window_set_mode(desired)

func apply_keys() -> void:
	for action in keys:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		InputMap.action_erase_events(action)
		var event := InputEventKey.new()
		event.physical_keycode = int(keys[action])
		InputMap.action_add_event(action, event)

func bind_key(action: String, code: int) -> bool:
	if code in [KEY_ESCAPE, KEY_F11, KEY_ENTER, KEY_SPACE, KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN, KEY_W, KEY_A, KEY_S, KEY_D, KEY_TAB]:
		return false
	for other in keys:
		if other != action and int(keys[other]) == code:
			return false
	keys[action] = code
	apply_keys()
	save()
	return true

func key_label(action: String) -> String:
	return OS.get_keycode_string(int(keys[action]))

func record_result(winner: int) -> void:
	for i in range(2):
		var data: Dictionary = profiles[profile_slots[i]]
		data.matches += 1
		if winner < 0:
			data.draws += 1
		elif winner == i:
			data.wins += 1
			data["p%d" % (i + 1)] += 1
		else:
			data.losses += 1
	save()
