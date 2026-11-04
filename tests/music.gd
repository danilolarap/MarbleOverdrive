extends Node
## Background music: deterministic, seamless loop, calm level and no abrupt changes.
## Run: godot --headless --path . --fixed-fps 120 res://tests/music.tscn
var failures: Array[String] = []

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)

func _ready() -> void:
	call_deferred("run")

func rms_db(left: PackedFloat32Array, right: PackedFloat32Array, from: int, to: int) -> float:
	var total := 0.0
	for i in range(from, to):
		total += left[i] * left[i] + right[i] * right[i]
	return 10.0 * log(total / float((to - from) * 2) + 1e-12) / log(10.0)

func run() -> void:
	var started := Time.get_ticks_msec()
	var synth := MusicSynth.new()
	var channels := synth.render_float()
	var render_ms := Time.get_ticks_msec() - started
	var left: PackedFloat32Array = channels[0]
	var right: PackedFloat32Array = channels[1]
	var frames := MusicSynth.FRAMES
	check(left.size() == frames and right.size() == frames, "The loop must be exactly FRAMES long")
	check(frames == MusicSynth.BEAT * MusicSynth.BEATS and MusicSynth.BEATS % 4 == 0, "The loop must be a whole number of bars")

	var peak := 0.0
	var largest_step := 0.0
	var steps: Array[float] = []
	for i in range(1, frames):
		peak = maxf(peak, maxf(absf(left[i]), absf(right[i])))
		var step := absf(left[i] - left[i - 1])
		largest_step = maxf(largest_step, step)
		if i % 64 == 0:
			steps.append(step)
	steps.sort()
	var p99: float = steps[int(steps.size() * 0.99)]
	check(peak <= MusicSynth.PEAK + 0.001 and peak > 0.4, "Peak level out of range: %.3f" % peak)
	check(largest_step < 0.3, "A sudden jump of %.3f would click" % largest_step)

	# Looping from the last frame to the first must be as smooth as any other step.
	for channel in [left, right]:
		var seam := absf(channel[0] - channel[frames - 1])
		check(seam <= maxf(p99, 0.01) * 1.5, "Audible seam at the loop point: %.4f (typical step %.4f)" % [seam, p99])

	# Calm and steady: the whole loop stays in a narrow loudness range, and is never loud.
	var bar_frames := frames / MusicSynth.BARS
	var lowest := 0.0
	var highest := -100.0
	for bar in range(MusicSynth.BARS):
		var level := rms_db(left, right, bar * bar_frames, (bar + 1) * bar_frames)
		lowest = minf(lowest, level)
		highest = maxf(highest, level)
		check(level < -14.0 and level > -30.0, "Bar %d level %.1f dB is not a calm background level" % [bar + 1, level])
	check(highest - lowest < 4.0, "Loudness varies by %.1f dB across the loop" % (highest - lowest))

	# Mono-compatible: no cancellation between the channels.
	var correlation := 0.0
	var energy := 0.0
	for i in range(0, frames, 7):
		correlation += left[i] * right[i]
		energy += left[i] * left[i]
	check(correlation / energy > 0.5, "Channels are too out of phase for mono speakers")

	# Same bytes every time, and the stream loops over exactly the whole buffer.
	var pcm := MusicSynth.encode(channels)
	check(pcm.size() == frames * 4, "PCM size mismatch")
	check(pcm == MusicSynth.new().render(), "The music is not deterministic")
	var stream := MusicSynth.make_stream(pcm)
	check(stream.loop_mode == AudioStreamWAV.LOOP_FORWARD and stream.loop_begin == 0 and stream.loop_end == frames, "The stream does not loop over the whole track")
	check(absf(stream.get_length() - float(frames) / MusicSynth.RATE) < 0.01, "Stream length mismatch: %.3f" % stream.get_length())

	# The setting exists, defaults to on, survives profiles and is translated.
	check(Session.music, "Music must default to on")
	check(Session.fresh_profile().get("music", false), "New profiles must start with music on")
	for locale in ["en", "es"]:
		TranslationServer.set_locale(locale)
		check(tr("MUSIC") != "MUSIC", "Missing localized text: MUSIC (%s)" % locale)

	print("MUSIC render=%d ms peak=%.3f loudness=%.1f..%.1f dB seam-limit=%.4f" % [render_ms, peak, lowest, highest, p99 * 1.5])
	print("PASS: background music" if failures.is_empty() else "FAIL: %d checks" % failures.size())
	get_tree().quit(0 if failures.is_empty() else 1)
