--!strict
--[[
	Ingredients.luau
	Lista de todos os ingredientes do jogo.

	COMO ADICIONAR UM INGREDIENTE:
	1. Copie uma linha abaixo e troque o "id" (em inglês, sem espaços, único).
	2. Ajuste nome, raridade, cor, preços e "traits".
	3. "traits" são os atributos que definem o efeito: { NomeDoTraço = peso }.
	   Os traços existentes estão em Config/Traits.luau. Quanto maior o peso,
	   mais chance daquele traço "vencer" na sua categoria quando misturado.
	4. unlockPrice = 0 deixa o ingrediente liberado desde o início.

	ATENÇÃO: nunca renomeie o "id" de um ingrediente já lançado; os dados salvos
	dos jogadores usam esse id.
]]

local Types = require(script.Parent.Parent.Types)

-- TODO(asset): trocar as cores por ícones/modelos finais de cada ingrediente.
local list: { Types.IngredientDef } = {
	-- Básicos (liberados desde o início)
	{
		id = "Mushroom",
		name = "Cogumelo",
		rarity = "Common",
		color = Color3.fromRGB(214, 69, 65),
		price = 10,
		sellValue = 8,
		unlockPrice = 0,
		traits = { Giant = 2, Frog = 1, Bouncy = 1 },
	},
	{
		id = "Feather",
		name = "Pena",
		rarity = "Common",
		color = Color3.fromRGB(245, 245, 235),
		price = 10,
		sellValue = 8,
		unlockPrice = 0,
		traits = { Fly = 2, Floaty = 1 },
	},
	{
		id = "Pepper",
		name = "Pimenta",
		rarity = "Common",
		color = Color3.fromRGB(230, 40, 30),
		price = 10,
		sellValue = 8,
		unlockPrice = 0,
		traits = { Speedy = 2, Fire = 2 },
	},
	{
		id = "Ice",
		name = "Gelo",
		rarity = "Common",
		color = Color3.fromRGB(150, 220, 255),
		price = 10,
		sellValue = 8,
		unlockPrice = 0,
		traits = { Mini = 2, Snow = 2, Slow = 1 },
	},
	{
		id = "Honey",
		name = "Mel",
		rarity = "Common",
		color = Color3.fromRGB(255, 180, 30),
		price = 10,
		sellValue = 8,
		unlockPrice = 0,
		traits = { Glow = 2, Slow = 1, Frog = 1 },
	},
	{
		id = "Stone",
		name = "Pedra",
		rarity = "Common",
		color = Color3.fromRGB(130, 130, 135),
		price = 10,
		sellValue = 8,
		unlockPrice = 0,
		traits = { Rock = 2, Giant = 1, Slow = 1 },
	},

	-- Desbloqueáveis
	{
		id = "Lightning",
		name = "Raio",
		rarity = "Uncommon",
		color = Color3.fromRGB(255, 235, 60),
		price = 35,
		sellValue = 22,
		unlockPrice = 250,
		traits = { Speedy = 3, Electric = 3 },
	},
	{
		id = "Cloud",
		name = "Nuvem",
		rarity = "Uncommon",
		color = Color3.fromRGB(235, 240, 255),
		price = 35,
		sellValue = 22,
		unlockPrice = 250,
		traits = { Cloud = 3, Fly = 2 },
	},
	{
		id = "Bubble",
		name = "Bolha",
		rarity = "Uncommon",
		color = Color3.fromRGB(140, 210, 255),
		price = 35,
		sellValue = 22,
		unlockPrice = 300,
		traits = { Bouncy = 3, Bubbles = 2, Frog = 1 },
	},
	{
		id = "Pizza",
		name = "Pizza",
		rarity = "Uncommon",
		color = Color3.fromRGB(240, 170, 60),
		price = 35,
		sellValue = 22,
		unlockPrice = 300,
		traits = { Pizza = 3, Giant = 2, Bouncy = 1 },
	},
	{
		id = "Moon",
		name = "Lua",
		rarity = "Rare",
		color = Color3.fromRGB(200, 200, 255),
		price = 90,
		sellValue = 55,
		unlockPrice = 1000,
		traits = { Floaty = 3, Glow = 2, Ghost = 1 },
	},
	{
		id = "Lava",
		name = "Lava",
		rarity = "Rare",
		color = Color3.fromRGB(255, 90, 20),
		price = 90,
		sellValue = 55,
		unlockPrice = 1000,
		traits = { Fire = 3, Rock = 2, Giant = 1 },
	},
	{
		id = "Magnet",
		name = "Ímã",
		rarity = "Rare",
		color = Color3.fromRGB(200, 40, 60),
		price = 90,
		sellValue = 55,
		unlockPrice = 1200,
		traits = { Metal = 3, Mini = 2, Electric = 1 },
	},
	{
		id = "Ghost",
		name = "Fantasma",
		rarity = "Epic",
		color = Color3.fromRGB(230, 240, 255),
		price = 220,
		sellValue = 130,
		unlockPrice = 4000,
		traits = { Ghost = 4, Floaty = 2 },
	},
	{
		id = "Star",
		name = "Estrela",
		rarity = "Epic",
		color = Color3.fromRGB(255, 220, 90),
		price = 220,
		sellValue = 130,
		unlockPrice = 4500,
		traits = { Sparkle = 4, Fly = 1, Glow = 1 },
	},
	{
		id = "Rainbow",
		name = "Arco-íris",
		rarity = "Legendary",
		color = Color3.fromRGB(255, 120, 200),
		price = 600,
		sellValue = 340,
		unlockPrice = 15000,
		traits = { Rainbow = 5, Speedy = 1 },
	},

	-- Só do Cometa (não aparece à venda no Mercado)
	{
		id = "Stardust",
		name = "Poeira de Cometa",
		rarity = "Legendary",
		color = Color3.fromRGB(170, 120, 255),
		price = 0,
		sellValue = 400,
		unlockPrice = 0,
		cometOnly = true,
		traits = { Cosmic = 5, Floaty = 2, Giant = 1 },
	},
}

-- Índice por id para buscas rápidas: Ingredients.byId["Mushroom"]
local byId: { [string]: Types.IngredientDef } = {}
for _, def in list do
	if byId[def.id] then
		warn(`[Ingredients] id duplicado: {def.id}`)
	end
	byId[def.id] = def
end

return {
	list = list,
	byId = byId,
}
