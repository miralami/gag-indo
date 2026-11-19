-- Pure audio hygiene policy (WORK_QUEUE item 22). No Roblox services, no Instances, no tweens:
-- the client/Audio.luau bridge owns Sound objects and Tweens and calls into this module for the
-- decisions. Keeping the loop-state machine pure lets it be pinned by LUNE-ONLY specs.
--
-- Hygiene contract this module enforces:
--   * static audit - every Sound config has a group with a set volume, a valid volume/id, and only
--     music/ambience groups loop;
--   * loop state - at most one current Sound per looping role (music, ambience); every accepted
--     transition records its outgoing/incoming key and bumps a role generation as a transition
--     identity. The bridge schedules each outgoing Stop on a timer guarded by a per-Sound fade
--     token, NOT this generation: intermediate outgoing loops must still be Stopped when state
--     changes again mid-fade, while a Sound that was replayed in the meantime must survive. A
--     role-level guard leaked four beds in Studio (WORK_QUEUE 22); see client/Audio.luau fadeOut.
--   * one-shots - pooled, never allocated: play() reports a fixed pool size regardless of how many
--     times a key is played (the bridge resets TimePosition before replaying).

local AudioPolicy = {}
AudioPolicy.__index = AudioPolicy

local ROLES = { "music", "ambience" }
local LOOPING_GROUPS = { music = true, ambience = true }

-- Return a sorted list of config problems (empty when clean). Pure over the two config tables.
function AudioPolicy.audit(groups, sounds)
	local problems = {}
	for name, volume in pairs(groups) do
		if type(volume) ~= "number" or volume < 0 or volume > 1 then
			table.insert(problems, "group " .. tostring(name) .. " has no valid volume in 0..1")
		end
	end
	for key, def in pairs(sounds) do
		if type(def) ~= "table" then
			table.insert(problems, "sound " .. tostring(key) .. " is not a table")
			continue
		end
		if type(def.group) ~= "string" or groups[def.group] == nil then
			table.insert(problems, "sound " .. tostring(key) .. " has no registered group")
		end
		if type(def.volume) ~= "number" or def.volume < 0 or def.volume > 1 then
			table.insert(problems, "sound " .. tostring(key) .. " has no valid volume in 0..1")
		end
		if type(def.id) ~= "number" or def.id < 0 or def.id % 1 ~= 0 then
			table.insert(problems, "sound " .. tostring(key) .. " has an invalid asset id")
		end
		if def.looped == true and not LOOPING_GROUPS[def.group] then
			table.insert(problems, "sound " .. tostring(key) .. " loops but is not a music/ambience group")
		end
	end
	table.sort(problems)
	return problems
end

-- Set of keys that have a real asset id, i.e. a Sound instance actually exists in the pool.
function AudioPolicy.playable(sounds)
	local out = {}
	for key, def in pairs(sounds) do
		if type(def) == "table" and type(def.id) == "number" and def.id > 0 and def.id % 1 == 0 then
			out[key] = true
		end
	end
	return out
end

function AudioPolicy.new(playable)
	return setmetatable({
		_playable = playable or {},
		_current = { music = nil, ambience = nil },
		_gen = { music = 0, ambience = 0 },
	}, AudioPolicy)
end

function AudioPolicy:isPlayable(key)
	return type(key) == "string" and self._playable[key] == true
end

function AudioPolicy:current(role)
	return self._current[role]
end

function AudioPolicy:generation(role)
	return self._gen[role]
end

-- Decide a looping-role transition. `key` is the requested Sound key; a non-playable key or nil
-- means "stop this role". Returns nil when nothing changes (the bridge must not touch tweens or
-- restart a sound). Otherwise returns:
--   { role=..., from=<key?>, to=<key?>, gen=<new generation>, changed=true }
-- Each accepted change bumps the role generation as a monotonic transition identity. The bridge
-- does not use it for the Stop guard (per-Sound fade identity is what matters there), but it keeps
-- the state machine explicit and spec-able.
function AudioPolicy:transition(role, key)
	assert(role == "music" or role == "ambience", "role must be music or ambience")
	local to = self:isPlayable(key) and key or nil
	local from = self._current[role]
	if from == to then
		return nil
	end
	self._current[role] = to
	self._gen[role] = self._gen[role] + 1
	return { role = role, from = from, to = to, gen = self._gen[role], changed = true }
end

-- Whether `gen` still identifies the latest transition for `role`. Kept as an explicit, spec-able
-- transition identity; the engine's actual Stop guard is per-Sound fade identity in Audio.luau.
function AudioPolicy:isCurrent(role, gen)
	return self._gen[role] == gen
end

-- At most one current key per looping role. Returned as a set for easy spec assertions.
function AudioPolicy:activeLoops()
	local out = {}
	for _, role in ROLES do
		local key = self._current[role]
		if key then
			out[key] = true
		end
	end
	return out
end

-- One-shots are pooled: replaying any number of keys never grows the pool. The bridge resets
-- TimePosition=0 before Play(), so this is a stable count, not an allocation.
function AudioPolicy:poolSize(playable)
	local n = 0
	for _ in pairs(playable or self._playable) do
		n += 1
	end
	return n
end

return AudioPolicy
