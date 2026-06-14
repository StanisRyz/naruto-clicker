class_name AudioConfig
extends RefCounted

const MUSIC_TRACK_PATHS: Array[String] = [
	"res://assets/audio/music/track_01.ogg",
	"res://assets/audio/music/track_02.ogg",
	"res://assets/audio/music/track_03.ogg",
	"res://assets/audio/music/track_04.ogg",
	"res://assets/audio/music/track_05.ogg",
	"res://assets/audio/music/track_06.ogg",
	"res://assets/audio/music/track_07.ogg",
]

const SFX_HIT_PATHS: Array[String] = [
	"res://assets/audio/sfx/hits/hit_01.ogg",
	"res://assets/audio/sfx/hits/hit_02.ogg",
	"res://assets/audio/sfx/hits/hit_03.ogg",
]

const SFX_BUTTON_CLICK: String = "res://assets/audio/sfx/ui/button_click.ogg"
const SFX_POPUP_OPEN: String = SFX_BUTTON_CLICK

const SFX_PURCHASE_SUCCESS: String = "res://assets/audio/sfx/shop/purchase_success.ogg"
const SFX_PURCHASE_ERROR: String = "res://assets/audio/sfx/shop/purchase_error.ogg"

const SFX_REWARD_RECEIVED: String = "res://assets/audio/sfx/rewards/reward_received.ogg"
const SFX_GOLD_RECEIVED: String = "res://assets/audio/sfx/rewards/gold_received.ogg"

const DEFAULT_MUSIC_VOLUME_DB: float = -10.0
const DEFAULT_SFX_VOLUME_DB: float = -2.0
