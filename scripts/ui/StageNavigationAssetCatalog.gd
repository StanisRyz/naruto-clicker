class_name StageNavigationAssetCatalog
extends RefCounted

const STAGE_NAV_IMAGE_ROOT: String = "res://assets/images/stage_navigation/"
const STAGE_NAV_COMMON_ROOT: String = STAGE_NAV_IMAGE_ROOT + "common/"
const LOCKED_OVERLAY_PATH: String = STAGE_NAV_COMMON_ROOT + "locked.png"
const CURRENT_OVERLAY_PATH: String = STAGE_NAV_COMMON_ROOT + "current.png"


static func load_locked_overlay_texture() -> Texture2D:
	if ResourceLoader.exists(LOCKED_OVERLAY_PATH):
		return ResourceLoader.load(LOCKED_OVERLAY_PATH) as Texture2D
	return null


static func has_locked_overlay_texture() -> bool:
	return ResourceLoader.exists(LOCKED_OVERLAY_PATH)


static func load_current_overlay_texture() -> Texture2D:
	if ResourceLoader.exists(CURRENT_OVERLAY_PATH):
		return ResourceLoader.load(CURRENT_OVERLAY_PATH) as Texture2D
	return null


static func has_current_overlay_texture() -> bool:
	return ResourceLoader.exists(CURRENT_OVERLAY_PATH)


static func get_zone_folder(zone_index: int) -> String:
	return "zone_%02d" % (zone_index + 1)


static func get_zone_stage_path(zone_index: int) -> String:
	return STAGE_NAV_IMAGE_ROOT + get_zone_folder(zone_index) + "/stage.png"


static func get_stage_path_for_level(level: int) -> String:
	var background_zone_index: int = ZoneConfig.get_background_asset_zone_index_for_level(level)
	return get_zone_stage_path(background_zone_index)


static func load_stage_texture_for_level(level: int) -> Texture2D:
	var path: String = get_stage_path_for_level(level)
	if ResourceLoader.exists(path):
		return ResourceLoader.load(path) as Texture2D
	return null
