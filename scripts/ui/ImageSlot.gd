class_name ImageSlot
extends ColorRect

@export var asset_key: String = ""
@export var fallback_color: Color = Color.WHITE
@export var stretch_mode: TextureRect.StretchMode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
@export var show_fallback_behind_texture: bool = true

var _texture_view: TextureRect = null


func _ready() -> void:
	_texture_view = TextureRect.new()
	_texture_view.name = "TextureView"
	_texture_view.set_anchors_preset(Control.PRESET_FULL_RECT)
	_texture_view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_texture_view.stretch_mode = stretch_mode
	_texture_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_texture_view.visible = false
	add_child(_texture_view)
	color = fallback_color
	refresh_image()


func set_asset_key(new_key: String, new_fallback_color: Color = fallback_color) -> void:
	asset_key = new_key
	fallback_color = new_fallback_color
	if _texture_view != null:
		refresh_image()


func refresh_image() -> void:
	if _texture_view == null:
		return
	var texture: Texture2D = GameAssetCatalog.load_texture(asset_key)
	if texture != null:
		_texture_view.texture = texture
		_texture_view.visible = true
		color = fallback_color if show_fallback_behind_texture else Color.TRANSPARENT
	else:
		_texture_view.texture = null
		_texture_view.visible = false
		color = fallback_color


func set_fallback_color(new_color: Color) -> void:
	fallback_color = new_color
	color = new_color


func set_direct_texture(texture: Texture2D, new_fallback_color: Color, show_fallback: bool = true) -> void:
	fallback_color = new_fallback_color
	if _texture_view == null:
		color = new_fallback_color
		return
	if texture != null:
		_texture_view.texture = texture
		_texture_view.visible = true
		color = new_fallback_color if show_fallback else Color.TRANSPARENT
	else:
		_texture_view.texture = null
		_texture_view.visible = false
		color = new_fallback_color
