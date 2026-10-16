--!strict
--[[
	UpgradeService.luau
	Compra de melhorias. Os efeitos de cada melhoria são calculados em
	shared/Util/PlayerStats.luau (assim o cliente mostra os mesmos números).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Upgrades = require(ReplicatedStorage.Shared.Config.Upgrades)
local Net = require(script.Parent.Parent.Net)
local Validate = require(script.Parent.Parent.Util.Validate)
local DataService = require(script.Parent.DataService)
local SyncService = require(script.Parent.SyncService)

local UpgradeService = {}

function UpgradeService.init()
	Net.onInvoke("BuyUpgrade", function(player, upgradeId: any)
		local data = DataService.get(player)
		if not data then
			return Net.fail("error.notLoaded")
		end
		if not Validate.text(upgradeId, 32) then
			return Net.fail("error.invalid")
		end
		local def = Upgrades.byId[upgradeId]
		if not def then
			return Net.fail("error.invalid")
		end

		local level = data.upgrades[def.id] or 0
		local cost = Upgrades.costFor(def, level)
		if cost == nil then
			return Net.fail("error.maxLevel")
		end
		if data.coins < cost then
			return Net.fail("error.notEnoughCoins")
		end

		data.coins -= cost
		data.upgrades[def.id] = level + 1
		SyncService.push(player)
		return Net.ok({ level = level + 1 })
	end)
end

return UpgradeService
