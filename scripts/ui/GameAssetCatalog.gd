class_name GameAssetCatalog

const IMAGE_ROOT: String = "res://assets/images/"

const ASSET_PATHS: Dictionary = {
	# Core UI
	"ui.top_interface": "res://assets/images/ui/top_interface.png",
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
	"ability.autoclick": "res://assets/images/abilities/autoclick/icon.png",
	"ability.gold_bonus": "res://assets/images/abilities/gold_bonus/icon.png",
	"ability.focus_burst": "res://assets/images/abilities/focus_burst/icon.png",
	"ability.rally": "res://assets/images/abilities/rally/icon.png",

	# Upgrade cards
	"upgrade.hero": "res://assets/images/upgrades/hero.png",
	"upgrade.autoclick": "res://assets/images/upgrades/autoclick.png",
	"upgrade.gold_bonus": "res://assets/images/upgrades/gold_bonus.png",
	"upgrade.focus_burst": "res://assets/images/upgrades/focus_burst.png",
	"upgrade.rally": "res://assets/images/upgrades/rally.png",

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
	"task.gain_10_game_levels": "res://assets/images/tasks/game_levels.png",

	# TasksWindow open button states
	"task.window_button.default": "res://assets/images/tasks/tasks_button/default.png",
	"task.window_button.completed": "res://assets/images/tasks/tasks_button/completed.png",

	# Bottom bar tabs
	"ui.bottom_tab.upgrades.default": "res://assets/images/ui/bottom_bar/tabs/upgrades/default.png",
	"ui.bottom_tab.upgrades.active": "res://assets/images/ui/bottom_bar/tabs/upgrades/active.png",

	"ui.bottom_tab.partners.default": "res://assets/images/ui/bottom_bar/tabs/partners/default.png",
	"ui.bottom_tab.partners.active": "res://assets/images/ui/bottom_bar/tabs/partners/active.png",

	"ui.bottom_tab.settlement.default": "res://assets/images/ui/bottom_bar/tabs/settlement/default.png",
	"ui.bottom_tab.settlement.active": "res://assets/images/ui/bottom_bar/tabs/settlement/active.png",

	"ui.bottom_tab.prestige.default": "res://assets/images/ui/bottom_bar/tabs/prestige/default.png",
	"ui.bottom_tab.prestige.active": "res://assets/images/ui/bottom_bar/tabs/prestige/active.png",

	"ui.bottom_tab.shop.default": "res://assets/images/ui/bottom_bar/tabs/shop/default.png",
	"ui.bottom_tab.shop.active": "res://assets/images/ui/bottom_bar/tabs/shop/active.png",
}


static func get_path(asset_key: String) -> String:
	if ASSET_PATHS.has(asset_key):
		return ASSET_PATHS[asset_key]
	# Dynamic partner icon: "partner.N.icon"
	if asset_key.begins_with("partner.") and asset_key.ends_with(".icon"):
		var parts: PackedStringArray = asset_key.split(".")
		if parts.size() == 3 and parts[2] == "icon":
			var idx: int = parts[1].to_int()
			return "res://assets/images/partners/partner_%02d/partner.png" % (idx + 1)
	# Dynamic partner skill: "partner.N.skill.M" — shared icons, partner_index unused
	if asset_key.begins_with("partner.") and ".skill." in asset_key:
		var parts: PackedStringArray = asset_key.split(".")
		if parts.size() == 4 and parts[2] == "skill":
			var level: int = parts[3].to_int()
			return "res://assets/images/partners/Skills/skill%d.png" % level
	# Dynamic hero skill: "hero_skill.N"
	if asset_key.begins_with("hero_skill."):
		var parts: PackedStringArray = asset_key.split(".")
		if parts.size() == 2:
			var level: int = parts[1].to_int()
			return "res://assets/images/hero_skills/skill_%02d.png" % level
	return ""


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


static func ability_skill_key(ability_id: String, _skill_level: int) -> String:
	return ability_icon_key(ability_id)


static func hero_skill_key(skill_level: int) -> String:
	return "hero_skill.%d" % skill_level


static func building_icon_key(building_index: int) -> String:
	return "building.%d.icon" % building_index


static func prestige_talent_icon_key(talent_id: String) -> String:
	return "prestige.%s" % talent_id


static func shop_product_icon_key(product_id: String) -> String:
	return "shop.%s" % product_id


static func task_icon_key(task_id: String) -> String:
	return "task.%s" % task_id
