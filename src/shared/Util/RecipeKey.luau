--!strict
--[[
	RecipeKey.luau
	A "chave" de uma receita é a lista de ids dos ingredientes, em ordem
	alfabética, unida por "|". Assim a ordem em que o jogador coloca os
	ingredientes não importa:
		{ "Pepper", "Feather", "Cloud" } -> "Cloud|Feather|Pepper"

	A "chave da pilha" (stack key) de uma poção no inventário é a chave da
	receita + a mutação opcional (Fase 2): "Cloud|Feather|Pepper#Golden".
]]

local RecipeKey = {}

local SEPARATOR = "|"
local MUTATION_SEPARATOR = "#"

function RecipeKey.fromIds(ids: { string }): string
	local sorted = table.clone(ids)
	table.sort(sorted)
	return table.concat(sorted, SEPARATOR)
end

function RecipeKey.toIds(key: string): { string }
	return string.split(key, SEPARATOR)
end

-- Monta a chave da pilha a partir da receita e da mutação (opcional).
function RecipeKey.stackKey(recipeKey: string, mutation: string?): string
	if mutation then
		return recipeKey .. MUTATION_SEPARATOR .. mutation
	end
	return recipeKey
end

-- Separa a chave da pilha em (chave da receita, mutação ou nil).
function RecipeKey.splitStack(stackKey: string): (string, string?)
	local parts = string.split(stackKey, MUTATION_SEPARATOR)
	return parts[1], parts[2]
end

-- Quantas receitas diferentes existem com "ingredientCount" ingredientes,
-- usando de 1 até "maxSize" por receita, com repetição permitida.
-- (combinação com repetição: C(n + k - 1, k) para cada tamanho k)
function RecipeKey.totalCombinations(ingredientCount: number, maxSize: number): number
	local total = 0
	for size = 1, maxSize do
		local combos = 1
		for i = 1, size do
			combos = combos * (ingredientCount + i - 1) / i
		end
		total += math.floor(combos + 0.5)
	end
	return total
end

return RecipeKey
