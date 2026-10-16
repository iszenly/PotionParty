--!strict
--[[
	Upgrades.luau
	Melhorias compráveis com moedas.

	Preço do próximo nível = floor(baseCost * costGrowth ^ nivelAtual),
	a não ser que "costs" exista (lista de preços fixos por nível).
	O significado de "valuePerLevel" depende da melhoria (veja PlayerStats.luau).
]]

local Types = require(script.Parent.Parent.Types)

local list: { Types.UpgradeDef } = {
	{
		id = "BrewSpeed",
		name = "Fogo Rápido",
		description = "-10% no tempo de preparo por nível",
		maxLevel = 10,
		valuePerLevel = 0.1,
		baseCost = 150,
		costGrowth = 1.6,
	},
	{
		id = "ExtraCauldron",
		name = "Caldeirão Extra",
		description = "+1 caldeirão para preparar ao mesmo tempo",
		maxLevel = 3,
		valuePerLevel = 1,
		baseCost = 0,
		costGrowth = 1,
		costs = { 500, 2500, 10000 },
	},
	{
		id = "Storage",
		name = "Prateleira Maior",
		description = "+10 espaços para poções",
		maxLevel = 10,
		valuePerLevel = 10,
		baseCost = 100,
		costGrowth = 1.5,
	},
	{
		id = "SellPrice",
		name = "Vitrine Brilhante",
		description = "+10% no preço de venda",
		maxLevel = 10,
		valuePerLevel = 0.1,
		baseCost = 200,
		costGrowth = 1.7,
	},
	-- Loja (tycoon)
	{
		id = "ShopShelves",
		name = "Prateleiras Extras",
		description = "+1 cliente ao mesmo tempo na sua loja",
		maxLevel = 5,
		valuePerLevel = 1,
		baseCost = 300,
		costGrowth = 1.8,
	},
	{
		id = "ShopShowcase",
		name = "Vitrine Mágica",
		description = "+5% de chance de pedidos especiais (pagam mais)",
		maxLevel = 5,
		valuePerLevel = 0.05,
		baseCost = 400,
		costGrowth = 1.9,
	},
}

local byId: { [string]: Types.UpgradeDef } = {}
for _, def in list do
	byId[def.id] = def
end

-- Retorna o preço para subir do nível "level" para o próximo, ou nil se já está no máximo.
local function costFor(def: Types.UpgradeDef, level: number): number?
	if level >= def.maxLevel then
		return nil
	end
	if def.costs then
		return def.costs[level + 1]
	end
	return math.floor(def.baseCost * def.costGrowth ^ level)
end

return {
	list = list,
	byId = byId,
	costFor = costFor,
}
