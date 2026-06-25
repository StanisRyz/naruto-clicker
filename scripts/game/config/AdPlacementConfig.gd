class_name AdPlacementConfig
extends RefCounted

const AD_PLACEMENTS: Array[Dictionary] = [
	{
		"id": "rewarded_shop_gems",
		"type": "rewarded",
		"android_ad_unit_id": "R-M-19501283-1",
	},
	{
		"id": "rewarded_bonus_banner",
		"type": "rewarded",
		"android_ad_unit_id": "R-M-19501283-2",
	},
	{
		"id": "rewarded_offline_gold_x3",
		"type": "rewarded",
		"android_ad_unit_id": "R-M-19501283-3",
	},
	{
		"id": "fullscreen_auto_interstitial",
		"type": "fullscreen",
		"android_ad_unit_id": "R-M-19501283-4",
	},
]


static func get_by_id(placement_id: String) -> Dictionary:
	for placement: Dictionary in AD_PLACEMENTS:
		if String(placement.get("id", "")) == placement_id:
			return placement
	return {}


static func get_platform_ad_unit_id(placement_id: String, platform_key: String) -> String:
	var placement: Dictionary = get_by_id(placement_id)
	if placement.is_empty():
		return ""
	match platform_key:
		"rustore":
			return String(placement.get("android_ad_unit_id", ""))
		_:
			return ""


static func exists(placement_id: String) -> bool:
	return not get_by_id(placement_id).is_empty()
