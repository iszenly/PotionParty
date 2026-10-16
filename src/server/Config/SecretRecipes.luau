--!strict
--[[
	SecretRecipes.luau (SERVIDOR)
	Receitas secretas da semana. Toda segunda-feira (00:00 UTC) o jogo sorteia
	"perWeek" receitas desta lista. Os jogadores veem só a DICA no Grimório.
	Quem criar uma delas durante a semana ganha "rewardCoins" (uma vez por
	receita por semana).

	O sorteio usa o número da semana como semente: todos os servidores escolhem
	as mesmas receitas. Pode usar qualquer combinação (fixa ou procedural).
]]

export type Secret = { ingredients: { string }, hint: string }

local pool: { Secret } = {
	{ ingredients = { "Ice", "Lava" }, hint = "Quente e gelado na mesma panela…" },
	{ ingredients = { "Honey", "Bubble", "Feather" }, hint = "Uma abelha tomando banho de espuma." },
	{ ingredients = { "Pepper", "Pepper", "Pepper" }, hint = "Três vezes mais ardido!" },
	{ ingredients = { "Stone", "Cloud" }, hint = "O mais pesado com o mais leve." },
	{ ingredients = { "Mushroom", "Moon" }, hint = "Um cogumelo que só cresce à noite." },
	{ ingredients = { "Magnet", "Lightning" }, hint = "Atração elétrica!" },
	{ ingredients = { "Pizza", "Ghost" }, hint = "Uma pizza que ninguém consegue morder…" },
	{ ingredients = { "Star", "Stardust" }, hint = "Duas coisas que caem do céu." },
	{ ingredients = { "Feather", "Feather" }, hint = "Leve como duas… penas?" },
	{ ingredients = { "Ice", "Ice", "Ice" }, hint = "Mais gelado, impossível." },
	{ ingredients = { "Honey", "Pizza" }, hint = "Sobremesa ou jantar? Os dois!" },
	{ ingredients = { "Mushroom", "Feather", "Stone" }, hint = "Cresce, voa e pesa ao mesmo tempo." },
}

return {
	perWeek = 3,
	rewardCoins = 400,
	pool = pool,
}
