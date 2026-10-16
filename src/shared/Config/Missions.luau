--!strict
--[[
	Missions.luau
	Missões diárias: todo dia (00:00 UTC) cada jogador recebe "perDay" missões
	sorteadas desta lista. O sorteio usa o dia + UserId como semente, então
	sair e voltar não troca as missões.

	text:          texto com {n} = quantidade
	min/max/step:  quantidade sorteada
	rewardPerUnit: moedas por unidade (mínimo minReward)
]]

export type MissionDef = {
	id: string, -- também é o "tipo" de progresso (MissionService.progress)
	text: string,
	min: number,
	max: number,
	step: number?,
	rewardPerUnit: number,
}

local list: { MissionDef } = {
	{ id = "brew", text = "Prepare {n} poções", min = 5, max = 12, rewardPerUnit = 25 },
	{ id = "sell", text = "Venda {n} poções no balcão", min = 5, max = 15, rewardPerUnit = 20 },
	{ id = "discover", text = "Descubra {n} receitas novas", min = 1, max = 3, rewardPerUnit = 150 },
	{ id = "drink", text = "Beba {n} poções", min = 2, max = 5, rewardPerUnit = 40 },
	{ id = "serve", text = "Atenda {n} clientes na sua loja", min = 3, max = 8, rewardPerUnit = 50 },
	{ id = "splash", text = "Dê {n} respingos em outros jogadores", min = 1, max = 3, rewardPerUnit = 60 },
	{ id = "comet", text = "Pegue {n} ingredientes do Cometa", min = 1, max = 3, rewardPerUnit = 80 },
	{ id = "earn", text = "Ganhe {n} moedas", min = 300, max = 1500, step = 100, rewardPerUnit = 0.2 },
}

local byId: { [string]: MissionDef } = {}
for _, def in list do
	byId[def.id] = def
end

return {
	perDay = 3,
	minReward = 50,
	list = list,
	byId = byId,
}
