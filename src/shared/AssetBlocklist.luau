--!strict
-- AssetBlocklist: Creator Store asset IDs that must never be loaded, baked or inserted.
-- Pure data, no Roblox globals. LookDevAssetLoader refuses every ID listed here.
--
-- 128627541097148 "Rumah Warga Indonesia 2" (kampung pick 2): hides a Script that clones a fake
-- "Roblox Studio / Disconnected / Error 0x89AF2 / Optimize" dialog into every PlayerGui, blurs the
-- screen and anchors the player, then asks the developer to paste a Command Bar snippet that turns
-- on HttpService and inserts the "Connector" of 78922956693900 into ServerScriptService (a
-- backdoor). Found 2026-11-23, sprint 4.
-- 78922956693900: the backdoor payload that snippet fetches.

local AssetBlocklist = {}

local BLOCKED: { [number]: string } = {
	[128627541097148] = "malicious: fake Studio Optimize dialog (ClickFix backdoor dropper)",
	[78922956693900] = "malicious: backdoor Connector payload",
}

function AssetBlocklist.isBlocked(assetId: any): boolean
	return type(assetId) == "number" and BLOCKED[assetId] ~= nil
end

function AssetBlocklist.reason(assetId: any): string?
	if type(assetId) ~= "number" then
		return nil
	end
	return BLOCKED[assetId]
end

function AssetBlocklist.ids(): { number }
	local out = {}
	for id in pairs(BLOCKED) do
		table.insert(out, id)
	end
	table.sort(out)
	return out
end

return AssetBlocklist
