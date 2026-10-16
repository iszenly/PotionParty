--!strict
--[[
	Remotes.luau
	Limite de frequência (rate limit) de cada chamada do cliente para o servidor.
		rate  = quantas chamadas por segundo são recuperadas
		burst = quantas chamadas seguidas são permitidas de uma vez
	Se o cliente passar do limite, o servidor recusa a chamada.
]]

export type Limit = { rate: number, burst: number }

local limits: { [string]: Limit } = {
	default = { rate = 4, burst = 8 },
	GetSnapshot = { rate = 2, burst = 5 },
	StartBrew = { rate = 2, burst = 4 },
	CollectBrew = { rate = 3, burst = 6 },
	DrinkPotion = { rate = 1, burst = 2 },
	SellPotion = { rate = 4, burst = 8 },
	BuyIngredient = { rate = 4, burst = 8 },
	UnlockIngredient = { rate = 1, burst = 3 },
	BuyUpgrade = { rate = 2, burst = 4 },
	GetGrimoireInfo = { rate = 0.5, burst = 3 },
	GetRanking = { rate = 0.2, burst = 2 },
	Debug = { rate = 2, burst = 4 }, -- só existe no Studio
	-- Fase 3
	ClaimMission = { rate = 1, burst = 3 },
	ClaimDaily = { rate = 0.5, burst = 2 },
	SetShield = { rate = 1, burst = 3 },
	EquipTrail = { rate = 1, burst = 3 },
	ThrowPotion = { rate = 1, burst = 2 },
	ShopDeliver = { rate = 3, burst = 6 },
	VisitShop = { rate = 0.5, burst = 2 },
	TradeRequest = { rate = 0.5, burst = 3 },
	TradeRespond = { rate = 1, burst = 3 },
	TradeSetOffer = { rate = 4, burst = 8 },
	TradeSetReady = { rate = 2, burst = 4 },
	TradeConfirm = { rate = 1, burst = 3 },
	TradeCancel = { rate = 1, burst = 3 },
	FriendshipPick = { rate = 3, burst = 6 },
	FriendshipReady = { rate = 2, burst = 4 },
	FriendshipLeave = { rate = 1, burst = 3 },
	Rebirth = { rate = 0.2, burst = 1 },
}

return limits
