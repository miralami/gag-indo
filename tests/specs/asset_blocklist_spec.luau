--!nocheck
-- Security 2026-11-23: blocked store assets are refused and every loaded model is script-stripped.

local fs = require("@lune/fs")

return function(t, Env)
	local expect = t.expect
	local env = Env.new()
	local AssetBlocklist = env:require("shared/AssetBlocklist")
	local loaderSrc = fs.readFile("src/server/World/LookDevAssetLoader.luau")

	t:describe("asset_blocklist", function()
		t:it("blocks the malicious kampung pick and its payload", function()
			expect(AssetBlocklist.isBlocked(128627541097148)):toBe(true)
			expect(AssetBlocklist.isBlocked(78922956693900)):toBe(true)
			expect(AssetBlocklist.isBlocked(18239791051)):toBe(false)
			expect(AssetBlocklist.isBlocked("128627541097148")):toBe(false)
			expect(AssetBlocklist.reason(128627541097148) ~= nil):toBe(true)
			expect(#AssetBlocklist.ids() >= 2):toBe(true)
		end)

		t:it("loader refuses blocked IDs on both paths and strips scripts on both paths", function()
			local _, blockChecks = string.gsub(loaderSrc, "AssetBlocklist%.isBlocked%(assetId%)", "")
			expect(blockChecks >= 2):toBe(true)
			expect(string.find(loaderSrc, "return sanitize(clone, assetId)", 1, true) ~= nil):toBe(true)
			expect(string.find(loaderSrc, "return sanitize(loaded, assetId)", 1, true) ~= nil):toBe(true)
			expect(string.find(loaderSrc, 'IsA("LuaSourceContainer")', 1, true) ~= nil):toBe(true)
			expect(string.find(loaderSrc, "return loaded\n", 1, true) == nil):toBe(true)
			expect(string.find(loaderSrc, "return clone\n", 1, true) == nil):toBe(true)
		end)

		t:it("no source file wires a blocked asset", function()
			for _, dir in ipairs({ "src/server/World", "src/shared", "src/client" }) do
				if fs.isDir(dir) then
					for _, name in ipairs(fs.readDir(dir)) do
						if string.sub(name, -5) == ".luau" and name ~= "AssetBlocklist.luau" then
							local src = fs.readFile(dir .. "/" .. name)
							for _, id in ipairs(AssetBlocklist.ids()) do
								expect(string.find(src, tostring(id), 1, true) == nil):toBe(true)
							end
						end
					end
				end
			end
		end)
	end)
end
