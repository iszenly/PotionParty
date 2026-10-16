--!strict
--[[
	Rarities.luau
	Raridades dos ingredientes. "brewSeconds" é somado ao tempo de preparo
	para CADA ingrediente daquela raridade na receita.
]]

local Types = require(script.Parent.Parent.Types)

local Rarities: { [string]: Types.RarityDef } = {
	Common = { order = 1, name = "Comum", color = Color3.fromRGB(200, 200, 200), brewSeconds = 2 },
	Uncommon = { order = 2, name = "Incomum", color = Color3.fromRGB(110, 220, 120), brewSeconds = 6 },
	Rare = { order = 3, name = "Raro", color = Color3.fromRGB(90, 160, 255), brewSeconds = 12 },
	Epic = { order = 4, name = "Épico", color = Color3.fromRGB(190, 110, 255), brewSeconds = 25 },
	Legendary = { order = 5, name = "Lendário", color = Color3.fromRGB(255, 190, 50), brewSeconds = 45 },
}

return Rarities
