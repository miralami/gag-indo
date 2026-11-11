-- State: pure builders for the replicated structured state (v2 PLAN §7.1).
--
-- Scalars stay on player attributes (Cash, Sus, Rank, ...). Everything that does not fit
-- in one attribute — produce stacks, items, tools, gudang, debt, quests, almanak, story —
-- travels through one snapshot on join and small section patches afterwards.
--
-- This module only shapes data. Transport lives in server/Net/State.luau and the client
-- store in client/State.luau.

local Produce = require(script.Parent.Produce)
local Inventory = require(script.Parent.Inventory)

local State = {}

State.VERSION = 1

-- Sections the client can receive. Keep this list in sync with `section()`.
State.SECTIONS = {
	"produce",
	"items",
	"shop",
	"tools",
	"gudang",
	"debt",
	"quests",
	"almanak",
	"story",
}

local function copyFlat(source): { [any]: any }
	local out = {}
	for key, value in source or {} do
		out[key] = value
	end
	return out
end

local function copyDeep(source): { [any]: any }
	local out = {}
	for key, value in source or {} do
		if type(value) == "table" then
			out[key] = copyDeep(value)
		else
			out[key] = value
		end
	end
	return out
end

function State.isSection(name: any): boolean
	return type(name) == "string" and table.find(State.SECTIONS, name) ~= nil
end

-- Builds one section from save data. Unknown sections return nil.
function State.section(data, name: string): any
	if name == "produce" then
		return Produce.snapshot(data.produce or {})
	elseif name == "items" then
		return Inventory.snapshot(data)
	elseif name == "shop" then
		local shop = data.shop or {}
		return {
			cycle = shop.cycle or 0,
			restockAt = shop.restockAt or 0,
			musim = shop.musim or "",
			stock = copyFlat(shop.stock),
		}
	elseif name == "tools" then
		return copyFlat(data.tools)
	elseif name == "gudang" then
		local gudang = data.gudang or {}
		return {
			capacity = gudang.capacity or 0,
			stacks = Produce.snapshot(gudang.stacks or {}),
		}
	elseif name == "debt" then
		return copyDeep(data.debt or {})
	elseif name == "quests" then
		return copyDeep(data.quests or {})
	elseif name == "almanak" then
		return copyDeep(data.almanak or {})
	elseif name == "story" then
		return copyDeep(data.story or {})
	end
	return nil
end

function State.snapshot(data): { version: number, sections: { [string]: any } }
	local sections = {}
	for _, name in State.SECTIONS do
		sections[name] = State.section(data, name)
	end
	return {
		version = State.VERSION,
		sections = sections,
	}
end

-- Builds a patch for the named sections that exist. Used by server/Net/State.luau.
function State.patch(data, names: { [string]: boolean }): { [string]: any }
	local sections = {}
	for name in names do
		if State.isSection(name) then
			sections[name] = State.section(data, name)
		end
	end
	return sections
end

return State
