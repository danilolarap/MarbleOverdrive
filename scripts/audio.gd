extends Node
## Prebaked PCM effects avoid a continuously running scripted audio generator.
var player: AudioStreamPlayer
var clips: Dictionary = {}

func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		return
	player = AudioStreamPlayer.new()
	add_child(player)

func tone(hz: float, duration: float = 0.12) -> void:
	if not Session.sound or not is_instance_valid(player):
		return
	var key := "%.0f/%.3f" % [hz, duration]
	if not clips.has(key):
		var clip := AudioStreamWAV.new()
		clip.format = AudioStreamWAV.FORMAT_16_BITS
		clip.mix_rate = 22050
		var count := int(duration * clip.mix_rate)
		var bytes := PackedByteArray()
		bytes.resize(count * 2)
		for i in range(count):
			var envelope := minf(1, i / 100.0) * minf(1, (count - i) / 300.0)
			var sample := sin(i * hz * TAU / clip.mix_rate) * 0.12 * envelope
			bytes.encode_s16(i * 2, int(sample * 32767))
		clip.data = bytes
		clips[key] = clip
	player.stream = clips[key]
	player.play()

func _exit_tree() -> void:
	if is_instance_valid(player):
		player.stop()
		player.stream = null
	clips.clear()
