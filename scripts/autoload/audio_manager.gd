extends Node

var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_streams: Dictionary = {}

const SFX_POOL_SIZE := 12
const SAMPLE_RATE := 22050
const SFX_DIR := "res://assets/audio/sfx/"


func _ready() -> void:
	for i in SFX_POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.volume_db = -6.0
		add_child(player)
		_sfx_players.append(player)

	_load_or_generate_all()


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
	return _sfx_players[0]


# --- Load from .wav files or generate procedurally ---

func _load_or_generate_all() -> void:
	var sfx_names: Array[String] = [
		"detonation", "enemy_destroy", "enemy_impact", "click_rejected",
		"mirv_split", "multi_kill", "silo_destroyed", "purchase",
	]

	# Generate all procedurally first
	var generators: Dictionary = {
		"detonation": _gen_detonation,
		"enemy_destroy": _gen_enemy_destroy,
		"enemy_impact": _gen_enemy_impact,
		"click_rejected": _gen_click_rejected,
		"mirv_split": _gen_mirv_split,
		"multi_kill": _gen_multi_kill,
		"silo_destroyed": _gen_silo_destroyed,
		"purchase": _gen_purchase,
	}

	for sfx_name in sfx_names:
		var wav_path: String = SFX_DIR + sfx_name + ".wav"

		# Try loading from file first (user-replaceable)
		if ResourceLoader.exists(wav_path):
			var loaded: AudioStream = load(wav_path)
			if loaded:
				_sfx_streams[sfx_name] = loaded
				continue

		# Fall back to procedural generation
		var samples: PackedFloat32Array = generators[sfx_name].call()
		var stream: AudioStreamWAV = _samples_to_stream(samples)
		_sfx_streams[sfx_name] = stream

		# Save as .wav so the user can replace it later
		_save_wav(wav_path, samples)


# --- WAV file I/O ---

func _samples_to_stream(samples: PackedFloat32Array) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false

	var data := PackedByteArray()
	for i in samples.size():
		var val: int = clampi(int(samples[i] * 32767.0), -32768, 32767)
		data.append(val & 0xFF)
		data.append((val >> 8) & 0xFF)

	stream.data = data
	return stream


func _save_wav(path: String, samples: PackedFloat32Array) -> void:
	# Ensure directory exists
	DirAccess.make_dir_recursive_absolute(SFX_DIR)

	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return

	var num_samples: int = samples.size()
	var data_size: int = num_samples * 2  # 16-bit = 2 bytes per sample
	var file_size: int = 36 + data_size  # Total file size minus 8 for RIFF header

	# RIFF header
	file.store_buffer("RIFF".to_ascii_buffer())
	file.store_32(file_size)
	file.store_buffer("WAVE".to_ascii_buffer())

	# fmt chunk
	file.store_buffer("fmt ".to_ascii_buffer())
	file.store_32(16)       # Chunk size
	file.store_16(1)        # PCM format
	file.store_16(1)        # Mono
	file.store_32(SAMPLE_RATE)
	file.store_32(SAMPLE_RATE * 2)  # Byte rate
	file.store_16(2)        # Block align
	file.store_16(16)       # Bits per sample

	# data chunk
	file.store_buffer("data".to_ascii_buffer())
	file.store_32(data_size)

	for i in num_samples:
		var val: int = clampi(int(samples[i] * 32767.0), -32768, 32767)
		file.store_16(val)

	file.close()


# --- Procedural SFX generators (return PackedFloat32Array) ---

func _gen_detonation() -> PackedFloat32Array:
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
	return samples


# Enemy destroyed: short punchy explosion (low rumble + crackle)
func _gen_enemy_destroy() -> PackedFloat32Array:
	var length: float = 0.25
	var count: int = int(SAMPLE_RATE * length)
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in count:
		var t: float = float(i) / float(SAMPLE_RATE)
		var env: float = (1.0 - t / length) * (1.0 - t / length)
		# Quick attack
		if t < 0.01:
			env = t / 0.01
		var freq: float = 120.0 * (1.0 - t / length * 0.6)
		var low: float = sin(TAU * freq * t + sin(TAU * 40.0 * t) * 1.5)
		var noise: float = randf_range(-1.0, 1.0)
		samples[i] = (low * 0.5 + noise * 0.4) * env * 0.6
	return samples


func _gen_enemy_impact() -> PackedFloat32Array:
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
	return samples


func _gen_click_rejected() -> PackedFloat32Array:
	var length: float = 0.12
	var count: int = int(SAMPLE_RATE * length)
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in count:
		var t: float = float(i) / float(SAMPLE_RATE)
		var env: float = (1.0 - t / length)
		var wave: float = sign(sin(TAU * 150.0 * t))
		samples[i] = wave * env * 0.3
	return samples


func _gen_mirv_split() -> PackedFloat32Array:
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
	return samples


func _gen_multi_kill() -> PackedFloat32Array:
	var length: float = 0.4
	var count: int = int(SAMPLE_RATE * length)
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in count:
		var t: float = float(i) / float(SAMPLE_RATE)
		var env: float = (1.0 - t / length)
		var chord: float = sin(TAU * 440.0 * t) + sin(TAU * 554.0 * t) + sin(TAU * 659.0 * t)
		samples[i] = chord / 3.0 * env * 0.5
	return samples


func _gen_silo_destroyed() -> PackedFloat32Array:
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
	return samples


func _gen_purchase() -> PackedFloat32Array:
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
	return samples
