--!strict
--[[
	IngredientService.luau
	Compra e liberação de ingredientes no Mercado + funções para conferir e
	gastar ingredientes (usadas pelo caldeirão).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Shared.Types)
local Economy = require(ReplicatedStorage.Shared.Config.Economy)
local Ingredients = require(ReplicatedStorage.Shared.Config.Ingredients)
local Net = require(script.Parent.Parent.Net)
local Validate = require(script.Parent.Parent.Util.Validate)
local DataService = require(script.Parent.DataService)
local MapService = require(script.Parent.MapService)
local SyncService = require(script.Parent.SyncService)

type PlayerData = Types.PlayerData

local IngredientService = {}

-- Conta quantos de cada ingrediente a lista pede (a lista pode repetir ids).
local function countIds(ids: { string }): { [string]: number }
	local needed: { [string]: number } = {}
	for _, id in ids do
		needed[id] = (needed[id] or 0) + 1
	end
	return needed
end

function IngredientService.hasAll(data: PlayerData, ids: { string }): boolean
	for id, amount in countIds(ids) do
		if (data.ingredients[id] or 0) < amount then
			return false
		end
	end
	return true
end

-- Gasta os ingredientes. Retorna false (sem gastar nada) se faltar algum.
function IngredientService.consume(data: PlayerData, ids: { string }): boolean
	if not IngredientService.hasAll(data, ids) then
		return false
	end
	for id, amount in countIds(ids) do
		data.ingredients[id] -= amount
	end
	return true
end

function IngredientService.add(data: PlayerData, id: string, amount: number)
	data.ingredients[id] = (data.ingredients[id] or 0) + amount
end

function IngredientService.init()
	Net.onInvoke("BuyIngredient", function(player, id: any, amount: any)
		local data = DataService.get(player)
		if not data then
			return Net.fail("error.notLoaded")
		end
		if not Validate.ingredientId(id) or not Validate.integer(amount, 1, Economy.maxBuyAmount) then
			return Net.fail("error.invalid")
		end
		if Ingredients.byId[id].cometOnly then
			return Net.fail("error.invalid") -- só vem do Cometa
		end
		if not data.unlocked[id] then
			return Net.fail("error.locked")
		end
		if not MapService.isNear(player, "Market") then
			return Net.fail("error.notNearMarket")
		end
		local cost = Ingredients.byId[id].price * amount
		if data.coins < cost then
			return Net.fail("error.notEnoughCoins")
		end

		data.coins -= cost
		IngredientService.add(data, id, amount)
		SyncService.push(player)
		return Net.ok()
	end)

	Net.onInvoke("UnlockIngredient", function(player, id: any)
		local data = DataService.get(player)
		if not data then
			return Net.fail("error.notLoaded")
		end
		if not Validate.ingredientId(id) or Ingredients.byId[id].cometOnly then
			return Net.fail("error.invalid")
		end
		if data.unlocked[id] then
			return Net.fail("error.alreadyUnlocked")
		end
		if not MapService.isNear(player, "Market") then
			return Net.fail("error.notNearMarket")
		end
		local cost = Ingredients.byId[id].unlockPrice
		if data.coins < cost then
			return Net.fail("error.notEnoughCoins")
		end

		data.coins -= cost
		data.unlocked[id] = true
		IngredientService.add(data, id, Economy.unlockBonusAmount)
		SyncService.push(player)
		return Net.ok()
	end)
end

return IngredientService
