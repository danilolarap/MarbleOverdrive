extends Node
## Original sound effects synthesised in code (no audio files): layered tones, glides,
## filtered noise and soft clipping, rendered once to PCM and cached. A small voice pool
## lets effects overlap, and two looping rumbles follow each marble's speed.
const RATE := 22050
const VOICES := 8
const EFFECTS := ["ui_click", "ui_select", "invalid", "place_equipment", "place_trap", "countdown", "go",
	"boost", "repair", "shield", "grip", "hit_magnet", "hit_barrier", "hit_oil", "hit_shock", "hazard",
	"emp", "jump", "phase", "brake", "recover", "gap", "land", "finish"]
var voices: Array[AudioStreamPlayer] = []
var rolling: Array[AudioStreamPlayer] = []
var clips: Dictionary = {}
var _next_voice := 0
## Background music: rendered once in a thread, cached on disk, then looped with soft fades.
const MUSIC_DB := -13.0
const MUSIC_RACE_DB := -19.0
var music_player: AudioStreamPlayer
var _music_thread: Thread
var _last_roll_msec := 0
var _prewarm: Array = []
var player: AudioStreamPlayer:
	get:
		return voices[0] if not voices.is_empty() else null

func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		return
	for i in range(VOICES):
		var voice := AudioStreamPlayer.new()
		add_child(voice)
		voices.append(voice)
	for i in range(2):
		var rumble := AudioStreamPlayer.new()
		rumble.volume_db = -80
		add_child(rumble)
		rolling.append(rumble)
	_prewarm = EFFECTS.duplicate()
	_start_music()

func _process(delta: float) -> void:
	_update_music(delta)
	# Render the library a couple of clips per frame instead of stalling the first menu click.
	for i in range(2):
		if _prewarm.is_empty():
			return
		var id: String = _prewarm.pop_front()
		if not clips.has(id):
			clips[id] = _render(id)

## Plays a named effect. Unknown names fall back to a soft click.
func play(id: String, pitch: float = 1.0, volume_db: float = 0.0) -> void:
	if not Session.sound or voices.is_empty():
		return
	if not clips.has(id):
		clips[id] = _render(id)
	var voice := voices[_next_voice]
	for offset in range(VOICES):
		var candidate := voices[(_next_voice + offset) % VOICES]
		if not candidate.playing:
			voice = candidate
			break
	_next_voice = (voices.find(voice) + 1) % VOICES
	voice.stream = clips[id]
	voice.pitch_scale = pitch
	voice.volume_db = volume_db
	voice.play()

## Kept for older callers: a plain tone with a short envelope.
func tone(hz: float, duration: float = 0.12) -> void:
	if not Session.sound or voices.is_empty():
		return
	var key := "tone/%.0f/%.3f" % [hz, duration]
	if not clips.has(key):
		clips[key] = _encode(_tone(hz, hz, duration, "sine", 0.3, 0.004, 1.5))
	play(key)

## Rolling rumble per marble: louder and higher with speed, silent in the air or when stopped.
func set_rolling(index: int, speed: float, on_ground: bool) -> void:
	if index >= rolling.size():
		return
	_last_roll_msec = Time.get_ticks_msec()
	var rumble := rolling[index]
	var amount := clampf(speed / 39.0, 0.0, 1.2) if on_ground and Session.sound else 0.0
	if amount < 0.03:
		if rumble.playing:
			rumble.stop()
		return
	if not clips.has("roll"):
		clips["roll"] = _render_roll()
	if not rumble.playing:
		rumble.stream = clips["roll"]
		rumble.play()
	rumble.volume_db = linear_to_db(0.08 + amount * 0.32) - 4.0
	rumble.pitch_scale = 0.55 + amount * 0.8

func stop_rolling() -> void:
	_last_roll_msec = 0
	for rumble in rolling:
		rumble.stop()

# ---------- background music ----------

func _music_cache_path() -> String:
	return "user://music_v%d.pcm" % MusicSynth.VERSION

func _start_music() -> void:
	var path := _music_cache_path()
	if FileAccess.file_exists(path):
		var cached := FileAccess.get_file_as_bytes(path)
		if cached.size() == MusicSynth.FRAMES * 4:
			_create_music(cached)
			return
	# First launch: compose it in a thread so the menu never stalls (about 3 s).
	_music_thread = Thread.new()
	_music_thread.start(func() -> PackedByteArray: return MusicSynth.new().render())

func _create_music(pcm: PackedByteArray) -> void:
	music_player = AudioStreamPlayer.new()
	music_player.stream = MusicSynth.make_stream(pcm)
	music_player.volume_db = -80.0
	add_child(music_player)
	music_player.play()

func _update_music(delta: float) -> void:
	if _music_thread and not _music_thread.is_alive():
		var pcm: PackedByteArray = _music_thread.wait_to_finish()
		_music_thread = null
		var file := FileAccess.open(_music_cache_path(), FileAccess.WRITE)
		if file:
			file.store_buffer(pcm)
			file.close()
		_create_music(pcm)
	if music_player == null:
		return
	# The music sits lower while marbles are rolling so the race effects stay clear.
	var racing := Time.get_ticks_msec() - _last_roll_msec < 400
	var target := -80.0
	if Session.sound and Session.music:
		target = MUSIC_RACE_DB if racing else MUSIC_DB
	music_player.volume_db = move_toward(music_player.volume_db, target, 40.0 * delta)
	music_player.stream_paused = target <= -79.0 and music_player.volume_db <= -79.0

func _exit_tree() -> void:
	if _music_thread:
		_music_thread.wait_to_finish()
		_music_thread = null
	if music_player:
		music_player.stop()
		music_player.stream = null
	for voice in voices + rolling:
		voice.stop()
		voice.stream = null
	clips.clear()

# ---------- synthesis ----------

func _render(id: String) -> AudioStreamWAV:
	var out := PackedFloat32Array()
	match id:
		"ui_click":
			out = _tone(1500, 1100, 0.04, "tri", 0.22, 0.002, 3.0)
			_mix(out, _noise(0.02, 0.08, 0.6, 0.2, 2.0), 0.0)
		"ui_select":
			out = _tone(660, 700, 0.09, "tri", 0.2, 0.003, 2.0)
			_mix(out, _tone(990, 1050, 0.11, "sine", 0.16, 0.003, 2.0), 0.035)
		"invalid":
			out = _tone(220, 200, 0.09, "square", 0.18, 0.003, 1.0)
			_mix(out, _tone(165, 150, 0.14, "square", 0.18, 0.003, 1.2), 0.1)
		"place_equipment":
			for k in range(3):
				_mix(out, _tone([523.0, 659.0, 784.0][k], [523.0, 659.0, 784.0][k], 0.22, "bell", 0.2, 0.002, 2.5), k * 0.055)
		"place_trap":
			out = _tone(392, 330, 0.12, "square", 0.16, 0.002, 1.6)
			_mix(out, _tone(262, 196, 0.2, "bell", 0.2, 0.002, 2.0), 0.06)
			_mix(out, _noise(0.06, 0.12, 0.7, 0.3, 2.0), 0.0)
		"countdown":
			out = _tone(880, 880, 0.1, "bell", 0.24, 0.002, 2.2)
		"go":
			for k in range(3):
				_mix(out, _tone([523.0, 659.0, 1046.0][k], [523.0, 659.0, 1046.0][k] * 1.02, 0.45, "saw", 0.12, 0.004, 1.4), 0.0)
			_mix(out, _noise(0.35, 0.12, 0.1, 0.8, 1.5), 0.0)
		"boost":
			out = _tone(180, 900, 0.42, "saw", 0.2, 0.01, 1.2)
			_mix(out, _noise(0.4, 0.14, 0.15, 0.9, 1.3), 0.0)
		"repair":
			for k in range(4):
				_mix(out, _tone(880.0 * pow(1.26, k), 880.0 * pow(1.26, k), 0.18, "bell", 0.15, 0.002, 2.5), k * 0.05)
		"shield":
			out = _tone(440, 470, 0.5, "chorus", 0.18, 0.03, 1.0)
			_mix(out, _tone(660, 700, 0.45, "sine", 0.1, 0.05, 1.0), 0.04)
		"grip":
			out = _tone(300, 600, 0.12, "tri", 0.2, 0.003, 1.5)
			_mix(out, _noise(0.04, 0.14, 0.9, 0.4, 2.0), 0.0)
		"hit_magnet":
			out = _tone(520, 110, 0.38, "wobble", 0.22, 0.004, 1.1)
		"hit_barrier":
			out = _tone(110, 45, 0.35, "sine", 0.45, 0.001, 2.0)
			_mix(out, _noise(0.22, 0.35, 0.9, 0.1, 2.2), 0.0)
		"hit_oil":
			out = _noise(0.32, 0.25, 0.08, 0.45, 1.2)
			_mix(out, _tone(300, 120, 0.3, "sine", 0.12, 0.01, 1.2), 0.0)
		"hit_shock":
			out = _tone(1200, 400, 0.3, "zap", 0.2, 0.001, 1.3)
			_mix(out, _noise(0.28, 0.2, 1.0, 0.6, 1.0), 0.0)
		"hazard":
			out = _tone(150, 60, 0.22, "sine", 0.4, 0.001, 2.0)
			_mix(out, _noise(0.12, 0.25, 0.8, 0.15, 2.5), 0.0)
		"emp":
			out = _tone(90, 35, 0.6, "sine", 0.5, 0.002, 1.6)
			_mix(out, _tone(1600, 200, 0.35, "zap", 0.14, 0.001, 1.4), 0.0)
			_mix(out, _noise(0.4, 0.2, 0.5, 0.05, 1.8), 0.0)
		"jump":
			out = _tone(220, 880, 0.24, "tri", 0.26, 0.004, 1.3)
			_mix(out, _tone(330, 1320, 0.2, "sine", 0.1, 0.004, 1.5), 0.02)
		"phase":
			out = _tone(700, 1400, 0.3, "chorus", 0.15, 0.02, 1.2)
			_mix(out, _noise(0.32, 0.16, 0.2, 0.7, 1.0), 0.0)
		"brake":
			out = _noise(0.16, 0.16, 0.9, 0.5, 1.5)
			_mix(out, _tone(1800, 1500, 0.14, "sine", 0.05, 0.005, 1.5), 0.0)
		"recover":
			out = _tone(900, 300, 0.18, "tri", 0.18, 0.003, 1.0)
			_mix(out, _tone(300, 900, 0.2, "tri", 0.18, 0.003, 1.4), 0.17)
		"gap":
			out = _noise(0.5, 0.18, 0.05, 0.6, 0.8)
			_mix(out, _tone(400, 700, 0.45, "sine", 0.06, 0.05, 1.0), 0.0)
		"land":
			out = _tone(120, 55, 0.25, "sine", 0.45, 0.001, 2.0)
			_mix(out, _noise(0.1, 0.2, 0.6, 0.1, 2.5), 0.0)
		"finish":
			var notes := [523.0, 659.0, 784.0, 1046.0]
			for k in range(notes.size()):
				_mix(out, _tone(notes[k], notes[k], 0.5 if k == 3 else 0.16, "saw", 0.13, 0.003, 1.6 if k == 3 else 2.0), k * 0.11)
				_mix(out, _tone(notes[k] * 2.0, notes[k] * 2.0, 0.3, "bell", 0.07, 0.002, 2.5), k * 0.11)
		_:
			out = _tone(1000, 900, 0.04, "tri", 0.2, 0.002, 3.0)
	return _encode(out)

func _render_roll() -> AudioStreamWAV:
	# Half a second of low filtered noise and a faint hum, built to loop.
	var count := RATE / 2
	var out := PackedFloat32Array()
	out.resize(count)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var low := 0.0
	for i in range(count):
		low += (rng.randf_range(-1, 1) - low) * 0.06
		var hum := sin(i * TAU * 54.0 / RATE) * 0.25 + sin(i * TAU * 108.0 / RATE) * 0.1
		out[i] = low * 1.6 + hum * 0.4
	var clip := _encode(out)
	clip.loop_mode = AudioStreamWAV.LOOP_FORWARD
	clip.loop_begin = 0
	clip.loop_end = count
	return clip

## A note gliding exponentially from f0 to f1, with a quick attack and a power-curve release.
func _tone(f0: float, f1: float, duration: float, wave: String, volume: float, attack: float, curve: float) -> PackedFloat32Array:
	var count := int(duration * RATE)
	var out := PackedFloat32Array()
	out.resize(count)
	var phase := 0.0
	var second := 0.0
	for i in range(count):
		var t := i / float(count)
		var freq := f0 * pow(f1 / f0, t)
		phase += freq / RATE
		second += freq * 1.007 / RATE
		var x := phase * TAU
		var v := 0.0
		match wave:
			"sine":
				v = sin(x)
			"tri":
				v = 2.0 * absf(2.0 * fposmod(phase, 1.0) - 1.0) - 1.0
			"square":
				v = tanh(sin(x) * 4.0) * 0.8
			"saw":
				v = sin(x) + sin(2 * x) / 2 + sin(3 * x) / 3 + sin(4 * x) / 4
				v *= 0.6
			"bell":
				v = sin(x) + 0.5 * sin(x * 2.76) * (1 - t) + 0.25 * sin(x * 5.4) * (1 - t) * (1 - t)
				v *= 0.6
			"chorus":
				v = (sin(x) + sin(second * TAU)) * 0.5
			"wobble":
				v = sin(x + sin(i * TAU * 14.0 / RATE) * 2.5)
			"zap":
				v = tanh(sin(x + sin(x * 3.1) * 3.0) * 3.0) * 0.7
		var envelope := minf(1.0, i / maxf(1.0, attack * RATE)) * pow(1.0 - t, curve)
		out[i] = v * envelope * volume
	return out

## White noise through a one-pole low-pass whose cutoff (0..1) glides from c0 to c1.
func _noise(duration: float, volume: float, c0: float, c1: float, curve: float) -> PackedFloat32Array:
	var count := int(duration * RATE)
	var out := PackedFloat32Array()
	out.resize(count)
	var rng := RandomNumberGenerator.new()
	rng.seed = count
	var state := 0.0
	for i in range(count):
		var t := i / float(count)
		var cutoff := lerpf(c0, c1, t)
		state += (rng.randf_range(-1, 1) - state) * clampf(cutoff, 0.01, 1.0)
		out[i] = state * volume * minf(1.0, i / 40.0) * pow(1.0 - t, curve)
	return out

func _mix(target: PackedFloat32Array, source: PackedFloat32Array, at: float) -> void:
	var offset := int(at * RATE)
	if target.size() < offset + source.size():
		target.resize(offset + source.size())
	for i in range(source.size()):
		target[offset + i] += source[i]

func _encode(samples: PackedFloat32Array) -> AudioStreamWAV:
	var clip := AudioStreamWAV.new()
	clip.format = AudioStreamWAV.FORMAT_16_BITS
	clip.mix_rate = RATE
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in range(samples.size()):
		bytes.encode_s16(i * 2, int(tanh(samples[i] * 1.4) * 0.8 * 32767))
	clip.data = bytes
	return clip
