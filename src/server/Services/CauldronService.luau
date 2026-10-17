--!strict
--[[
	CauldronService.luau
	Preparo de poções.

	Fluxo:
	1. StartBrew(slot, {ids}) -> gasta ingredientes e marca o caldeirão com
	   a hora em que fica pronto (os.time). O preparo continua contando mesmo
	   se o jogador sair do jogo, porque guardamos só o horário.
	2. CollectBrew(slot) -> se já passou do horário:
	   - sorteia a mutação (com o clima ATUAL do servidor);
	   - coloca a poção no inventário;
	   - se a receita é nova para o jogador, registra no Grimório e tenta a
	     Descoberta Mundial (em segundo plano);
	   - confere se é uma receita secreta da semana.

	O nome/efeito só é revelado ao coletar (o cliente não sabe antes).
	Para preparar basta TER o ingrediente (o "desbloqueio" libera a compra no
	Mercado; ingredientes do Cometa podem ser usados mesmo sem desbloquear).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Economy = require(ReplicatedStorage.Shared.Config.Economy)
local RecipeKey = require(ReplicatedStorage.Shared.Util.RecipeKey)
local PlayerStats = require(ReplicatedStorage.Shared.Util.PlayerStats)
local Net = require(script.Parent.Parent.Net)
local Announce = require(script.Parent.Parent.Announce)
local Validate = require(script.Parent.Parent.Util.Validate)
local DataService = require(script.Parent.DataService)
local MapService = require(script.Parent.MapService)
local SyncService = require(script.Parent.SyncService)
local RecipeService = require(script.Parent.RecipeService)
local IngredientService = require(script.Parent.IngredientService)
local MutationService = require(script.Parent.MutationService)
local WeatherService = require(script.Parent.WeatherService)
local DiscoveryService = require(script.Parent.DiscoveryService)
local MissionService = require(script.Parent.MissionService)

local CauldronService = {}

function CauldronService.init()
	Net.onInvoke("StartBrew", function(player, slot: any, ingredientIds: any)
		local data = DataService.get(player)
		if not data then
			return Net.fail("error.notLoaded")
		end
		if not Validate.integer(slot, 1, PlayerStats.cauldronCount(data)) then
			return Net.fail("error.invalid")
		end
		local ids = Validate.ingredientList(ingredientIds, Economy.maxIngredientsPerBrew)
		if not ids then
			return Net.fail("error.invalid")
		end
		local slotKey = tostring(slot)
		if data.cauldrons[slotKey] then
			return Net.fail("error.slotBusy")
		end
		if not MapService.isNear(player, "Cauldron") then
			return Net.fail("error.notNearCauldron")
		end
		local recipeKey = RecipeKey.fromIds(ids)
		if not RecipeService.resolve(recipeKey) then
			return Net.fail("error.invalid")
		end
		if not IngredientService.consume(data, ids) then
			return Net.fail("error.notEnoughIngredients")
		end

		local now = os.time()
		local seconds = PlayerStats.brewSeconds(data, ids)
		data.cauldrons[slotKey] = { key = recipeKey, startedAt = now, finishAt = now + seconds }
		SyncService.push(player)
		return Net.ok({ seconds = seconds })
	end)

	Net.onInvoke("CollectBrew", function(player, slot: any)
		local data = DataService.get(player)
		if not data then
			return Net.fail("error.notLoaded")
		end
		-- visibleCauldronCount: permite coletar de um caldeirão extra que sumiu (correção P18).
		if not Validate.integer(slot, 1, PlayerStats.visibleCauldronCount(data)) then
			return Net.fail("error.invalid")
		end
		local slotKey = tostring(slot)
		local brew = data.cauldrons[slotKey]
		if not brew then
			return Net.fail("error.slotEmpty")
		end
		if os.time() < brew.finishAt then
			return Net.fail("error.notReady")
		end
		if not MapService.isNear(player, "Cauldron") then
			return Net.fail("error.notNearCauldron")
		end
		if PlayerStats.potionCount(data) >= PlayerStats.potionCapacity(data) then
			return Net.fail("error.inventoryFull")
		end

		local recipeKey = brew.key
		local info = RecipeService.resolve(recipeKey);
		(data.cauldrons :: any)[slotKey] = nil
		if not info then
			-- A receita ficou inválida (ex.: ingrediente removido da Config). Descarta.
			SyncService.push(player)
			return Net.fail("error.invalid")
		end

		local mutation = MutationService.roll(WeatherService.current(), PlayerStats.luck(data))
		local stackKey = RecipeKey.stackKey(recipeKey, mutation)
		data.potions[stackKey] = (data.potions[stackKey] or 0) + 1
		data.stats.brewed += 1
		MissionService.progress(player, "brew", 1)

		local isNew = data.discovered[recipeKey] == nil
		if isNew then
			data.discovered[recipeKey] = { t = os.time() }
			DiscoveryService.register(player, recipeKey, info.name)
			DiscoveryService.markRankingDirty(player)
			MissionService.progress(player, "discover", 1)
		end

		local secretReward = DiscoveryService.checkWeeklySecret(data, recipeKey)
		if secretReward then
			data.stats.coinsEarned += secretReward
			Announce.player(player, "announce.weeklySecret", { reward = secretReward }, "world")
		end

		SyncService.push(player)
		return Net.ok({
			stackKey = stackKey,
			recipe = info,
			isNew = isNew,
			mutation = mutation,
		})
	end)
end

return CauldronService
