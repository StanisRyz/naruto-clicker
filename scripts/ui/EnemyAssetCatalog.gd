class_name EnemyAssetCatalog

const ENEMY_IMAGE_ROOT: String = "res://assets/images/enemies/"
const STATE_HEALTHY: String = "healthy"
const STATE_HIT: String = "hit"
const STATE_WOUNDED: String = "wounded"
const STATE_DEFEATED: String = "defeated"
const ENEMY_STATES: Array[String] = ["healthy", "hit", "wounded", "defeated"]


static func get_zone_folder(zone_index: int) -> String:
	return "zone_%02d" % (zone_index + 1)


static func get_enemy_folder(enemy_slot: String) -> String:
	return enemy_slot


static func get_enemy_state_path(zone_index: int, enemy_slot: String, state: String) -> String:
	return ENEMY_IMAGE_ROOT + get_zone_folder(zone_index) + "/" + get_enemy_folder(enemy_slot) + "/" + state + ".png"


static func load_enemy_texture(zone_index: int, enemy_slot: String, state: String) -> Texture2D:
	var path: String = get_enemy_state_path(zone_index, enemy_slot, state)
	if not ResourceLoader.exists(path):
		return null
	return ResourceLoader.load(path) as Texture2D


static func enemy_slot_for_normal_enemy(enemy_index: int) -> String:
	return "enemy_%02d" % (enemy_index + 1)


static func enemy_slot_for_elite() -> String:
	return "elite_01"


static func enemy_slot_for_boss() -> String:
	return "boss_01"
