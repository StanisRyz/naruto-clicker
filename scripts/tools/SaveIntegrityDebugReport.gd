# Dev-only tool. Run via Godot editor script runner. Never instantiated in game runtime.
# Usage: SaveIntegrityDebugReport.new().run()
class_name SaveIntegrityDebugReport
extends RefCounted

const SaveAdapter = preload("res://scripts/game/save/ClickerStateSaveAdapter.gd")

var _pass_count: int = 0
var _fail_count: int = 0


func run() -> void:
	print("=== SaveIntegrityDebugReport ===")
	_check_save_roundtrip()
	_check_reset_preserved()
	_check_prestige_preserved()
	_check_offline_reward_safety()
	print("--- RESULT: %d passed, %d failed ---" % [_pass_count, _fail_count])


func _check_save_roundtrip() -> void:
	print("-- save/load roundtrip --")
	var state := ClickerState.new()
	state.gold = BigNumber.from_int(12345)
	state.gems = 77
	state.character_level = 10
	state.current_level = 5
	state.max_unlocked_level = 8
	state.shop_permanent_partner_dps_x2_count = 2
	state.shop_permanent_click_damage_x2_count = 1
	state.shop_permanent_gold_x2_count = 3
	state.sound_enabled = false
	state.music_enabled = false
	state.language = "ru"
	state.rewarded_ad_all_damage_x2_expires_at = 9999999
	state.rewarded_ad_gold_x2_expires_at = 8888888
	state.rewarded_ad_banner_cooldown_until = 7777777
	state.rewarded_ad_current_reward_id = "gems_5"
	state.pending_offline_gold_reward = BigNumber.from_int(5000)
	state.pending_offline_elapsed_seconds = 3600
	state.pending_offline_created_at = 1000000

	var data: Dictionary = SaveAdapter.build_save_data(state)
	var state2 := ClickerState.new()
	SaveAdapter.apply_save_data(state2, data)

	_assert_bn_int("gold", state2.gold, 12345)
	_assert_eq("gems", state2.gems, 77)
	_assert_eq("character_level", state2.character_level, 10)
	_assert_eq("current_level", state2.current_level, 5)
	_assert_eq("max_unlocked_level", state2.max_unlocked_level, 8)
	_assert_eq("shop_permanent_partner_dps_x2_count", state2.shop_permanent_partner_dps_x2_count, 2)
	_assert_eq("shop_permanent_click_damage_x2_count", state2.shop_permanent_click_damage_x2_count, 1)
	_assert_eq("shop_permanent_gold_x2_count", state2.shop_permanent_gold_x2_count, 3)
	_assert_bool("sound_enabled", state2.sound_enabled, false)
	_assert_bool("music_enabled", state2.music_enabled, false)
	_assert_str("language", state2.language, "ru")
	_assert_eq("rewarded_ad_all_damage_x2_expires_at", state2.rewarded_ad_all_damage_x2_expires_at, 9999999)
	_assert_eq("rewarded_ad_gold_x2_expires_at", state2.rewarded_ad_gold_x2_expires_at, 8888888)
	_assert_eq("rewarded_ad_banner_cooldown_until", state2.rewarded_ad_banner_cooldown_until, 7777777)
	_assert_str("rewarded_ad_current_reward_id", state2.rewarded_ad_current_reward_id, "gems_5")
	_assert_bn_int("pending_offline_gold_reward", state2.pending_offline_gold_reward, 5000)
	_assert_eq("pending_offline_elapsed_seconds", state2.pending_offline_elapsed_seconds, 3600)
	_assert_eq("pending_offline_created_at", state2.pending_offline_created_at, 1000000)


func _check_reset_preserved() -> void:
	print("-- reset progress preservation --")
	var state := ClickerState.new()
	state.gold = BigNumber.from_int(99999)
	state.gems = 50
	state.shop_permanent_partner_dps_x2_count = 2
	state.shop_permanent_click_damage_x2_count = 1
	state.shop_permanent_gold_x2_count = 3
	state.sound_enabled = false
	state.music_enabled = false
	state.language = "ru"
	state.character_level = 20
	state.current_level = 15

	var snap: Dictionary = state.get_reset_progress_preserved_snapshot()
	state.reset_to_new_game()
	state.apply_reset_progress_preserved_snapshot(snap)

	_assert_eq("reset: gems preserved", state.gems, 50)
	_assert_eq("reset: shop_partner_dps preserved", state.shop_permanent_partner_dps_x2_count, 2)
	_assert_eq("reset: shop_click_damage preserved", state.shop_permanent_click_damage_x2_count, 1)
	_assert_eq("reset: shop_gold preserved", state.shop_permanent_gold_x2_count, 3)
	_assert_bool("reset: sound_enabled preserved", state.sound_enabled, false)
	_assert_bool("reset: music_enabled preserved", state.music_enabled, false)
	_assert_str("reset: language preserved", state.language, "ru")
	_assert_bn_zero("reset: gold cleared", state.gold)
	_assert_eq("reset: character_level cleared", state.character_level, 1)
	_assert_eq("reset: current_level cleared", state.current_level, 1)
	_assert_eq("reset: prestige_points cleared", state.prestige_points_available, 0)


func _check_prestige_preserved() -> void:
	print("-- prestige preservation --")
	var state := ClickerState.new()
	state.gems = 30
	state.shop_permanent_partner_dps_x2_count = 1
	state.shop_permanent_click_damage_x2_count = 2
	state.shop_permanent_gold_x2_count = 0
	state.sound_enabled = false
	state.music_enabled = false
	state.language = "ru"
	state.prestige_talent_levels[0] = 3
	state.prestige_points_available = 10
	state.prestige_points_total_earned = 10
	state.total_prestiges = 1
	state.gold = BigNumber.from_int(99999)
	state.character_level = 50
	state.current_level = 100

	var gems_before: int = state.gems
	var shop_pdps: int = state.shop_permanent_partner_dps_x2_count
	var shop_click: int = state.shop_permanent_click_damage_x2_count
	var shop_gold_: int = state.shop_permanent_gold_x2_count
	var talent_0: int = state.prestige_talent_levels[0]
	var sound_b: bool = state.sound_enabled
	var music_b: bool = state.music_enabled
	var lang_b: String = state.language

	var reward: int = 5
	state.prestige_points_available += reward
	state.prestige_points_total_earned += reward
	state.total_prestiges += 1
	state.gold = BigNumber.zero()
	state.character_level = 1
	state.current_level = 1
	state.max_unlocked_level = 1
	state.enemies_defeated_on_level = 0
	state.clear_cleared_levels()
	state.clear_all_level_progress()
	state.autoclick_purchased = false
	state.purchased_partner_skill_ids.clear()
	state.purchased_hero_skill_ids.clear()
	state.purchased_ability_skill_ids.clear()

	_assert_eq("prestige: gems preserved", state.gems, gems_before)
	_assert_eq("prestige: shop_partner_dps preserved", state.shop_permanent_partner_dps_x2_count, shop_pdps)
	_assert_eq("prestige: shop_click_damage preserved", state.shop_permanent_click_damage_x2_count, shop_click)
	_assert_eq("prestige: shop_gold preserved", state.shop_permanent_gold_x2_count, shop_gold_)
	_assert_eq("prestige: talent_levels[0] preserved", state.prestige_talent_levels[0], talent_0)
	_assert_bool("prestige: sound_enabled preserved", state.sound_enabled, sound_b)
	_assert_bool("prestige: music_enabled preserved", state.music_enabled, music_b)
	_assert_str("prestige: language preserved", state.language, lang_b)
	_assert_bn_zero("prestige: gold cleared", state.gold)
	_assert_eq("prestige: character_level cleared", state.character_level, 1)


func _check_offline_reward_safety() -> void:
	print("-- offline reward safety --")
	var state := ClickerState.new()
	state.last_save_unix_time = int(Time.get_unix_time_from_system()) - 7200

	var elapsed: int = int(Time.get_unix_time_from_system()) - state.last_save_unix_time
	state.queue_offline_gold_reward(elapsed)
	var queued_reward: BigNumber = state.pending_offline_gold_reward.clone()

	var state2 := ClickerState.new()
	state2.pending_offline_gold_reward = queued_reward.clone()
	state2.pending_offline_elapsed_seconds = state.pending_offline_elapsed_seconds

	var had_pending: bool = state2.has_pending_offline_gold_reward()
	_assert_bool("offline: pending detected on restart", had_pending, true)
	_assert_bn_eq("offline: pending reward unchanged on restart", state2.pending_offline_gold_reward, queued_reward)

	var gold_before: BigNumber = state2.gold.clone()
	state2.claim_pending_offline_gold(1)
	_assert_bn_eq("offline: gold added after claim", state2.gold, gold_before.add(queued_reward))
	_assert_bool("offline: pending cleared after claim", state2.has_pending_offline_gold_reward(), false)

	var gold_after_first: BigNumber = state2.gold.clone()
	state2.claim_pending_offline_gold(1)
	_assert_bn_eq("offline: no double-claim", state2.gold, gold_after_first)


func _assert_eq(label: String, actual: int, expected: int) -> void:
	if actual == expected:
		print("  PASS: %s = %d" % [label, actual])
		_pass_count += 1
	else:
		print("  FAIL: %s expected %d, got %d" % [label, expected, actual])
		_fail_count += 1


func _assert_bn_int(label: String, actual: BigNumber, expected: int) -> void:
	var actual_int: int = actual.floor_to_int_safe()
	if actual_int == expected:
		print("  PASS: %s = %d" % [label, actual_int])
		_pass_count += 1
	else:
		print("  FAIL: %s expected %d, got %s" % [label, expected, actual.to_debug_string()])
		_fail_count += 1


func _assert_bn_zero(label: String, actual: BigNumber) -> void:
	if actual.is_zero():
		print("  PASS: %s = 0" % label)
		_pass_count += 1
	else:
		print("  FAIL: %s expected 0, got %s" % [label, actual.to_debug_string()])
		_fail_count += 1


func _assert_bn_eq(label: String, actual: BigNumber, expected: BigNumber) -> void:
	if actual.compare_to(expected) == 0:
		print("  PASS: %s = %s" % [label, actual.to_debug_string()])
		_pass_count += 1
	else:
		print("  FAIL: %s expected %s, got %s" % [label, expected.to_debug_string(), actual.to_debug_string()])
		_fail_count += 1


func _assert_bool(label: String, actual: bool, expected: bool) -> void:
	if actual == expected:
		print("  PASS: %s = %s" % [label, str(actual)])
		_pass_count += 1
	else:
		print("  FAIL: %s expected %s, got %s" % [label, str(expected), str(actual)])
		_fail_count += 1


func _assert_str(label: String, actual: String, expected: String) -> void:
	if actual == expected:
		print("  PASS: %s = '%s'" % [label, actual])
		_pass_count += 1
	else:
		print("  FAIL: %s expected '%s', got '%s'" % [label, expected, actual])
		_fail_count += 1
