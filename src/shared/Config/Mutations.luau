--!strict
--[[
	Mutations.luau
	Mutações: variações raras que aparecem ao COLETAR uma poção do caldeirão.
	Uma poção tem no máximo 1 mutação. O sorteio testa da mais rara para a
	mais comum e para na primeira que acertar.

	chance            0.01 = 1%  (multiplicada pela "sorte" do jogador, ex.: Sorte VIP)
	priceMultiplier   multiplica o preço de venda (e, na Fase 3, o valor de troca)
	weather           só acontece durante este clima (veja Weather.luau)
	durationMultiplier / fixedDuration   mudam a duração do efeito ao beber
	overlay           traço extra (Config/Traits.luau) aplicado junto com o efeito

	Os ids ficam salvos nos dados dos jogadores: não renomeie depois de lançar.
]]

local Types = require(script.Parent.Parent.Types)

local list: { Types.MutationDef } = {
	{
		id = "Rainbow",
		name = "Arco-íris",
		chance = 0.001,
		priceMultiplier = 20,
		color = Color3.fromRGB(255, 120, 220),
		overlay = "Rainbow",
		durationMultiplier = 2,
	},
	{
		id = "Eternal",
		name = "Eterna",
		chance = 0.004,
		priceMultiplier = 6,
		color = Color3.fromRGB(120, 255, 230),
		fixedDuration = 900, -- 15 minutos (ou até beber outra / renascer)
	},
	{
		id = "Golden",
		name = "Dourada",
		chance = 0.01,
		priceMultiplier = 5,
		color = Color3.fromRGB(255, 200, 40),
		overlay = "GoldAura",
	},
	{
		id = "Double",
		name = "Dupla",
		chance = 0.03,
		priceMultiplier = 2,
		color = Color3.fromRGB(120, 200, 255),
		durationMultiplier = 2,
	},
	-- Mutações de clima
	{
		id = "Electrified",
		name = "Eletrificada",
		chance = 0.25,
		priceMultiplier = 2.5,
		color = Color3.fromRGB(255, 240, 80),
		weather = "Storm",
		overlay = "Electric",
	},
	{
		id = "Haunted",
		name = "Assombrada",
		chance = 0.25,
		priceMultiplier = 3,
		color = Color3.fromRGB(170, 120, 255),
		weather = "FullMoon",
		overlay = "Ghost",
	},
}

-- Ordena da mais rara para a mais comum (é a ordem do sorteio).
table.sort(list, function(a, b)
	return a.chance < b.chance
end)

local byId: { [string]: Types.MutationDef } = {}
for _, def in list do
	byId[def.id] = def
end

local Mutations = {
	list = list,
	byId = byId,
}

-- Multiplicador de preço de uma mutação (1 se não houver).
function Mutations.priceMultiplier(mutationId: string?): number
	local def = if mutationId then byId[mutationId] else nil
	return if def then def.priceMultiplier else 1
end

-- Duração final do efeito com a mutação aplicada.
function Mutations.duration(mutationId: string?, baseDuration: number): number
	local def = if mutationId then byId[mutationId] else nil
	if not def then
		return baseDuration
	end
	if def.fixedDuration then
		return def.fixedDuration
	end
	return baseDuration * (def.durationMultiplier or 1)
end

return Mutations
