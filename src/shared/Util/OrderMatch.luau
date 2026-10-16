--!strict
--[[
	OrderMatch.luau
	Regras dos pedidos dos clientes NPC (usadas pelo servidor para validar e
	pelo cliente para mostrar quais poções servem).
]]

local Shared = script.Parent.Parent
local Types = require(Shared.Types)
local Locale = require(Shared.Locale)
local Describe = require(script.Parent.Describe)

local OrderMatch = {}

local function effectHas(effect: Types.PotionEffect, traitId: string): boolean
	return effect.size == traitId or effect.form == traitId or effect.movement == traitId or effect.visual == traitId
end

-- A poção (receita "recipeKey") atende este pedido?
function OrderMatch.matches(order: Types.Order, recipeKey: string, info: Types.RecipeInfo): boolean
	if order.kind == "recipe" then
		return recipeKey == order.recipeKey
	end
	local traits: { string } = order.traits or {}
	if #traits == 0 then
		return false
	end
	for _, traitId in traits do
		if not effectHas(info.effect, traitId) then
			return false
		end
	end
	return true
end

-- Texto do balão do cliente: "Quero voar e brilhar!"
function OrderMatch.describe(order: Types.Order): string
	if order.kind == "recipe" then
		return Locale.t("order.recipe", { name = order.recipeName or "?" })
	end
	local names: { string } = {}
	local traits: { string } = order.traits or {}
	for _, traitId in traits do
		table.insert(names, string.lower(Describe.trait(traitId)))
	end
	return Locale.t("order.effect", { effects = table.concat(names, Locale.t("order.and")) })
end

return OrderMatch
