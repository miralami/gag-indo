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
	require("./specs/harness_timing_spec"),
	require("./specs/multiclient_spec"),
	require("./specs/persistence_check_spec"),
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
	require("./specs/texturemap_spec"),
	require("./specs/soundmap_spec"),
	require("./specs/candidate_gallery_spec"),
	require("./specs/streaming_readiness_spec"),
	require("./specs/npc_model_candidates_spec"),
	require("./specs/crop_model_candidates_spec"),
	require("./specs/hub_prop_candidates_spec"),
	require("./specs/phone_layout_spec"),
	require("./specs/npc_framework_spec"),
	require("./specs/world_constants_spec"),
	require("./specs/remote_audit_spec"),
	require("./specs/remote_fuzz_spec"),
	require("./specs/save_fuzz_spec"),
	require("./specs/economy_sim_spec"),
	require("./specs/client_error_boundary_spec"),
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
	require("./specs/dead_code_spec"),
	require("./specs/lookdev_candidates_spec"),
	require("./specs/lookdev_corner_spec"),
	require("./specs/lookdev_additive_spec"),
	require("./specs/economy_config_spec"),
	require("./specs/first_session_failure_spec"),
	require("./specs/client_state_failure_spec"),
	require("./specs/rank_failure_spec"),
	require("./specs/player_leave_cleanup_spec"),
	require("./specs/respawn_rejoin_spec"),
	require("./specs/purchase_idempotency_spec"),
	require("./specs/cross_server_failure_spec"),
	require("./specs/admin_authority_spec"),
	require("./specs/q6_admin_spec"),
	require("./specs/analytics_audit_spec"),
	require("./specs/npc_pathing_robustness_spec"),
	require("./specs/ui_touch_text_audit_spec"),
	require("./specs/navigation_spec"),
	require("./specs/nav_wiring_spec"),
	require("./specs/audio_policy_spec"),
	require("./specs/audio_wiring_spec"),
	require("./specs/day_cycle_spec"),
	require("./specs/day_cycle_live_spec"),
	require("./specs/texture_map_r3_spec"),
	require("./specs/icon_map_r3_spec"),
	require("./specs/model_map_r3_spec"),
	require("./specs/sky_map_r3_spec"),
	require("./specs/review_round3_bugfix_spec"),
	require("./specs/texture_map_r4_spec"),
	require("./specs/sky_map_r4_spec"),
	require("./specs/model_map_buildings_r4_spec"),
	require("./specs/model_map_vegetation_r4_spec"),
	require("./specs/model_map_props_r4_spec"),
	require("./specs/model_map_npcs_r4_spec"),
	require("./specs/spawn_ground_r5_spec"),
	require("./specs/spawn_ground_r6_spec"),
	require("./specs/vegetation_r5_spec"),
	require("./specs/vegetation_r6_spec"),
	require("./specs/npcs_r6_spec"),
	require("./specs/props_r6_spec"),
	require("./specs/designer_kit_spec"),
	require("./specs/sky_map_r5_spec"),
	require("./specs/sky_map_r6_spec"),
	require("./specs/terrain_map_r6_spec"),
	require("./specs/props_r5_spec"),
	require("./specs/npcs_r5_spec"),
	require("./specs/spawn_dressing_r5_spec"),
	require("./specs/r7_review_check_fix_spec"),
	require("./specs/npcs_r7_catalog_spec"),
	require("./specs/cloud_cover_spec"),
	require("./specs/veg_near_spec"),
	require("./specs/props_r8_ids_spec"),
	require("./specs/hubveg_r8_spec"),
	require("./specs/plots_r8_spec"),
	require("./specs/sawah_r8_spec"),
	require("./specs/river_r8_spec"),
	require("./specs/pathedge_r8_spec"),
	require("./specs/water_r8_spec"),
	require("./specs/water_default_spec"),
	require("./specs/buildings_r8_spec"),
	require("./specs/facades_r8_spec"),
	require("./specs/hubprops_r8_spec"),
	require("./specs/forest_pines_legacy_spec"),
	require("./specs/forest_r9_spec"),
	require("./specs/blocks_r9_spec"),
	require("./specs/hubs_real_r9_spec"),
	require("./specs/pasar_awnings_r8_spec"),
}

-- `--timing` prints a full per-spec table; without it only the slowest rows print. The first
-- non-flag argument is still the name filter, so existing `lune run tests/run -- economy` usage
-- keeps working.
local filter
local showTiming = false
for _, arg in process.args do
	if arg == "--timing" then
		showTiming = true
	elseif filter == nil then
		filter = arg
	end
end

local SLOW_SECONDS = 2

local t = Test.new()
-- Registration is where specs that scan src/ do their file I/O, so time it separately from the
-- case execution recorded in Test:run. Remember which suites each spec registered so the report
-- can give a per-spec total.
local meta = {}
local regTotal = 0
for _, register in specs do
	local source = debug.info(register, "s")
	local name = string.match(source, "([%w_]+)$") or source
	local before = #t.suites
	local regStart = os.clock()
	register(t, Env, Fakes)
	local regSeconds = os.clock() - regStart
	regTotal += regSeconds
	local owned = {}
	for i = before + 1, #t.suites do
		owned[t.suites[i]] = true
	end
	table.insert(meta, { name = name, reg = regSeconds, owned = owned })
end

local passed, failed, failures = t:run(filter, print)

-- Timing report. Kept above the final pass/fail summary so the last line is unchanged for CI.
do
	local function fmt(seconds: number): string
		return string.format("%.3fs", seconds)
	end

	local specRows = {}
	for _, m in meta do
		local exec = 0
		for suite in m.owned do
			exec += t.suiteSeconds[suite] or 0
		end
		table.insert(specRows, { name = m.name, reg = m.reg, exec = exec, total = m.reg + exec })
	end
	table.sort(specRows, function(a, b)
		return a.total > b.total
	end)

	local caseRows = {}
	for _, suite in t.suites do
		for _, case in suite.cases do
			local seconds = t.caseSeconds[case]
			if seconds then
				table.insert(caseRows, { name = suite.name .. " > " .. case.name, seconds = seconds })
			end
		end
	end
	table.sort(caseRows, function(a, b)
		return a.seconds > b.seconds
	end)

	local function slowMark(seconds: number): string
		return if seconds >= SLOW_SECONDS then "  <== SLOW" else ""
	end

	print("")
	print(`=== Timing (threshold {SLOW_SECONDS}s; --timing for all specs) ===`)
	print(`registration {fmt(regTotal)}  +  cases {fmt(t.totalSeconds)}  =  {fmt(regTotal + t.totalSeconds)}`)
	print("slowest specs (total = registration + cases):")
	local specLimit = showTiming and #specRows or math.min(12, #specRows)
	for i = 1, specLimit do
		local r = specRows[i]
		print(
			string.format(
				"  %8s  reg=%-8s cases=%-8s  %s%s",
				fmt(r.total),
				fmt(r.reg),
				fmt(r.exec),
				r.name,
				slowMark(r.total)
			)
		)
	end
	print("slowest cases:")
	for i = 1, math.min(12, #caseRows) do
		local r = caseRows[i]
		print(string.format("  %8s  %s%s", fmt(r.seconds), r.name, slowMark(r.seconds)))
	end
end

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
