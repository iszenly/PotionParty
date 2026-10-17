--!strict
--[[
	DebugService.luau
	Atalhos de teste que SÓ existem no Studio (o Remote nem é criado em
	servidores reais). O painel aparece no canto da tela durante o Play.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Debug = require(ReplicatedStorage.Shared.Config.Debug)
local Ingredients = require(ReplicatedStorage.Shared.Config.Ingredients)
local Net = require(script.Parent.Parent.Net)
local DataService = require(script.Parent.DataService)
local SyncService = require(script.Parent.SyncService)
local WeatherService = require(script.Parent.WeatherService)
local CometService = require(script.Parent.CometService)
local MutationService = require(script.Parent.MutationService)
local ShopService = require(script.Parent.ShopService)

local DebugService = {}

function DebugService.init()
	if not Debug.enabled() then
		return
	end
	warn("[PotionParty] modo DEBUG ativo (só no Studio)")

	Net.onInvoke("Debug", function(player, command: any, argument: any)
		local data = DataService.get(player)
		if not data then
			return Net.fail("error.notLoaded")
		end
		if command == "weather" then
			WeatherService.force(if type(argument) == "string" and argument ~= "Clear" then argument else nil)
		elseif command == "comet" then
			CometService.trigger()
		elseif command == "coins" then
			data.coins += 5000
		elseif command == "ingredients" then
			for _, def in Ingredients.list do
				data.ingredients[def.id] = (data.ingredients[def.id] or 0) + 10
			end
		elseif command == "mutation" then
			MutationService.forceNext(if type(argument) == "string" then argument else nil)
		elseif command == "finishBrews" then
			for _, slot in data.cauldrons do
				slot.finishAt = os.time()
			end
		elseif command == "coinsBig" then
			data.coins += 100000
		elseif command == "pass" and type(argument) == "string" then
			-- Liga/desliga um Game Pass só nesta sessão de teste (sem Robux).
			(data.passes :: any)[argument] = if data.passes[argument] then nil else true
		elseif command == "resetDaily" then
			-- Simula "voltei amanhã": a diária fica disponível e a sequência continua.
			data.streak.lastClaimDay = os.time() // 86400 - 1
		elseif command == "resetMissions" then
			data.missions = { day = 0, list = {} }
		elseif command == "offline" then
			-- Simula ter ficado 2 horas offline e roda a venda automática agora.
			-- (Não mexe em data.lastLogout: a simulação não afeta o próximo login.)
			ShopService.offlineSales(player, data, os.time() - 7200)
		else
			return Net.fail("error.invalid")
		end
		SyncService.push(player)
		return Net.ok()
	end)
end

return DebugService
