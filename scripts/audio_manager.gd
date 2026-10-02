class_name BloomkeeperAudioManager
extends Node

var pulse_player: AudioStreamPlayer
var pacify_player: AudioStreamPlayer
var damage_player: AudioStreamPlayer
var victory_player: AudioStreamPlayer
var game_over_player: AudioStreamPlayer


func _ready() -> void:
	pulse_player = _create_player("PulsePlayer")
	pacify_player = _create_player("PacifyPlayer")
	damage_player = _create_player("DamagePlayer")
	victory_player = _create_player("VictoryPlayer")
	game_over_player = _create_player("GameOverPlayer")

	pulse_player.stream = _generate_tone_wav(440.0, 0.25, 0.3, true)
	pacify_player.stream = _generate_chord_wav([523.25, 659.25, 783.99], 0.6, 0.4) # C5 major chord
	damage_player.stream = _generate_tone_wav(160.0, 0.2, 0.5, false)
	victory_player.stream = _generate_chord_wav([523.25, 659.25, 783.99, 1046.50], 1.2, 0.5)
	game_over_player.stream = _generate_chord_wav([311.13, 261.63, 220.00], 0.8, 0.4)


func _create_player(p_name: String) -> AudioStreamPlayer:
	var player: AudioStreamPlayer = AudioStreamPlayer.new()
	player.name = p_name
	add_child(player)
	return player


func play_pulse() -> void:
	if pulse_player:
		pulse_player.play()


func play_pacify() -> void:
	if pacify_player:
		pacify_player.play()


func play_damage() -> void:
	if damage_player:
		damage_player.play()


func play_victory() -> void:
	if victory_player:
		victory_player.play()


func play_game_over() -> void:
	if game_over_player:
		game_over_player.play()


func _generate_tone_wav(freq: float, duration: float, volume: float, is_sweep: bool) -> AudioStreamWAV:
	var sample_rate: int = 44100
	var total_samples: int = int(sample_rate * duration)
	var data: PackedByteArray = PackedByteArray()
	data.resize(total_samples * 2)

	for i in range(total_samples):
		var t: float = float(i) / float(sample_rate)
		var current_freq: float = freq + (t * 200.0 if is_sweep else 0.0)
		var envelope: float = (1.0 - (t / duration)) * volume
		var sample_val: float = sin(TAU * current_freq * t) * envelope
		var int_val: int = int(clampf(sample_val, -1.0, 1.0) * 32767.0)

		data.encode_s16(i * 2, int_val)

	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = data
	return wav


func _generate_chord_wav(freqs: Array, duration: float, volume: float) -> AudioStreamWAV:
	var sample_rate: int = 44100
	var total_samples: int = int(sample_rate * duration)
	var data: PackedByteArray = PackedByteArray()
	data.resize(total_samples * 2)

	for i in range(total_samples):
		var t: float = float(i) / float(sample_rate)
		var envelope: float = (1.0 - (t / duration)) * volume
		var combined: float = 0.0

		for f in freqs:
			combined += sin(TAU * float(f) * t)

		combined = (combined / float(freqs.size())) * envelope
		var int_val: int = int(clampf(combined, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, int_val)

	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = data
	return wav
