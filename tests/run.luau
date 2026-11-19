--!nocheck
-- Test runner.   Run from the repository root:
--
--     lune run tests/run                 (all tests)
--     lune run tests/run -- economy      (only tests whose name contains "economy")
--
-- Exit code is 1 when anything fails, so CI can use it directly.

local process = require("@lune/process")

local Test = require("./lib/Test")
local Env = require("./lib/Env")
local Fakes = require("./lib/Fakes")

-- Add new spec files here.
local specs = {
	require("./specs/config_spec"),
	require("./specs/produce_spec"),
	require("./specs/state_spec"),
	require("./specs/seasons_spec"),
	require("./specs/shop_spec"),
	require("./specs/shop_failure_spec"),
	require("./specs/economy_failure_spec"),
	require("./specs/debt_failure_spec"),
	require("./specs/debt_collector_failure_spec"),
	require("./specs/economy_money_spec"),
	require("./specs/debt_persistence_spec"),
	require("./specs/produce_guard_spec"),
	require("./specs/bribe_failure_spec"),
	require("./specs/market_spec"),
	require("./specs/tool_spec"),
	require("./specs/storage_spec"),
	require("./specs/worker_spec"),
	require("./specs/onboarding_spec"),
	require("./specs/debt_spec"),
	require("./specs/quest_spec"),
	require("./specs/liveconfig_spec"),
	require("./specs/rarity_spec"),
	require("./specs/traits_spec"),
	require("./specs/almanak_spec"),
	require("./specs/ratelimit_spec"),
	require("./specs/sus_spec"),
	require("./specs/rank_spec"),
	require("./specs/economy_spec"),
	require("./specs/receipts_spec"),
	require("./specs/passes_spec"),
	require("./specs/playerdata_spec"),
	require("./specs/leaderboard_spec"),
	require("./specs/analytics_spec"),
	require("./specs/visuals_spec"),
	require("./specs/visual_art_spec"),
	require("./specs/security_spec"),
	require("./specs/balance_spec"),
	require("./specs/harness_spec"),
	require("./specs/raid_trigger_spec"),
	require("./specs/fps_sampler_spec"),
	require("./specs/greybox_spec"),
	require("./specs/sky_spec"),
	require("./specs/seedfloor_spec"),
	require("./specs/npcfactory_spec"),
	require("./specs/decor_spec"),
	require("./specs/details_spec"),
	require("./specs/flora_spec"),
	require("./specs/landscape_spec"),
		require("./specs/enums_spec"),
	require("./specs/camerafeel_spec"),
	require("./specs/feel_spec"),
	require("./specs/nextgoal_spec"),
	require("./specs/first_session_spec"),
	require("./specs/iconmap_spec"),
	require("./specs/phone_layout_spec"),
	require("./specs/npc_framework_spec"),
	require("./specs/world_constants_spec"),
	require("./specs/remote_audit_spec"),
	require("./specs/farm_failure_spec"),
	require("./specs/fidelity_tier_spec"),
	require("./specs/fidelity_runtime_spec"),
	require("./specs/hook_moment_spec"),
	require("./specs/raid_failure_spec"),
	require("./specs/quest_failure_spec"),
	require("./specs/worker_failure_spec"),
	require("./specs/storage_failure_spec"),
	require("./specs/cheat_failure_spec"),
	require("./specs/evidence_failure_spec"),
	require("./specs/plot_failure_spec"),
	require("./specs/warung_neighbor_failure_spec"),
	require("./specs/perf_switches_spec"),
	require("./specs/sus_almanak_failure_spec"),
	require("./specs/season_admin_failure_spec"),
	require("./specs/cosmetics_leaderboard_failure_spec"),
	require("./specs/save_reconcile_spec"),
	require("./specs/onboarding_receipts_failure_spec"),
	require("./specs/tool_items_failure_spec"),
	require("./specs/events_badges_passes_failure_spec"),
	require("./specs/tier_consumers_spec"),
	require("./specs/strings_integrity_spec"),
	require("./specs/config_crossref_spec"),
	require("./specs/cutscene_sequencer_spec"),
	require("./specs/lazy_pages_spec"),
	require("./specs/minigame_cancel_spec"),
	require("./specs/multiplayer_sim_spec"),
	require("./specs/state_request_failure_spec"),
	require("./specs/data_pass_failure_spec"),
	require("./specs/greybox_retirement_spec"),
	require("./specs/perf_hotpath_spec"),
	require("./specs/code_health_spec"),
	require("./specs/lookdev_candidates_spec"),
	require("./specs/economy_config_spec"),
	require("./specs/first_session_failure_spec"),
	require("./specs/client_state_failure_spec"),
	require("./specs/rank_failure_spec"),
	require("./specs/player_leave_cleanup_spec"),
	require("./specs/respawn_rejoin_spec"),
	require("./specs/purchase_idempotency_spec"),
	require("./specs/cross_server_failure_spec"),
	require("./specs/admin_authority_spec"),
	require("./specs/analytics_audit_spec"),
	require("./specs/npc_pathing_robustness_spec"),
	require("./specs/ui_touch_text_audit_spec"),
	require("./specs/navigation_spec"),
	require("./specs/nav_wiring_spec"),
}

local t = Test.new()
for _, register in specs do
	register(t, Env, Fakes)
end

local filter = process.args[1]
local passed, failed, failures = t:run(filter, print)

print("")
if failed > 0 then
	print(`{failed} FAILED, {passed} passed`)
	print("")
	for _, failure in failures do
		print("  - " .. failure)
	end
	process.exit(1)
end
print(`All {passed} tests passed`)

