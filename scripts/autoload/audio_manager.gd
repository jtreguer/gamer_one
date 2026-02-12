extends Node

## Stub AudioManager — plays nothing until audio assets are integrated (Phase 5).

var _sfx_players: Array[AudioStreamPlayer] = []
var _music_player: AudioStreamPlayer = null

const SFX_POOL_SIZE := 8


func _ready() -> void:
	for i in SFX_POOL_SIZE:
		var player := AudioStreamPlayer.new()
		add_child(player)
		_sfx_players.append(player)

	_music_player = AudioStreamPlayer.new()
	add_child(_music_player)


func play_sfx(_sfx_name: String, _pitch_variation: float = 0.1) -> void:
	# Stub: no audio files loaded yet.
	pass


func play_music(_stream: AudioStream, _fade_in: float = 1.0) -> void:
	pass


func stop_music(_fade_out: float = 1.0) -> void:
	pass
