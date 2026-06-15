extends Node

const _SFX_POOL_SIZE: int = 6
const GOLD_RECEIVED_SOUND_MIN_INTERVAL_SEC: float = 0.15

var _sound_enabled: bool = true
var _music_enabled: bool = true
var _paused_for_ad: bool = false
var _last_gold_received_time: float = -999.0
var _audio_context_unlocked: bool = false

var _music_player: AudioStreamPlayer = null
var _sfx_players: Array[AudioStreamPlayer] = []

var _music_streams: Array[AudioStream] = []
var _current_music_index: int = -1
var _shuffled_music_bag: Array[int] = []

var _hit_streams: Array[AudioStream] = []
var _click_stream: AudioStream = null
var _purchase_stream: AudioStream = null
var _error_stream: AudioStream = null
var _reward_stream: AudioStream = null
var _gold_stream: AudioStream = null


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
	_music_streams.clear()
	for path: String in AudioConfig.MUSIC_TRACK_PATHS:
		_music_streams.append(_try_load(path))

	_click_stream = _try_load(AudioConfig.SFX_BUTTON_CLICK)
	_purchase_stream = _try_load(AudioConfig.SFX_PURCHASE_SUCCESS)
	_error_stream = _try_load(AudioConfig.SFX_PURCHASE_ERROR)
	_reward_stream = _try_load(AudioConfig.SFX_REWARD_RECEIVED)
	_gold_stream = _try_load(AudioConfig.SFX_GOLD_RECEIVED)

	_hit_streams.clear()
	for path: String in AudioConfig.SFX_HIT_PATHS:
		var s: AudioStream = _try_load(path)
		if s != null:
			_hit_streams.append(s)


func _try_load(path: String) -> AudioStream:
	if ResourceLoader.exists(path):
		return load(path) as AudioStream
	return null


# --- Settings ---

func set_music_enabled(enabled: bool) -> void:
	_music_enabled = enabled
	if not enabled:
		_music_player.stop()
	elif not _music_player.playing:
		play_next_music_track()


func set_sound_enabled(enabled: bool) -> void:
	_sound_enabled = enabled


# --- Music ---

func play_main_music() -> void:
	if _music_enabled:
		play_next_music_track()


func play_music_track(index: int) -> void:
	if index < 0 or index >= _music_streams.size():
		return
	if _music_streams[index] == null:
		return
	_current_music_index = index
	if _music_enabled:
		_play_track_at_index(_current_music_index)


func play_random_music_track() -> void:
	play_next_music_track()


func play_next_music_track() -> void:
	if _shuffled_music_bag.is_empty():
		_rebuild_shuffled_music_bag()
	if _shuffled_music_bag.is_empty():
		return
	var next_index: int = _shuffled_music_bag.pop_front()
	if next_index == _current_music_index and _has_multiple_valid_music_tracks():
		if _shuffled_music_bag.is_empty():
			_rebuild_shuffled_music_bag()
		if not _shuffled_music_bag.is_empty():
			_shuffled_music_bag.append(next_index)
			next_index = _shuffled_music_bag.pop_front()
	_current_music_index = next_index
	_play_track_at_index(_current_music_index)


func stop_music() -> void:
	_music_player.stop()


# --- SFX ---

func unlock_audio_if_needed() -> void:
	# Un-pause music if paused by NOTIFICATION_APPLICATION_FOCUS_OUT when FOCUS_IN never fired
	# (common in Yandex Games iframe).
	if _music_enabled and not _paused_for_ad and _music_player.stream_paused:
		_music_player.stream_paused = false

	if _audio_context_unlocked:
		return
	_audio_context_unlocked = true

	# Re-attempt music start after first confirmed user gesture.
	# On web, AudioContext may be suspended until the first interaction.
	if _music_enabled and not _paused_for_ad and not _music_player.playing:
		if _current_music_index >= 0:
			_play_track_at_index(_current_music_index)
		else:
			play_next_music_track()


func play_button_click() -> void:
	unlock_audio_if_needed()
	if _sound_enabled:
		_play_sfx(_click_stream)


func play_popup_open() -> void:
	play_button_click()


func play_random_hit() -> void:
	unlock_audio_if_needed()
	if _sound_enabled and not _hit_streams.is_empty():
		_play_sfx(_hit_streams[randi() % _hit_streams.size()])


func play_purchase_success() -> void:
	if _sound_enabled:
		_play_sfx(_purchase_stream)


func play_purchase_error() -> void:
	if _sound_enabled:
		_play_sfx(_error_stream)


func play_reward_received() -> void:
	if _sound_enabled:
		_play_sfx(_reward_stream)


func play_gold_received() -> void:
	if not _sound_enabled:
		return
	var now: float = Time.get_ticks_msec() / 1000.0
	if now - _last_gold_received_time < GOLD_RECEIVED_SOUND_MIN_INTERVAL_SEC:
		return
	_last_gold_received_time = now
	_play_sfx(_gold_stream)


# --- Ad pause/resume ---

func pause_for_ad() -> void:
	if _paused_for_ad:
		return
	_paused_for_ad = true
	_music_player.stream_paused = true


func resume_after_ad() -> void:
	if not _paused_for_ad:
		return
	_paused_for_ad = false
	if _music_enabled:
		_music_player.stream_paused = false


# --- Button binding ---

func bind_button(button: Button) -> void:
	if button.get_meta("audio_skip", false):
		return
	if button.get_meta("audio_button_bound", false):
		return
	button.set_meta("audio_button_bound", true)
	# button_down fires at press time, not at release — SFX plays immediately.
	button.button_down.connect(play_button_click)


func bind_buttons_in_tree(root: Node) -> void:
	_bind_buttons_recursive(root)


func _bind_buttons_recursive(node: Node) -> void:
	if node is Button:
		bind_button(node as Button)
	for child: Node in node.get_children():
		_bind_buttons_recursive(child)


# --- Internal ---

func _play_track_at_index(index: int) -> void:
	if not _music_enabled or _paused_for_ad:
		return
	if index < 0 or index >= _music_streams.size():
		return
	var stream: AudioStream = _music_streams[index]
	if stream == null:
		play_next_music_track()
		return
	_music_player.stream = stream
	_music_player.play()


func _get_valid_music_indices() -> Array[int]:
	var valid: Array[int] = []
	for i: int in _music_streams.size():
		if _music_streams[i] != null:
			valid.append(i)
	return valid


func _rebuild_shuffled_music_bag() -> void:
	_shuffled_music_bag = _get_valid_music_indices()
	_shuffled_music_bag.shuffle()
	if _shuffled_music_bag.size() > 1 and _shuffled_music_bag[0] == _current_music_index:
		var swap_index: int = 1 + (randi() % (_shuffled_music_bag.size() - 1))
		var tmp: int = _shuffled_music_bag[0]
		_shuffled_music_bag[0] = _shuffled_music_bag[swap_index]
		_shuffled_music_bag[swap_index] = tmp


func _has_multiple_valid_music_tracks() -> bool:
	return _get_valid_music_indices().size() > 1


func _notification(what: int) -> void:
	if _music_player == null:
		return
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT:
			_music_player.stream_paused = true
		NOTIFICATION_APPLICATION_FOCUS_IN:
			if _music_enabled and not _paused_for_ad:
				_music_player.stream_paused = false


func _play_sfx(stream: AudioStream) -> void:
	if stream == null or _paused_for_ad:
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
		play_next_music_track()
