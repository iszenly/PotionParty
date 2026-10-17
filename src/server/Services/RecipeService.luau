--!strict
--[[
	RecipeService.luau
	Transforma uma chave de receita ("Cloud|Feather|Pepper") em uma poção:
	nome, efeito, valor e cor.

	DETERMINÍSTICO: a mesma chave SEMPRE gera a mesma poção, em qualquer
	servidor. Para isso, o "acaso" (desempates e escolha de nomes) usa um
	Random com semente = hash da chave, nunca math.random.

	Como o efeito procedural é montado:
	1. soma os pesos dos "traits" de todos os ingredientes;
	2. para cada categoria (size, form, movement, visual), o traço de maior
	   peso vence, se o peso for >= Economy.traitThreshold;
	3. se nenhuma categoria passou do limite, o traço mais forte entra mesmo assim;
	4. receitas fixas (Config/Recipes.luau) substituem tudo isso.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Shared.Types)
local Economy = require(ReplicatedStorage.Shared.Config.Economy)
local Ingredients = require(ReplicatedStorage.Shared.Config.Ingredients)
local Rarities = require(ReplicatedStorage.Shared.Config.Rarities)
local Traits = require(ReplicatedStorage.Shared.Config.Traits)
local RecipeKey = require(ReplicatedStorage.Shared.Util.RecipeKey)
local Hash = require(ReplicatedStorage.Shared.Util.Hash)
local FixedRecipes = require(script.Parent.Parent.Config.Recipes)
local NameParts = require(script.Parent.Parent.Config.NameParts)

type RecipeInfo = Types.RecipeInfo
type PotionEffect = Types.PotionEffect

local RecipeService = {}

-- Cache: cada receita VÁLIDA é calculada uma vez por servidor.
-- (O número de receitas válidas é limitado; chaves inválidas nunca entram aqui.)
local cache: { [string]: RecipeInfo } = {}

-- Confere se a chave é válida e está no formato canônico (ordenada).
local function parseKey(key: string): { string }?
	if #key > 120 then
		return nil
	end
	local ids = RecipeKey.toIds(key)
	-- Até 3 no caldeirão normal; até 4 no Caldeirão da Amizade (receitas exclusivas).
	if #ids < 1 or #ids > math.max(Economy.maxIngredientsPerBrew, Economy.maxFriendshipIngredients) then
		return nil
	end
	for _, id in ids do
		if not Ingredients.byId[id] then
			return nil
		end
	end
	if RecipeKey.fromIds(ids) ~= key then
		return nil
	end
	return ids
end

local function pickFrom(list: { string }, rng: Random): string
	return list[rng:NextInteger(1, #list)]
end

-- Escolhe o traço vencedor de uma categoria. Empates são decididos pelo rng.
local function strongestTrait(weights: { [string]: number }, category: string, rng: Random): (string?, number)
	local bestWeight = 0
	local tied: { string } = {}
	for _, trait in Traits.list do
		if trait.category == category then
			local weight = weights[trait.id] or 0
			if weight > bestWeight then
				bestWeight = weight
				tied = { trait.id }
			elseif weight > 0 and weight == bestWeight then
				table.insert(tied, trait.id)
			end
		end
	end
	if bestWeight == 0 then
		return nil, 0
	end
	return pickFrom(tied, rng), bestWeight
end

local function generateName(effect: PotionEffect, rng: Random): string
	local prefix = pickFrom(NameParts.prefixes, rng)

	local subjectTrait = effect.form or effect.size
	local subjects = subjectTrait and NameParts.subjectsByTrait[subjectTrait] or NameParts.defaultSubjects
	local subject = pickFrom(subjects, rng)

	local complementTrait = effect.movement or effect.visual
	local complements = complementTrait and NameParts.complementsByTrait[complementTrait]
		or NameParts.defaultComplements
	local complement = pickFrom(complements, rng)

	return `{prefix} {subject} {complement}`
end

local function compute(key: string): RecipeInfo?
	local ids = parseKey(key)
	if not ids then
		return nil
	end

	local rng = Random.new(Hash.fnv1a(key))
	local weights: { [string]: number } = {}
	local baseValue = 0
	local duration = Economy.effectBaseDuration
	local r, g, b = 0, 0, 0

	for _, id in ids do
		local def = Ingredients.byId[id]
		for traitId, weight in def.traits do
			weights[traitId] = (weights[traitId] or 0) + weight
		end
		baseValue += def.sellValue
		duration += (Rarities[def.rarity].order - 1) * Economy.effectDurationPerRarity
		r += def.color.R
		g += def.color.G
		b += def.color.B
	end

	-- Monta o efeito categoria por categoria.
	local picked: { [string]: string } = {}
	local strongestId: string? = nil
	local strongestWeight = 0
	for _, category in Traits.categories do
		local traitId, weight = strongestTrait(weights, category, rng)
		if traitId then
			if weight >= Economy.traitThreshold then
				picked[category] = traitId
			end
			if weight > strongestWeight then
				strongestId, strongestWeight = traitId, weight
			end
		end
	end
	if next(picked) == nil and strongestId then
		picked[Traits.byId[strongestId].category] = strongestId
	end

	local effect: PotionEffect = {
		size = picked.size,
		form = picked.form,
		movement = picked.movement,
		visual = picked.visual,
		duration = duration,
	}

	local count = #ids
	local value = baseValue * (Economy.comboMultiplier[count] or 1)
	local name: string
	local fixed = FixedRecipes[key]

	if fixed then
		effect = {
			size = fixed.size,
			form = fixed.form,
			movement = fixed.movement,
			visual = fixed.visual,
			duration = fixed.duration or duration,
		}
		name = fixed.name
		value *= fixed.valueMultiplier or Economy.specialRecipeMultiplier
	else
		name = generateName(effect, rng)
	end

	return {
		key = key,
		name = name,
		ingredients = ids,
		effect = effect,
		value = math.floor(value + 0.5),
		color = Color3.new(r / count, g / count, b / count),
		isSpecial = fixed ~= nil,
	}
end

-- Retorna as informações da receita, ou nil se a chave for inválida.
function RecipeService.resolve(key: string): RecipeInfo?
	local cached = cache[key]
	if cached then
		return cached
	end
	local info = compute(key)
	-- Só guarda receitas válidas: chaves inválidas não ocupam memória (correção P8).
	-- Recalcular uma chave inválida é barato (para logo na validação).
	if info then
		cache[key] = info
	end
	return info
end

return RecipeService
