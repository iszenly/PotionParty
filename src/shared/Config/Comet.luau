--!strict
--[[
	Comet.luau
	Evento do Cometa: de tempos em tempos um cometa cai no centro do mapa,
	espalha ingredientes raros e deixa um núcleo de energia. Se os jogadores
	do servidor encherem JUNTOS a barra de energia, todos que ajudaram ganham
	o ingrediente lendário "Poeira de Cometa".
]]

return {
	interval = 600, -- segundos entre cometas
	warningSeconds = 15, -- aviso antes da queda
	fallSeconds = 3, -- duração da queda (animação)
	activeSeconds = 90, -- quanto tempo os itens e o núcleo ficam no chão

	center = Vector3.new(0, 0, 34), -- onde o cometa cai (atrás do spawn)
	scatterMinRadius = 8,
	scatterMaxRadius = 34,

	-- Ingredientes espalhados: base + porJogador, até o máximo
	pickupsBase = 6,
	pickupsPerPlayer = 2,
	pickupsMax = 20,
	-- Peso de cada raridade no sorteio dos ingredientes espalhados
	pickupRarityWeights = { Uncommon = 60, Rare = 30, Epic = 10 } :: { [string]: number },

	-- Barra de energia coletiva: energia necessária = base + porJogador * jogadores
	energyBase = 20,
	energyPerPlayer = 15,
	tapCooldown = 0.35, -- segundos entre toques do mesmo jogador
	minTapsForReward = 3, -- toques mínimos para ganhar a recompensa
	legendaryIngredient = "Stardust",
	legendaryAmount = 1,
}
