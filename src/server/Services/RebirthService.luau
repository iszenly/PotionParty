--!strict
--[[
	RebirthService.luau
	"Novo Mestre" (rebirth): reinicia moedas e melhorias em troca de um
	multiplicador permanente de moedas (Config/Rebirth.luau).
	Mantém: receitas, Grimório, poções, ingredientes, cosméticos e Game Passes.
	Exige caldeirões vazios (os extras somem junto com as melhorias).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Economy = require(ReplicatedStorage.Shared.Config.Economy)
local Rebirth = require(ReplicatedStorage.Shared.Config.Rebirth)
local Net = require(script.Parent.Parent.Net)
local Announce = require(script.Parent.Parent.Announce)
local DataService = require(script.Parent.DataService)
local SyncService = require(script.Parent.SyncService)

local RebirthService = {}

function RebirthService.init()
	Net.onInvoke("Rebirth", function(player)
		local data = DataService.get(player)
		if not data then
			return Net.fail("error.notLoaded")
		end
		local cost = Rebirth.cost(data.rebirths)
		if data.coins < cost then
			return Net.fail("error.notEnoughCoins")
		end
		if next(data.cauldrons) ~= nil then
			return Net.fail("error.rebirthBrewing")
		end

		data.coins = Economy.startingCoins
		data.upgrades = {}
		data.rebirths += 1
		SyncService.push(player)
		Announce.all("announce.rebirth", { player = player.DisplayName, count = data.rebirths }, "world")
		return Net.ok({ rebirths = data.rebirths })
	end)
end

return RebirthService
