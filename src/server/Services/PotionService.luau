--!strict
--[[
	PotionService.luau
	Ações com poções do inventário: beber e vender.
	A mutação (parte depois do "#" na chave da pilha) muda a duração, adiciona
	um efeito extra e multiplica o preço.
	(Arremessar como respingo chega na Fase 3.)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Mutations = require(ReplicatedStorage.Shared.Config.Mutations)
local RecipeKey = require(ReplicatedStorage.Shared.Util.RecipeKey)
local PlayerStats = require(ReplicatedStorage.Shared.Util.PlayerStats)
local Net = require(script.Parent.Parent.Net)
local Validate = require(script.Parent.Parent.Util.Validate)
local DataService = require(script.Parent.DataService)
local MapService = require(script.Parent.MapService)
local SyncService = require(script.Parent.SyncService)
local RecipeService = require(script.Parent.RecipeService)
local EffectService = require(script.Parent.EffectService)
local RewardService = require(script.Parent.RewardService)
local MissionService = require(script.Parent.MissionService)

local MAX_KEY_LENGTH = 160

local PotionService = {}

-- Remove "amount" poções da pilha; apaga a chave quando zera.
local function takePotions(potions: { [string]: number }, stackKey: string, amount: number)
	local left = (potions[stackKey] or 0) - amount
	if left <= 0 then
		(potions :: any)[stackKey] = nil
	else
		potions[stackKey] = left
	end
end

function PotionService.init()
	Net.onInvoke("DrinkPotion", function(player, stackKey: any)
		local data = DataService.get(player)
		if not data then
			return Net.fail("error.notLoaded")
		end
		if not Validate.text(stackKey, MAX_KEY_LENGTH) then
			return Net.fail("error.invalid")
		end
		if (data.potions[stackKey] or 0) < 1 then
			return Net.fail("error.noPotion")
		end
		local recipeKey, mutationId = RecipeKey.splitStack(stackKey)
		local info = RecipeService.resolve(recipeKey)
		if not info then
			return Net.fail("error.invalid")
		end

		local mutation = if mutationId then Mutations.byId[mutationId] else nil
		local effect = table.clone(info.effect)
		effect.duration = Mutations.duration(mutationId, effect.duration)
		local displayName = if mutation then `{info.name} • {mutation.name}` else info.name
		local overlay = if mutation then mutation.overlay else nil

		if not EffectService.apply(player, effect, displayName, overlay, info.color) then
			return Net.fail("error.noCharacter")
		end

		takePotions(data.potions, stackKey, 1)
		data.stats.drunk += 1
		MissionService.progress(player, "drink", 1)
		SyncService.push(player)
		return Net.ok({ name = displayName })
	end)

	Net.onInvoke("SellPotion", function(player, stackKey: any, amount: any)
		local data = DataService.get(player)
		if not data then
			return Net.fail("error.notLoaded")
		end
		if not Validate.text(stackKey, MAX_KEY_LENGTH) or not Validate.integer(amount, 1, 9999) then
			return Net.fail("error.invalid")
		end
		if (data.potions[stackKey] or 0) < amount then
			return Net.fail("error.noPotion")
		end
		if not MapService.isNear(player, "SellCounter") then
			return Net.fail("error.notNearSell")
		end
		local recipeKey, mutationId = RecipeKey.splitStack(stackKey)
		local info = RecipeService.resolve(recipeKey)
		if not info then
			return Net.fail("error.invalid")
		end

		local unitPrice = PlayerStats.sellPrice(data, info.value * Mutations.priceMultiplier(mutationId))
		local total = unitPrice * amount
		takePotions(data.potions, stackKey, amount)
		data.stats.sold += amount
		local earned = RewardService.coins(player, data, total)
		MissionService.progress(player, "sell", amount)
		SyncService.push(player)
		return Net.ok({ coins = earned })
	end)
end

return PotionService
