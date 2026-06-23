class_name AdPlacementConfig
extends RefCounted

# Logical ad placements. android_ad_unit_id is a placeholder — fill in the
# real unit ids from the RuStore Ads dashboard before enabling Android ads.
const AD_PLACEMENTS: Array[Dictionary] = [
	{
		"id": "rewarded_shop_gems",
		"type": "rewarded",
		"android_ad_unit_id": "",
	},
	{
		"id": "rewarded_bonus_banner",
		"type": "rewarded",
		"android_ad_unit_id": "",
	},
	{
		"id": "rewarded_offline_gold_x3",
		"type": "rewarded",
		"android_ad_unit_id": "",
	},
	{
		"id": "fullscreen_auto_interstitial",
		"type": "fullscreen",
		"android_ad_unit_id": "",
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
