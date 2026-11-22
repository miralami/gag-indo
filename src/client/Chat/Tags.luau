-- Tags: chat prefix for Juragan and the Ordal pass (GDD §7 ranks, §9.1 passes).
-- Purely cosmetic and client-side: the attributes it reads are already replicated, and
-- TextChatService.OnIncomingMessage only changes what this client sees.

local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Strings = require(Shared.Strings)

local Tags = {}

-- Supplied by Main.client at mount(); defaults to Indonesian for specs that call mount() bare.
local lang = "id"

-- Returns e.g. "[Juragan][Ordal] " or nil when the sender has no tag.
local function prefixFor(source: TextSource?): string?
	if not source then
		return nil
	end
	local player = Players:GetPlayerByUserId(source.UserId)
	if not player then
		return nil
	end
	local labels: { string } = {}
	if player:GetAttribute("Rank") == "juragan" then
		table.insert(labels, Strings.get(lang, "tag_juragan"))
	end
	if player:GetAttribute("Pass_Ordal") then
		table.insert(labels, Strings.get(lang, "tag_ordal"))
	end
	if #labels == 0 then
		return nil
	end
	return "[" .. table.concat(labels, "][") .. "] "
end

function Tags.mount(langCode: string?)
	lang = Strings.langFor(langCode or "id")
	TextChatService.OnIncomingMessage = function(message: TextChatMessage)
		local prefix = prefixFor(message.TextSource)
		if not prefix then
			return nil
		end
		local props = Instance.new("TextChatMessageProperties")
		props.PrefixText = prefix .. (message.PrefixText or "")
		return props
	end
end

return Tags
