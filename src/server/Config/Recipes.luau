--!strict
--[[
	Recipes.luau (SERVIDOR)
	Receitas especiais escritas à mão. Toda combinação que NÃO estiver aqui
	gera uma poção procedural (veja RecipeService).

	Este arquivo fica no servidor de propósito: se ficasse em "shared", qualquer
	jogador poderia ler a lista e estragar a graça das descobertas.

	COMO ADICIONAR UMA RECEITA:
		recipe({ "Feather", "Pepper", "Cloud" }, {
			name = "Poção do Galo Foguete",
			movement = "Fly",          -- ids de Config/Traits.luau (todos opcionais)
			visual = "Fire",
			-- size = "Giant", form = "Frog",
			-- duration = 40,          -- segundos (opcional)
			-- valueMultiplier = 3,    -- opcional, padrão em Economy.specialRecipeMultiplier
		})
	A ordem dos ingredientes não importa. Ingredientes repetidos são permitidos
	({ "Mushroom", "Mushroom" }).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RecipeKey = require(ReplicatedStorage.Shared.Util.RecipeKey)
local Ingredients = require(ReplicatedStorage.Shared.Config.Ingredients)
local Traits = require(ReplicatedStorage.Shared.Config.Traits)

export type FixedRecipe = {
	name: string,
	size: string?,
	form: string?,
	movement: string?,
	visual: string?,
	duration: number?,
	valueMultiplier: number?,
}

local byKey: { [string]: FixedRecipe } = {}

local function recipe(ingredientIds: { string }, def: FixedRecipe)
	-- Validação para pegar erros de digitação logo ao iniciar o servidor.
	for _, id in ingredientIds do
		if not Ingredients.byId[id] then
			warn(`[Recipes] ingrediente desconhecido "{id}" na receita "{def.name}"`)
			return
		end
	end
	for _, traitId in { def.size, def.form, def.movement, def.visual } :: { string? } do
		if traitId and not Traits.byId[traitId] then
			warn(`[Recipes] traço desconhecido "{traitId}" na receita "{def.name}"`)
			return
		end
	end
	local key = RecipeKey.fromIds(ingredientIds)
	if byKey[key] then
		warn(`[Recipes] receita repetida: {key}`)
	end
	byKey[key] = def
end

-- Só com básicos -------------------------------------------------------------
recipe({ "Mushroom", "Mushroom" }, { name = "Poção do Cogumelo Gigantesco", size = "Giant", movement = "Bouncy" })
recipe({ "Honey", "Ice" }, { name = "Poção do Picolé de Abelha", size = "Mini", visual = "Snow", movement = "Slow" })
recipe({ "Ice", "Pepper" }, { name = "Poção do Choque Térmico", movement = "Speedy", visual = "Electric" })
recipe({ "Feather", "Honey" }, { name = "Poção da Abelha Rainha", size = "Mini", movement = "Fly", visual = "Glow" })
recipe(
	{ "Mushroom", "Stone", "Stone" },
	{ name = "Poção do Golem Dorminhoco", size = "Giant", form = "Rock", movement = "Slow" }
)

-- Com desbloqueáveis ---------------------------------------------------------
recipe({ "Feather", "Pepper", "Cloud" }, { name = "Poção do Galo Foguete", movement = "Fly", visual = "Fire" })
recipe(
	{ "Mushroom", "Bubble" },
	{ name = "Poção do Sapo Saltitante", size = "Mini", form = "Frog", movement = "Bouncy" }
)
recipe(
	{ "Ghost", "Moon" },
	{ name = "Poção da Assombração Sonolenta", form = "Ghost", movement = "Floaty", visual = "Glow" }
)
recipe({ "Mushroom", "Pizza", "Stone" }, { name = "Poção do Gigante Comilão", size = "Giant", form = "Pizza" })
recipe(
	{ "Feather", "Star" },
	{ name = "Poção da Fada Madrinha", size = "Mini", movement = "Fly", visual = "Sparkle" }
)
recipe({ "Lightning", "Rainbow", "Star" }, {
	name = "Poção do Unicórnio Turbo",
	size = "Giant",
	movement = "Speedy",
	visual = "Rainbow",
	valueMultiplier = 3,
})

-- Com Poeira de Cometa (só vem do Cometa) -------------------------------------
recipe(
	{ "Stardust", "Feather" },
	{ name = "Poção do Astronauta Perdido", movement = "Floaty", visual = "Cosmic", valueMultiplier = 3 }
)
recipe({ "Stardust", "Mushroom", "Moon" }, {
	name = "Poção do Planeta Cogumelo",
	size = "Giant",
	movement = "Floaty",
	visual = "Cosmic",
	valueMultiplier = 4,
})

-- Caldeirão da Amizade (4 ingredientes: 2 de cada jogador) -------------------
-- Toda combinação de 4 só existe lá; estas são as especiais escritas à mão.
recipe(
	{ "Honey", "Honey", "Feather", "Feather" },
	{ name = "Poção dos Melhores Amigos", movement = "Fly", visual = "Sparkle", valueMultiplier = 3 }
)
recipe(
	{ "Mushroom", "Mushroom", "Bubble", "Bubble" },
	{ name = "Poção da Lagoa dos Sapos", size = "Giant", form = "Frog", movement = "Bouncy", valueMultiplier = 3 }
)
recipe(
	{ "Pizza", "Pizza", "Pepper", "Honey" },
	{ name = "Poção da Festa do Pijama", form = "Pizza", movement = "Speedy", visual = "Glow", valueMultiplier = 3 }
)
recipe(
	{ "Rainbow", "Star", "Cloud", "Moon" },
	{ name = "Poção do Sonho Compartilhado", movement = "Floaty", visual = "Rainbow", valueMultiplier = 5 }
)

return byKey
