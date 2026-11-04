class_name MusicSynth
extends RefCounted
## Original background music, composed and synthesised in code (no audio files).
##
## A calm, futuristic loop in A minor at 90 BPM: 16 bars (about 43 s) built from a warm pad, a soft
## sub-bass pulse, a quiet plucked arpeggio with a ping-pong echo, a few glassy bell notes and a very
## light tick. The track is intentionally repetitive and low in contrast: nothing is loud, there are
## no melodies that stand out, and the arrangement grows gently over the 16 bars. Every note that
## would cross the end of the buffer wraps around to the start, so looping has no seam.
const VERSION := 1                ## bump when the composition changes: it names the cache file
const RATE := 22050
const BEAT := 14700                ## frames per beat at 90 BPM
const BEATS := 64                  ## 16 bars of 4/4
const BARS := 16
const SLOTS := 8                   ## chord slots in the loop
const HALF_BEAT := 7350
const ECHO_DELAY := 11025          ## dotted eighth note
const FRAMES := BEAT * BEATS       ## 940800 frames, 42.67 s
const TABLE := 2048
const SLOT_BEATS := 8              ## each chord lasts two bars
const PEAK := 0.62                 ## normalised peak of the rendered loop (about -4 dBFS)
## Am9 - Fmaj7 - Cmaj9 - Em7, then the cycle repeats. Midi notes.
const CHORDS := [
	{"bass": 45, "pad": [57, 60, 64, 67], "arp": [69, 72, 76, 79]},
	{"bass": 41, "pad": [57, 60, 64, 65], "arp": [65, 69, 72, 76]},
	{"bass": 48, "pad": [55, 59, 62, 64], "arp": [67, 71, 74, 79]},
	{"bass": 40, "pad": [55, 59, 62, 67], "arp": [64, 67, 71, 74]},
]
const ARP_EVEN := [0, 2, 1, 3, 2, 1, 3, 1]    ## chord-tone index for each eighth note
const ARP_ODD := [3, 1, 2, 0, 1, 2, 0, 2]
## [bar, beat, midi]: always a chord tone of the chord that is playing.
const BELLS := [[1, 0, 81], [3, 2, 84], [5, 0, 76], [7, 2, 79], [9, 0, 81], [11, 2, 88], [13, 0, 84], [15, 2, 79]]
const ARP_FIRST_BAR := 4
const TICK_FIRST_BAR := 8

var _sine := PackedFloat32Array()
var _saw := PackedFloat32Array()

## Returns the loop as interleaved signed 16-bit stereo PCM (FRAMES * 4 bytes).
func render() -> PackedByteArray:
	return encode(render_float())

## Returns [left, right] as float arrays of FRAMES samples each, peak-normalised.
func render_float() -> Array:
	_build_tables()
	var pad_l := _zeros()
	var pad_r := _zeros()
	var low := _zeros()
	var arp_l := _zeros()
	var arp_r := _zeros()
	var tick := _zeros()
	for slot in range(SLOTS):
		var chord: Dictionary = CHORDS[slot % CHORDS.size()]
		for note in chord.pad:
			_pad(pad_l, pad_r, slot * SLOT_BEATS * BEAT, SLOT_BEATS * BEAT, note, 0.05)
	for bar in range(BARS):
		var chord: Dictionary = CHORDS[(bar >> 1) % CHORDS.size()]
		var bar_start := bar * 4 * BEAT
		_bass(low, bar_start, chord.bass, 0.2)
		if bar >= ARP_FIRST_BAR:
			_bass(low, bar_start + int(2.5 * BEAT), chord.bass, 0.12)
			var pattern: Array = ARP_EVEN if bar % 2 == 0 else ARP_ODD
			for step in range(8):
				var side := 0.3 if step % 2 == 0 else 0.7
				_pluck(arp_l, arp_r, bar_start + step * HALF_BEAT, chord.arp[pattern[step]], 0.17, side)
		if bar >= TICK_FIRST_BAR:
			for step in range(4):
				_tick(tick, bar_start + step * BEAT + HALF_BEAT, 0.075 if step % 2 == 0 else 0.05)
	for bell in BELLS:
		_bell(arp_l, arp_r, bell[0] * 4 * BEAT + bell[1] * BEAT, bell[2], 0.075)
	var warm_l := _lowpass(pad_l, 2300.0)
	var warm_r := _lowpass(pad_r, 2300.0)
	var out_l := PackedFloat32Array()
	var out_r := PackedFloat32Array()
	out_l.resize(FRAMES)
	out_r.resize(FRAMES)
	# Ping-pong echo (dotted eighth) over the arpeggio and bells, wrapping around the loop.
	var delay := ECHO_DELAY
	for i in range(FRAMES):
		var j1 := i - delay
		if j1 < 0:
			j1 += FRAMES
		var j2 := j1 - delay
		if j2 < 0:
			j2 += FRAMES
		var j3 := j2 - delay
		if j3 < 0:
			j3 += FRAMES
		out_l[i] = warm_l[i] + low[i] + tick[i] + arp_l[i] + 0.42 * arp_r[j1] + 0.2 * arp_l[j2] + 0.09 * arp_r[j3]
		out_r[i] = warm_r[i] + low[i] + tick[i] * 0.8 + arp_r[i] + 0.42 * arp_l[j1] + 0.2 * arp_r[j2] + 0.09 * arp_l[j3]
	var peak := 0.0001
	for i in range(FRAMES):
		peak = maxf(peak, maxf(absf(out_l[i]), absf(out_r[i])))
	var gain := PEAK / peak
	for i in range(FRAMES):
		out_l[i] *= gain
		out_r[i] *= gain
	return [out_l, out_r]

static func encode(channels: Array) -> PackedByteArray:
	var left: PackedFloat32Array = channels[0]
	var right: PackedFloat32Array = channels[1]
	var data := PackedByteArray()
	data.resize(FRAMES * 4)
	for i in range(FRAMES):
		data.encode_s16(i * 4, int(clampf(left[i], -1.0, 1.0) * 32767.0))
		data.encode_s16(i * 4 + 2, int(clampf(right[i], -1.0, 1.0) * 32767.0))
	return data

## Wraps rendered PCM in a looping stream. `loop_end` is counted in frames.
static func make_stream(pcm: PackedByteArray) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.stereo = true
	stream.mix_rate = RATE
	stream.data = pcm
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = FRAMES
	return stream

# ---------- instruments ----------

func _zeros() -> PackedFloat32Array:
	var buffer := PackedFloat32Array()
	buffer.resize(FRAMES)
	return buffer

func _hz(midi: int) -> float:
	return 440.0 * pow(2.0, (midi - 69) / 12.0)

func _build_tables() -> void:
	_sine.resize(TABLE)
	_saw.resize(TABLE)
	var peak := 0.0
	for i in range(TABLE):
		var x := TAU * i / TABLE
		_sine[i] = sin(x)
		# A soft sawtooth: six harmonics that fall away quickly.
		var value := 0.0
		for harmonic in range(1, 7):
			value += sin(x * harmonic) / pow(harmonic, 1.3)
		_saw[i] = value
		peak = maxf(peak, absf(value))
	for i in range(TABLE):
		_saw[i] /= peak

## Sustained pad note: two slightly detuned oscillators panned apart, slow attack and release.
## The release rings on into the next chord and wraps past the end of the loop.
func _pad(left: PackedFloat32Array, right: PackedFloat32Array, start: int, sustain: int, midi: int, amp: float) -> void:
	var attack := 26460
	var release := 39690
	var scale := float(TABLE) / RATE
	var inc_a := _hz(midi) * 1.0035 * scale
	var inc_b := _hz(midi) * 0.9965 * scale
	var phase_a := float((midi * 37) % TABLE)
	var phase_b := float((midi * 91) % TABLE)
	var lfo := float((midi * 53) % TABLE)
	var lfo_inc := 0.17 * scale
	var saw := _saw
	var sine := _sine
	for i in range(sustain + release):
		var env := 1.0
		if i < attack:
			var x := i / float(attack)
			env = x * x * (3.0 - 2.0 * x)
		elif i >= sustain:
			var x := 1.0 - (i - sustain) / float(release)
			env = x * x * (3.0 - 2.0 * x)
		var level := env * amp * (1.0 + 0.07 * sine[int(lfo) & 2047])
		var a := saw[int(phase_a) & 2047]
		var b := saw[int(phase_b) & 2047]
		var index := start + i
		if index >= FRAMES:
			index -= FRAMES
		left[index] += (0.75 * a + 0.25 * b) * level
		right[index] += (0.25 * a + 0.75 * b) * level
		phase_a += inc_a
		phase_b += inc_b
		lfo += lfo_inc

## Low pulse: a sine with a touch of second harmonic and an exponential decay.
func _bass(buffer: PackedFloat32Array, start: int, midi: int, amp: float) -> void:
	var frames := 33000
	var inc := _hz(midi) * TABLE / RATE
	var decay := exp(-1.0 / (0.5 * RATE))
	var env := amp
	var phase := 0.0
	var sine := _sine
	for i in range(frames):
		var fade := minf(1.0, i / 300.0)
		var value := (sine[int(phase) & 2047] + 0.55 * sine[int(phase * 2.0) & 2047]) * env * fade
		var index := start + i
		if index >= FRAMES:
			index -= FRAMES
		buffer[index] += value
		phase += inc
		env *= decay

## Soft pluck for the arpeggio: a sine with a quiet octave that fades faster than the fundamental.
func _pluck(left: PackedFloat32Array, right: PackedFloat32Array, start: int, midi: int, amp: float, pan: float) -> void:
	var frames := 15000
	var inc := _hz(midi) * TABLE / RATE
	var decay := exp(-1.0 / (0.2 * RATE))
	var env := amp
	var phase := 0.0
	var sine := _sine
	for i in range(frames):
		var fade := minf(1.0, i / 90.0)
		var value := (sine[int(phase) & 2047] + 0.35 * env / amp * sine[int(phase * 2.0) & 2047]) * env * fade
		var index := start + i
		if index >= FRAMES:
			index -= FRAMES
		left[index] += value * (1.0 - pan)
		right[index] += value * pan
		phase += inc
		env *= decay

## Glass bell: two-operator FM whose brightness fades as the note rings out.
func _bell(left: PackedFloat32Array, right: PackedFloat32Array, start: int, midi: int, amp: float) -> void:
	var frames := 62000
	var hz := _hz(midi)
	for i in range(frames):
		var t := i / float(RATE)
		var env := exp(-t / 0.9) * minf(1.0, i / 200.0)
		var brightness := 1.4 * exp(-t / 0.5)
		var value := sin(TAU * hz * t + brightness * sin(TAU * hz * 3.5 * t)) * env * amp
		var index := start + i
		if index >= FRAMES:
			index -= FRAMES
		left[index] += value * 0.6
		right[index] += value * 0.4

## A very light tick: a few milliseconds of high-passed noise from a fixed random sequence.
func _tick(buffer: PackedFloat32Array, start: int, amp: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 90210 + start
	var previous := 0.0
	for i in range(520):
		var noise := rng.randf() * 2.0 - 1.0
		var value := (noise - previous) * 0.5 * exp(-i / 90.0) * amp
		previous = noise
		var index := start + i
		if index >= FRAMES:
			index -= FRAMES
		buffer[index] += value

## One-pole low-pass, run twice around the loop so the state at the seam is continuous.
func _lowpass(source: PackedFloat32Array, cutoff: float) -> PackedFloat32Array:
	var result := _zeros()
	var alpha := 1.0 - exp(-TAU * cutoff / RATE)
	var state := 0.0
	for pass_index in range(2):
		for i in range(FRAMES):
			state += alpha * (source[i] - state)
			if pass_index == 1:
				result[i] = state
	return result
