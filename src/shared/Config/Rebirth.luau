--!strict
--[[
	Rebirth.luau
	"Novo Mestre": o jogador troca suas moedas e melhorias por um
	multiplicador PERMANENTE de moedas. Receitas, Grimório, poções e
	ingredientes são mantidos.

	Custo do próximo = floor(baseCost * costGrowth ^ rebirthsFeitos)
	Multiplicador     = 1 + multiplierPerRebirth * rebirthsFeitos
]]

local Rebirth = {
	baseCost = 25000,
	costGrowth = 3,
	multiplierPerRebirth = 0.5,
}

function Rebirth.cost(rebirths: number): number
	return math.floor(Rebirth.baseCost * Rebirth.costGrowth ^ rebirths)
end

function Rebirth.multiplier(rebirths: number): number
	return 1 + Rebirth.multiplierPerRebirth * rebirths
end

return Rebirth
