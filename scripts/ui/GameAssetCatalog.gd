class_name GameAssetCatalog

const IMAGE_ROOT: String = "res://assets/images/"

const ASSET_PATHS: Dictionary = {
	# Core UI
	"ui.gold": "res://assets/images/ui/gold.png",
	"ui.gems": "res://assets/images/ui/gems.png",
	"ui.hero_level": "res://assets/images/ui/hero_level.png",
	"ui.click_damage": "res://assets/images/ui/click_damage.png",
	"ui.partner_dps": "res://assets/images/ui/partner_dps.png",
	"ui.settings": "res://assets/images/ui/settings.png",

	# Sheet header resources
	"header.gold": "res://assets/images/ui/gold.png",
	"header.prestige_points": "res://assets/images/ui/prestige_points.png",
	"header.gems": "res://assets/images/ui/gems.png",

	# Game field
	"game.field_background": "res://assets/images/game/field_background.png",
	"enemy.default.healthy": "res://assets/images/enemies/default_healthy.png",
	"enemy.default.hit": "res://assets/images/enemies/default_hit.png",
	"enemy.default.wounded": "res://assets/images/enemies/default_wounded.png",
	"enemy.default.defeated": "res://assets/images/enemies/default_defeated.png",

	# Stage navigator
	"stage.unlocked": "res://assets/images/ui/stage_unlocked.png",
	"stage.locked": "res://assets/images/ui/stage_locked.png",
	"stage.current": "res://assets/images/ui/stage_current.png",
	"stage.latest": "res://assets/images/ui/stage_latest.png",
	"stage.auto_on": "res://assets/images/ui/auto_on.png",
	"stage.auto_off": "res://assets/images/ui/auto_off.png",

	# Abilities
	"ability.autoclick": "res://assets/images/abilities/autoclick.png",
	"ability.gold_bonus": "res://assets/images/abilities/gold_bonus.png",
	"ability.focus_burst": "res://assets/images/abilities/focus_burst.png",
	"ability.rally": "res://assets/images/abilities/rally.png",

	# Upgrade cards
	"upgrade.hero": "res://assets/images/upgrades/hero.png",
	"upgrade.autoclick": "res://assets/images/upgrades/autoclick.png",
	"upgrade.gold_bonus": "res://assets/images/upgrades/gold_bonus.png",
	"upgrade.focus_burst": "res://assets/images/upgrades/focus_burst.png",
	"upgrade.rally": "res://assets/images/upgrades/rally.png",

	# Partner icons (indexes 0–12)
	"partner.0.icon": "res://assets/images/partners/partner_01.png",
	"partner.1.icon": "res://assets/images/partners/partner_02.png",
	"partner.2.icon": "res://assets/images/partners/partner_03.png",
	"partner.3.icon": "res://assets/images/partners/partner_04.png",
	"partner.4.icon": "res://assets/images/partners/partner_05.png",
	"partner.5.icon": "res://assets/images/partners/partner_06.png",
	"partner.6.icon": "res://assets/images/partners/partner_07.png",
	"partner.7.icon": "res://assets/images/partners/partner_08.png",
	"partner.8.icon": "res://assets/images/partners/partner_09.png",
	"partner.9.icon": "res://assets/images/partners/partner_10.png",
	"partner.10.icon": "res://assets/images/partners/partner_11.png",
	"partner.11.icon": "res://assets/images/partners/partner_12.png",
	"partner.12.icon": "res://assets/images/partners/partner_13.png",

	# Partner skills (indexes 0–12, levels 1–5)
	"partner.0.skill.1": "res://assets/images/partners/skills/partner_01_skill_01.png",
	"partner.0.skill.2": "res://assets/images/partners/skills/partner_01_skill_02.png",
	"partner.0.skill.3": "res://assets/images/partners/skills/partner_01_skill_03.png",
	"partner.0.skill.4": "res://assets/images/partners/skills/partner_01_skill_04.png",
	"partner.0.skill.5": "res://assets/images/partners/skills/partner_01_skill_05.png",
	"partner.1.skill.1": "res://assets/images/partners/skills/partner_02_skill_01.png",
	"partner.1.skill.2": "res://assets/images/partners/skills/partner_02_skill_02.png",
	"partner.1.skill.3": "res://assets/images/partners/skills/partner_02_skill_03.png",
	"partner.1.skill.4": "res://assets/images/partners/skills/partner_02_skill_04.png",
	"partner.1.skill.5": "res://assets/images/partners/skills/partner_02_skill_05.png",
	"partner.2.skill.1": "res://assets/images/partners/skills/partner_03_skill_01.png",
	"partner.2.skill.2": "res://assets/images/partners/skills/partner_03_skill_02.png",
	"partner.2.skill.3": "res://assets/images/partners/skills/partner_03_skill_03.png",
	"partner.2.skill.4": "res://assets/images/partners/skills/partner_03_skill_04.png",
	"partner.2.skill.5": "res://assets/images/partners/skills/partner_03_skill_05.png",
	"partner.3.skill.1": "res://assets/images/partners/skills/partner_04_skill_01.png",
	"partner.3.skill.2": "res://assets/images/partners/skills/partner_04_skill_02.png",
	"partner.3.skill.3": "res://assets/images/partners/skills/partner_04_skill_03.png",
	"partner.3.skill.4": "res://assets/images/partners/skills/partner_04_skill_04.png",
	"partner.3.skill.5": "res://assets/images/partners/skills/partner_04_skill_05.png",
	"partner.4.skill.1": "res://assets/images/partners/skills/partner_05_skill_01.png",
	"partner.4.skill.2": "res://assets/images/partners/skills/partner_05_skill_02.png",
	"partner.4.skill.3": "res://assets/images/partners/skills/partner_05_skill_03.png",
	"partner.4.skill.4": "res://assets/images/partners/skills/partner_05_skill_04.png",
	"partner.4.skill.5": "res://assets/images/partners/skills/partner_05_skill_05.png",
	"partner.5.skill.1": "res://assets/images/partners/skills/partner_06_skill_01.png",
	"partner.5.skill.2": "res://assets/images/partners/skills/partner_06_skill_02.png",
	"partner.5.skill.3": "res://assets/images/partners/skills/partner_06_skill_03.png",
	"partner.5.skill.4": "res://assets/images/partners/skills/partner_06_skill_04.png",
	"partner.5.skill.5": "res://assets/images/partners/skills/partner_06_skill_05.png",
	"partner.6.skill.1": "res://assets/images/partners/skills/partner_07_skill_01.png",
	"partner.6.skill.2": "res://assets/images/partners/skills/partner_07_skill_02.png",
	"partner.6.skill.3": "res://assets/images/partners/skills/partner_07_skill_03.png",
	"partner.6.skill.4": "res://assets/images/partners/skills/partner_07_skill_04.png",
	"partner.6.skill.5": "res://assets/images/partners/skills/partner_07_skill_05.png",
	"partner.7.skill.1": "res://assets/images/partners/skills/partner_08_skill_01.png",
	"partner.7.skill.2": "res://assets/images/partners/skills/partner_08_skill_02.png",
	"partner.7.skill.3": "res://assets/images/partners/skills/partner_08_skill_03.png",
	"partner.7.skill.4": "res://assets/images/partners/skills/partner_08_skill_04.png",
	"partner.7.skill.5": "res://assets/images/partners/skills/partner_08_skill_05.png",
	"partner.8.skill.1": "res://assets/images/partners/skills/partner_09_skill_01.png",
	"partner.8.skill.2": "res://assets/images/partners/skills/partner_09_skill_02.png",
	"partner.8.skill.3": "res://assets/images/partners/skills/partner_09_skill_03.png",
	"partner.8.skill.4": "res://assets/images/partners/skills/partner_09_skill_04.png",
	"partner.8.skill.5": "res://assets/images/partners/skills/partner_09_skill_05.png",
	"partner.9.skill.1": "res://assets/images/partners/skills/partner_10_skill_01.png",
	"partner.9.skill.2": "res://assets/images/partners/skills/partner_10_skill_02.png",
	"partner.9.skill.3": "res://assets/images/partners/skills/partner_10_skill_03.png",
	"partner.9.skill.4": "res://assets/images/partners/skills/partner_10_skill_04.png",
	"partner.9.skill.5": "res://assets/images/partners/skills/partner_10_skill_05.png",
	"partner.10.skill.1": "res://assets/images/partners/skills/partner_11_skill_01.png",
	"partner.10.skill.2": "res://assets/images/partners/skills/partner_11_skill_02.png",
	"partner.10.skill.3": "res://assets/images/partners/skills/partner_11_skill_03.png",
	"partner.10.skill.4": "res://assets/images/partners/skills/partner_11_skill_04.png",
	"partner.10.skill.5": "res://assets/images/partners/skills/partner_11_skill_05.png",
	"partner.11.skill.1": "res://assets/images/partners/skills/partner_12_skill_01.png",
	"partner.11.skill.2": "res://assets/images/partners/skills/partner_12_skill_02.png",
	"partner.11.skill.3": "res://assets/images/partners/skills/partner_12_skill_03.png",
	"partner.11.skill.4": "res://assets/images/partners/skills/partner_12_skill_04.png",
	"partner.11.skill.5": "res://assets/images/partners/skills/partner_12_skill_05.png",
	"partner.12.skill.1": "res://assets/images/partners/skills/partner_13_skill_01.png",
	"partner.12.skill.2": "res://assets/images/partners/skills/partner_13_skill_02.png",
	"partner.12.skill.3": "res://assets/images/partners/skills/partner_13_skill_03.png",
	"partner.12.skill.4": "res://assets/images/partners/skills/partner_13_skill_04.png",
	"partner.12.skill.5": "res://assets/images/partners/skills/partner_13_skill_05.png",

	# Buildings (indexes 0–5)
	"building.0.icon": "res://assets/images/buildings/training_camp.png",
	"building.1.icon": "res://assets/images/buildings/market.png",
	"building.2.icon": "res://assets/images/buildings/knight_hut.png",
	"building.3.icon": "res://assets/images/buildings/war_banner.png",
	"building.4.icon": "res://assets/images/buildings/clock_tower.png",
	"building.5.icon": "res://assets/images/buildings/boss_shrine.png",

	# Prestige
	"prestige.action": "res://assets/images/prestige/prestige.png",
	"prestige.focus_training": "res://assets/images/prestige/focus_training.png",
	"prestige.trade_routes": "res://assets/images/prestige/trade_routes.png",
	"prestige.command_aura": "res://assets/images/prestige/command_aura.png",
	"prestige.quick_hands": "res://assets/images/prestige/quick_hands.png",
	"prestige.builder_wisdom": "res://assets/images/prestige/builder_wisdom.png",
	"prestige.boss_hunter": "res://assets/images/prestige/boss_hunter.png",

	# Shop
	"shop.gold_pack_small": "res://assets/images/shop/gold_pack_small.png",
	"shop.gold_pack_large": "res://assets/images/shop/gold_pack_large.png",
	"shop.instant_combo": "res://assets/images/shop/instant_combo.png",
	"shop.boss_retry_token": "res://assets/images/shop/boss_retry.png",
	"shop.task_boost": "res://assets/images/shop/task_boost.png",

	# Tasks
	"task.manual_damage_500": "res://assets/images/tasks/manual_damage.png",
	"task.defeat_25_enemies": "res://assets/images/tasks/enemies.png",
	"task.defeat_2_elites": "res://assets/images/tasks/elites.png",
	"task.defeat_1_boss": "res://assets/images/tasks/boss.png",
	"task.gain_10_hero_levels": "res://assets/images/tasks/hero_levels.png",
	"task.hire_10_partners": "res://assets/images/tasks/partners.png",
	"task.build_5_buildings": "res://assets/images/tasks/buildings.png",
	"task.activate_autoclick_1": "res://assets/images/tasks/autoclick.png",
	"task.combo_empowered_1": "res://assets/images/tasks/combo.png",
	"task.gain_10_game_levels": "res://assets/images/tasks/game_levels.png",
}


static func get_path(asset_key: String) -> String:
	return ASSET_PATHS.get(asset_key, "")


static func has_texture(asset_key: String) -> bool:
	var path: String = get_path(asset_key)
	return path != "" and ResourceLoader.exists(path)


static func load_texture(asset_key: String) -> Texture2D:
	var path: String = get_path(asset_key)
	if path == "" or not ResourceLoader.exists(path):
		return null
	return ResourceLoader.load(path) as Texture2D


static func partner_icon_key(partner_index: int) -> String:
	return "partner.%d.icon" % partner_index


static func partner_skill_key(partner_index: int, skill_level: int) -> String:
	return "partner.%d.skill.%d" % [partner_index, skill_level]


static func ability_icon_key(ability_id: String) -> String:
	return "ability.%s" % ability_id


static func ability_skill_key(ability_id: String, skill_level: int) -> String:
	return "upgrade.%s.skill.%d" % [ability_id, skill_level]


static func hero_skill_key(skill_level: int) -> String:
	return "upgrade.hero.skill.%d" % skill_level


static func building_icon_key(building_index: int) -> String:
	return "building.%d.icon" % building_index


static func prestige_talent_icon_key(talent_id: String) -> String:
	return "prestige.%s" % talent_id


static func shop_product_icon_key(product_id: String) -> String:
	return "shop.%s" % product_id


static func task_icon_key(task_id: String) -> String:
	return "task.%s" % task_id
