-- Client bootstrap.

local LocalizationService = game:GetService("LocalizationService")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Strings = require(Shared.Strings)

local Hud = require(script.Parent.UI.Hud)
local Tiles = require(script.Parent.UI.Tiles)

local lang = Strings.langFor(LocalizationService.RobloxLocaleId)

Hud.mount(lang)
Tiles.mount(lang)
