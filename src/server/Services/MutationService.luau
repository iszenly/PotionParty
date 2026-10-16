--!strict
--[[
	MutationService.luau
	Sorteia a mutação de uma poção ao ser coletada (veja Config/Mutations.luau).
	Aqui usamos um Random "de verdade" (não determinístico): a receita é sempre
	a mesma, mas a sorte da mutação muda a cada preparo.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Mutations = require(ReplicatedStorage.Shared.Config.Mutations)

local rng = Random.new()

local MutationService = {}

-- Debug (Studio): força a mutação da próxima poção coletada.
local forcedNext: string? = nil

function MutationService.forceNext(mutationId: string?)
	forcedNext = if mutationId and Mutations.byId[mutationId] then mutationId else nil
end

-- weatherId: clima atual (nil = céu limpo). luck: 1 = normal, 2 = dobro de chance.
function MutationService.roll(weatherId: string?, luck: number): string?
	if forcedNext then
		local forced = forcedNext
		forcedNext = nil
		return forced
	end
	-- A lista já vem ordenada da mais rara para a mais comum.
	for _, def in Mutations.list do
		if def.weather == nil or def.weather == weatherId then
			if rng:NextNumber() < def.chance * luck then
				return def.id
			end
		end
	end
	return nil
end

return MutationService
