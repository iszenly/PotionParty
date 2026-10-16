--!strict
--[[
	Daily.luau
	Recompensa diária com sequência (streak). Entrar em dias seguidos avança
	o dia da sequência; pular um dia volta para o dia 1. Depois do último dia,
	o ciclo recomeça (mas o contador de dias seguidos continua subindo).
]]

export type DailyReward = {
	coins: number,
	ingredients: { [string]: number }?,
}

local rewards: { DailyReward } = {
	{ coins = 100 },
	{ coins = 150 },
	{ coins = 200, ingredients = { Lightning = 2, Cloud = 2 } },
	{ coins = 300 },
	{ coins = 400, ingredients = { Moon = 1, Lava = 1 } },
	{ coins = 500 },
	{ coins = 1000, ingredients = { Star = 1, Ghost = 1 } },
}

return {
	rewards = rewards,
}
