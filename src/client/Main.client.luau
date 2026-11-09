-- Client bootstrap: mount the HUD, tile presentation, phone, minigame and raid overlay.

local LocalizationService = game:GetService("LocalizationService")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Strings = require(Shared.Strings)

local Hud = require(script.Parent.UI.Hud)
local Tiles = require(script.Parent.UI.Tiles)
local Evidence = require(script.Parent.UI.Evidence)
local Phone = require(script.Parent.UI.Phone)
local Minigame = require(script.Parent.UI.Minigame)
local RaidOverlay = require(script.Parent.UI.RaidOverlay)
local Tags = require(script.Parent.Chat.Tags)

local lang = Strings.langFor(LocalizationService.RobloxLocaleId)

local hudGui = Hud.mount(lang)
Evidence.mount(lang, hudGui)
Phone.mount(lang)
Minigame.mount(lang)
RaidOverlay.mount(lang)
Tags.mount()
Tiles.mount(lang)
