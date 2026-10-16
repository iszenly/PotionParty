--!strict
--[[
	RewardService.luau
	Ponto único para dar moedas "ganhas jogando" (vendas e pedidos da loja).
	Aplica o bônus de amigos, soma nas estatísticas e na missão "earn".
	(Recompensas fixas, como missões e diária, não passam por aqui.)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Shared.Types)
local FriendService = require(script.Parent.FriendService)
local MissionService = require(script.Parent.MissionService)

local RewardService = {}

-- Dá as moedas e retorna o total final (com bônus).
function RewardService.coins(player: Player, data: Types.PlayerData, amount: number): number
	local total = math.floor(amount * FriendService.coinMultiplier(player) + 0.5)
	data.coins += total
	data.stats.coinsEarned += total
	MissionService.progress(player, "earn", total)
	return total
end

return RewardService
