extends Node

var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_streams: Dictionary = {}

const SFX_POOL_SIZE := 12
const SAMPLE_RATE := 22050


func _ready() -> void:
	for i in SFX_POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.volume_db = -6.0
		add_child(player)
		_sfx_players.append(player)

	_generate_all_sfx()


func play_sfx(sfx_name: String, pitch_variation: float = 0.1) -> void:
	if not _sfx_streams.has(sfx_name):
		return
	var player: AudioStreamPlayer = _get_free_player()
	if player == null:
		return
	player.stream = _sfx_streams[sfx_name]
	player.pitch_scale = randf_range(1.0 - pitch_variation, 1.0 + pitch_variation)
	player.play()


func _get_free_player() -> AudioStreamPlayer:
	for player in _sfx_players:
		if not player.playing:
			return player
	# All busy — steal the first one
	return _sfx_players[0]


# --- Procedural SFX generation ---

func _generate_all_sfx() -> void:
	_sfx_streams["detonation"] = _gen_detonation()
	_sfx_streams["enemy_destroy"] = _gen_enemy_destroy()
	_sfx_streams["enemy_impact"] = _gen_enemy_impact()
	_sfx_streams["click_rejected"] = _gen_click_rejected()
	_sfx_streams["mirv_split"] = _gen_mirv_split()
	_sfx_streams["multi_kill"] = _gen_multi_kill()
	_sfx_streams["silo_destroyed"] = _gen_silo_destroyed()
	_sfx_streams["purchase"] = _gen_purchase()


func _make_stream(samples: PackedFloat32Array) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false

	var data := PackedByteArray()
	for i in samples.size():
		var val: int = clampi(int(samples[i] * 32767.0), -32768, 32767)
		# Little-endian 16-bit signed
		data.append(val & 0xFF)
		data.append((val >> 8) & 0xFF)

	stream.data = data
	return stream


# Blast detonation: low rumble with noise burst
func _gen_detonation() -> AudioStreamWAV:
	var length: float = 0.35
	var count: int = int(SAMPLE_RATE * length)
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in count:
		var t: float = float(i) / float(SAMPLE_RATE)
		var env: float = (1.0 - t / length) * (1.0 - t / length)
		var low: float = sin(TAU * 65.0 * t + sin(TAU * 30.0 * t) * 2.0)
		var noise: float = randf_range(-1.0, 1.0)
		samples[i] = (low * 0.5 + noise * 0.5) * env * 0.7
	return _make_stream(samples)


# Enemy destroyed: quick rising blip
func _gen_enemy_destroy() -> AudioStreamWAV:
	var length: float = 0.15
	var count: int = int(SAMPLE_RATE * length)
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in count:
		var t: float = float(i) / float(SAMPLE_RATE)
		var env: float = (1.0 - t / length)
		var freq: float = 400.0 + 800.0 * (t / length)
		samples[i] = sin(TAU * freq * t) * env * 0.5
	return _make_stream(samples)


# Enemy impact on planet: heavy thud
func _gen_enemy_impact() -> AudioStreamWAV:
	var length: float = 0.3
	var count: int = int(SAMPLE_RATE * length)
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in count:
		var t: float = float(i) / float(SAMPLE_RATE)
		var env: float = (1.0 - t / length) * (1.0 - t / length)
		var freq: float = 90.0 * (1.0 - t / length * 0.5)
		var noise: float = randf_range(-1.0, 1.0)
		samples[i] = (sin(TAU * freq * t) * 0.6 + noise * 0.4) * env * 0.6
	return _make_stream(samples)


# Click rejected: short low buzz
func _gen_click_rejected() -> AudioStreamWAV:
	var length: float = 0.12
	var count: int = int(SAMPLE_RATE * length)
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in count:
		var t: float = float(i) / float(SAMPLE_RATE)
		var env: float = (1.0 - t / length)
		# Square-ish wave at low freq
		var wave: float = sign(sin(TAU * 150.0 * t))
		samples[i] = wave * env * 0.3
	return _make_stream(samples)


# MIRV split: metallic scatter
func _gen_mirv_split() -> AudioStreamWAV:
	var length: float = 0.25
	var count: int = int(SAMPLE_RATE * length)
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in count:
		var t: float = float(i) / float(SAMPLE_RATE)
		var env: float = (1.0 - t / length)
		var tone1: float = sin(TAU * 520.0 * t)
		var tone2: float = sin(TAU * 780.0 * t + sin(TAU * 200.0 * t) * 3.0)
		var noise: float = randf_range(-1.0, 1.0)
		samples[i] = (tone1 * 0.3 + tone2 * 0.3 + noise * 0.2) * env * 0.5
	return _make_stream(samples)


# Multi kill: rising triumphant chord
func _gen_multi_kill() -> AudioStreamWAV:
	var length: float = 0.4
	var count: int = int(SAMPLE_RATE * length)
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in count:
		var t: float = float(i) / float(SAMPLE_RATE)
		var env: float = (1.0 - t / length)
		var chord: float = sin(TAU * 440.0 * t) + sin(TAU * 554.0 * t) + sin(TAU * 659.0 * t)
		samples[i] = chord / 3.0 * env * 0.5
	return _make_stream(samples)


# Silo destroyed: deep explosion rumble
func _gen_silo_destroyed() -> AudioStreamWAV:
	var length: float = 0.5
	var count: int = int(SAMPLE_RATE * length)
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in count:
		var t: float = float(i) / float(SAMPLE_RATE)
		var env: float = (1.0 - t / length) * (1.0 - t / length)
		var low: float = sin(TAU * 45.0 * t + sin(TAU * 20.0 * t) * 4.0)
		var noise: float = randf_range(-1.0, 1.0)
		samples[i] = (low * 0.5 + noise * 0.5) * env * 0.8
	return _make_stream(samples)


# Purchase upgrade: bright confirmation ding
func _gen_purchase() -> AudioStreamWAV:
	var length: float = 0.2
	var count: int = int(SAMPLE_RATE * length)
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in count:
		var t: float = float(i) / float(SAMPLE_RATE)
		var env: float = (1.0 - t / length)
		var freq: float = 880.0
		if t > 0.08:
			freq = 1100.0
		samples[i] = sin(TAU * freq * t) * env * 0.4
	return _make_stream(samples)
