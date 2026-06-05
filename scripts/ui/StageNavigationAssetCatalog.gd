class_name StageNavigationAssetCatalog
extends RefCounted

const STAGE_NAV_IMAGE_ROOT: String = "res://assets/images/stage_navigation/"


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
