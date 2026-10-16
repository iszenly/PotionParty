--!strict
--[[
	Describe.luau
	Textos amigáveis para efeitos de poção: "Gigante • Voar • Brilhar".
]]

local Shared = script.Parent.Parent
local Types = require(Shared.Types)
local Traits = require(Shared.Config.Traits)
local Locale = require(Shared.Locale)

local Describe = {}

function Describe.trait(traitId: string): string
	local def = Traits.byId[traitId]
	return Locale.name("trait", traitId, if def then def.name else traitId)
end

function Describe.effect(effect: Types.PotionEffect): string
	local parts: { string } = {}
	for _, traitId in { effect.size, effect.form, effect.movement, effect.visual } :: { string? } do
		if traitId then
			table.insert(parts, Describe.trait(traitId))
		end
	end
	if #parts == 0 then
		return Locale.t("ui.noEffect")
	end
	return table.concat(parts, " • ")
end

return Describe
