--!strict
--[[
	Economy.luau
	Números gerais de balanceamento. Mexa à vontade para testar.
]]

return {
	-- Início do jogo
	startingCoins = 100,
	startingIngredientAmount = 5, -- de cada ingrediente básico

	-- Receitas
	maxIngredientsPerBrew = 3,
	maxFriendshipIngredients = 4, -- Caldeirão da Amizade: 2 de cada jogador (receitas exclusivas)
	traitThreshold = 2, -- peso mínimo para um traço entrar no efeito
	comboMultiplier = { 1, 1.4, 1.9, 2.6 }, -- valor da poção com 1, 2, 3 ou 4 ingredientes (4 = Amizade)
	specialRecipeMultiplier = 2, -- receitas fixas valem mais (pode ser sobrescrito por receita)

	-- Caldeirão
	brewBaseSeconds = 3, -- + Rarities[x].brewSeconds por ingrediente

	-- Efeitos
	effectBaseDuration = 25, -- segundos
	effectDurationPerRarity = 8, -- + segundos por nível de raridade acima de Comum, por ingrediente
	flyUpSpeed = 28, -- velocidade de subida ao segurar pulo com efeito de voo

	-- Inventário
	basePotionCapacity = 20,

	-- Mercado
	maxBuyAmount = 50,
	unlockBonusAmount = 3, -- ingredientes grátis ao desbloquear

	-- Anti-exploit: distância máxima (studs) de uma estação para usar suas ações
	stationRadius = 16,
}
