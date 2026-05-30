class_name BackgroundAssetCatalog

const BACKGROUND_IMAGE_ROOT: String = "res://assets/images/backgrounds/"
const DEFAULT_BACKGROUND_KEY: String = "game.field_background"


static func get_zone_folder(zone_index: int) -> String:
	return "zone_%02d" % (zone_index + 1)


static func get_zone_background_path(zone_index: int) -> String:
	return BACKGROUND_IMAGE_ROOT + get_zone_folder(zone_index) + "/background.png"


static func load_zone_background(zone_index: int) -> Texture2D:
	var path: String = get_zone_background_path(zone_index)
	if ResourceLoader.exists(path):
		return ResourceLoader.load(path) as Texture2D
	return GameAssetCatalog.load_texture(DEFAULT_BACKGROUND_KEY)
