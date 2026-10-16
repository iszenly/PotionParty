--!strict
--[[
	Monetization.luau
	Game Passes e Developer Products.

	COMO CONFIGURAR:
	1. No Creator Hub (create.roblox.com) -> seu jogo -> Monetização:
	   crie cada Pass e cada Developer Product e defina o preço em Robux.
	2. Copie o ID de cada um para o campo "id" abaixo.
	   Com id = 0 o botão aparece como "em breve" e nada é vendido.

	REGRA DE OURO (jogo justo): nada aqui pode comprar uma Descoberta Mundial,
	posição no ranking ou vantagem sobre outros jogadores em troca/respingo.
]]

export type PassDef = { key: string, id: number, name: string, description: string, icon: string }

export type ProductGrant = {
	ingredients: { [string]: number }?,
	finishBrews: boolean?,
	cosmetic: string?,
}

export type ProductDef = {
	key: string,
	id: number,
	name: string,
	description: string,
	icon: string,
	grant: ProductGrant,
}

export type CosmeticDef = { id: string, name: string, colors: { Color3 } }

local passes: { PassDef } = {
	{
		key = "ExtraCauldron",
		id = 0,
		name = "Caldeirão Extra",
		description = "+1 caldeirão para sempre",
		icon = "🧪",
	},
	{
		key = "AutoSell",
		id = 0,
		name = "Auto-venda",
		description = "Clientes atendidos sozinhos e o dobro de vendas offline",
		icon = "🤖",
	},
	{ key = "VipLuck", id = 0, name = "Sorte VIP", description = "Dobro de chance de mutações", icon = "🍀" },
	{ key = "BigShop", id = 0, name = "Loja Maior", description = "+2 clientes ao mesmo tempo", icon = "🏪" },
}

local products: { ProductDef } = {
	{
		key = "IngredientPackSmall",
		id = 0,
		name = "Pacote de Ingredientes",
		description = "3x Raio, Nuvem, Bolha e Pizza",
		icon = "🧺",
		grant = { ingredients = { Lightning = 3, Cloud = 3, Bubble = 3, Pizza = 3 } },
	},
	{
		key = "IngredientPackBig",
		id = 0,
		name = "Baú de Ingredientes Raros",
		description = "3x Lua, Lava e Ímã + 2x Fantasma e Estrela",
		icon = "🎁",
		grant = { ingredients = { Moon = 3, Lava = 3, Magnet = 3, Ghost = 2, Star = 2 } },
	},
	{
		key = "BrewSkip",
		id = 0,
		name = "Acelerar Preparo",
		description = "Termina todos os caldeirões agora",
		icon = "⏩",
		grant = { finishBrews = true },
	},
	{
		key = "TrailSparkle",
		id = 0,
		name = "Trilha Brilhante",
		description = "Rastro dourado ao andar (cosmético)",
		icon = "✨",
		grant = { cosmetic = "TrailSparkle" },
	},
	{
		key = "TrailRainbow",
		id = 0,
		name = "Trilha Arco-íris",
		description = "Rastro arco-íris ao andar (cosmético)",
		icon = "🌈",
		grant = { cosmetic = "TrailRainbow" },
	},
}

-- TODO(asset): texturas próprias para as trilhas.
local cosmetics: { [string]: CosmeticDef } = {
	TrailSparkle = {
		id = "TrailSparkle",
		name = "Trilha Brilhante",
		colors = { Color3.fromRGB(255, 230, 120), Color3.fromRGB(255, 170, 40) },
	},
	TrailRainbow = {
		id = "TrailRainbow",
		name = "Trilha Arco-íris",
		colors = {
			Color3.fromRGB(255, 80, 80),
			Color3.fromRGB(255, 210, 60),
			Color3.fromRGB(90, 220, 120),
			Color3.fromRGB(80, 160, 255),
			Color3.fromRGB(200, 100, 255),
		},
	},
}

local passByKey: { [string]: PassDef } = {}
local passById: { [number]: PassDef } = {}
for _, def in passes do
	passByKey[def.key] = def
	if def.id ~= 0 then
		passById[def.id] = def
	end
end

local productById: { [number]: ProductDef } = {}
for _, def in products do
	if def.id ~= 0 then
		productById[def.id] = def
	end
end

return {
	passes = passes,
	products = products,
	cosmetics = cosmetics,
	passByKey = passByKey,
	passById = passById,
	productById = productById,
}
