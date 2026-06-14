extends Node

const _SFX_POOL_SIZE: int = 6

var _sound_enabled: bool = true
var _music_enabled: bool = true

var _music_player: AudioStreamPlayer = null
var _sfx_players: Array[AudioStreamPlayer] = []

var _music_stream: AudioStream = null
var _hit_streams: Array[AudioStream] = []
var _click_stream: AudioStream = null
var _purchase_stream: AudioStream = null


func _ready() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.volume_db = AudioConfig.DEFAULT_MUSIC_VOLUME_DB
	_music_player.finished.connect(_on_music_finished)
	add_child(_music_player)

	for _i: int in _SFX_POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.volume_db = AudioConfig.DEFAULT_SFX_VOLUME_DB
		add_child(p)
		_sfx_players.append(p)

	_load_streams()


func _load_streams() -> void:
	_music_stream = _try_load(AudioConfig.MUSIC_MAIN_THEME)
	_click_stream = _try_load(AudioConfig.SFX_BUTTON_CLICK)
	_purchase_stream = _try_load(AudioConfig.SFX_PURCHASE_SUCCESS)
	_hit_streams.clear()
	for path: String in AudioConfig.SFX_HIT_PATHS:
		var s: AudioStream = _try_load(path)
		if s != null:
			_hit_streams.append(s)


func _try_load(path: String) -> AudioStream:
	if ResourceLoader.exists(path):
		return load(path) as AudioStream
	return null


func set_music_enabled(enabled: bool) -> void:
	_music_enabled = enabled
	if not enabled:
		_music_player.stop()
	elif not _music_player.playing:
		_play_music_stream()


func set_sound_enabled(enabled: bool) -> void:
	_sound_enabled = enabled


func play_main_music() -> void:
	if _music_enabled:
		_play_music_stream()


func stop_music() -> void:
	_music_player.stop()


func play_button_click() -> void:
	if _sound_enabled:
		_play_sfx(_click_stream)


func play_random_hit() -> void:
	if _sound_enabled and not _hit_streams.is_empty():
		_play_sfx(_hit_streams[randi() % _hit_streams.size()])


func play_purchase_success() -> void:
	if _sound_enabled:
		_play_sfx(_purchase_stream)


func bind_button(button: Button) -> void:
	if button.get_meta("audio_skip", false):
		return
	if button.get_meta("audio_button_bound", false):
		return
	button.set_meta("audio_button_bound", true)
	button.pressed.connect(play_button_click)


func bind_buttons_in_tree(root: Node) -> void:
	_bind_buttons_recursive(root)


func _bind_buttons_recursive(node: Node) -> void:
	if node is Button:
		bind_button(node as Button)
	for child: Node in node.get_children():
		_bind_buttons_recursive(child)


func _play_music_stream() -> void:
	if _music_stream == null:
		return
	_music_player.stream = _music_stream
	_music_player.play()


func _play_sfx(stream: AudioStream) -> void:
	if stream == null:
		return
	for player: AudioStreamPlayer in _sfx_players:
		if not player.playing:
			player.stream = stream
			player.play()
			return
	_sfx_players[0].stop()
	_sfx_players[0].stream = stream
	_sfx_players[0].play()


func _on_music_finished() -> void:
	if _music_enabled:
		_music_player.play()
