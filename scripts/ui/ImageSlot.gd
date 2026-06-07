class_name ImageSlot
extends ColorRect

@export var asset_key: String = ""
@export var fallback_color: Color = Color.WHITE
@export var stretch_mode: TextureRect.StretchMode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
@export var show_fallback_behind_texture: bool = false

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


func has_loaded_texture() -> bool:
	return _texture_view != null and _texture_view.texture != null and _texture_view.visible


func _get_visible_fallback_color_for_texture_state(has_texture: bool) -> Color:
	if has_texture:
		return fallback_color if show_fallback_behind_texture else Color.TRANSPARENT
	return fallback_color


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
		color = _get_visible_fallback_color_for_texture_state(true)
	else:
		_texture_view.texture = null
		_texture_view.visible = false
		color = _get_visible_fallback_color_for_texture_state(false)


func set_fallback_color(new_color: Color) -> void:
	fallback_color = new_color
	color = _get_visible_fallback_color_for_texture_state(has_loaded_texture())


func set_direct_texture(texture: Texture2D, new_fallback_color: Color, show_fallback: bool = false) -> void:
	fallback_color = new_fallback_color
	show_fallback_behind_texture = show_fallback
	if _texture_view == null:
		color = new_fallback_color
		return
	if texture != null:
		_texture_view.texture = texture
		_texture_view.visible = true
	else:
		_texture_view.texture = null
		_texture_view.visible = false
	color = _get_visible_fallback_color_for_texture_state(texture != null)
