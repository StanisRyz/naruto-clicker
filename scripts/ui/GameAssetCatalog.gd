class_name GameAssetCatalog

const IMAGE_ROOT: String = "res://assets/images/"

const ASSET_PATHS: Dictionary = {
	# Sheet backgrounds
	"ui.sheet.standard": "res://assets/images/ui/sheets/standard_sheet.png",
	"ui.sheet.close_button": "res://assets/images/ui/sheets/close_button.png",
	"ui.sheet.close_button.pressed": "res://assets/images/ui/sheets/close_button_pressed.png",

	# Card backgrounds
	"ui.card.sheet": "res://assets/images/ui/cards/sheet_card.png",
	"ui.card.button.default": "res://assets/images/ui/cards/button/default.png",
	"ui.card.button.active": "res://assets/images/ui/cards/button/active.png",

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
	"stage.latest": "res://assets/images/ui/stage_navigation/latest_stage/default.png",
	"stage.auto_on": "res://assets/images/ui/stage_navigation/auto_transition/enabled.png",
	"stage.auto_off": "res://assets/images/ui/stage_navigation/auto_transition/disabled.png",

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
	# Required path (create before release): res://assets/images/shop/rewarded_gems_ad.png
	"shop.rewarded_gems_ad": "res://assets/images/shop/rewarded_gems_ad.png",
	"shop.gold_pack_small": "res://assets/images/shop/gold_pack_small.png",
	"shop.gold_pack_large": "res://assets/images/shop/gold_pack_large.png",

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

	# TasksWindow task card background
	"task.card.background": "res://assets/images/tasks/task_card.png",

	# TasksWindow panel and close button
	"task.window.background": "res://assets/images/tasks/window/background.png",
	"task.window.close": "res://assets/images/tasks/window/close.png",
	"task.window.claim_button": "res://assets/images/tasks/window/claim_button.png",

	# Shop permanent upgrade icons
	"shop.permanent_partner_dps_x2": "res://assets/images/shop/permanent_partner_dps_x2.png",
	"shop.permanent_click_damage_x2": "res://assets/images/shop/permanent_click_damage_x2.png",
	"shop.permanent_gold_x2": "res://assets/images/shop/permanent_gold_x2.png",

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

	# Bottom tabs decorative backdrop (820px wide, bleeds 50px each side beyond 720px viewport)
	"ui.bottom_tabs.backdrop": "res://assets/images/ui/bottom_bar/tabs_backdrop.png",

	# Popup and window backgrounds
	"ui.popup.skill.background": "res://assets/images/ui/popups/skill/background.png",
	"ui.popup.auto_transition.background": "res://assets/images/ui/popups/auto_transition/background.png",
	"ui.window.settings.background": "res://assets/images/ui/windows/settings/background.png",
	"ui.window.settings.reset_confirm_background": "res://assets/images/ui/windows/settings/reset_confirm_background.png",
	"ui.dialog.prestige.background": "res://assets/images/ui/dialogs/prestige/background.png",
	"ui.dialog.prestige.inner_background": "res://assets/images/ui/dialogs/prestige/inner_background.png",
	"ui.popup.shop_confirm.background": "res://assets/images/ui/popups/shop_confirm/background.png",

	# Popup action buttons
	"ui.popup.button.default": "res://assets/images/ui/popups/buttons/default.png",
	"ui.popup.button.danger": "res://assets/images/ui/popups/buttons/danger.png",
	"ui.popup.button.pressed": "res://assets/images/ui/popups/buttons/pressed.png",

	# Rewarded ad banner thumbnails — all three must share the same pixel dimensions.
	# Required paths (create before release):
	#   res://assets/images/ui/rewarded_ads/banner_all_damage.png
	#   res://assets/images/ui/rewarded_ads/banner_gems.png
	#   res://assets/images/ui/rewarded_ads/banner_gold.png
	"rewarded_ad.banner.all_damage": "res://assets/images/ui/rewarded_ads/banner_all_damage.png",
	"rewarded_ad.banner.gems":       "res://assets/images/ui/rewarded_ads/banner_gems.png",
	"rewarded_ad.banner.gold":       "res://assets/images/ui/rewarded_ads/banner_gold.png",
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
	# Shared skill rank icon: "skill.rank.N"
	if asset_key.begins_with("skill.rank."):
		var parts: PackedStringArray = asset_key.split(".")
		if parts.size() == 3:
			var level: int = parts[2].to_int()
			return "res://assets/images/skills/skill_%02d.png" % level
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


static func skill_rank_icon_key(skill_level: int) -> String:
	return "skill.rank.%d" % skill_level


static func partner_skill_key(_partner_index: int, skill_level: int) -> String:
	return skill_rank_icon_key(skill_level)


static func ability_icon_key(ability_id: String) -> String:
	return "ability.%s" % ability_id


static func ability_skill_key(_ability_id: String, skill_level: int) -> String:
	return skill_rank_icon_key(skill_level)


static func hero_skill_key(skill_level: int) -> String:
	return skill_rank_icon_key(skill_level)


static func building_icon_key(building_index: int) -> String:
	return "building.%d.icon" % building_index


static func prestige_talent_icon_key(talent_id: String) -> String:
	return "prestige.%s" % talent_id


static func shop_product_icon_key(product_id: String) -> String:
	return "shop.%s" % product_id


static func task_icon_key(task_id: String) -> String:
	return "task.%s" % task_id
