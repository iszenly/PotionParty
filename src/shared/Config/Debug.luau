--!strict
--[[
	Debug.luau
	Ajustes para testar no Studio. NADA aqui vale em servidores reais.

	fastTimersInStudio: encurta os tempos de clima e cometa no Studio
	studioTimeScale:    fator aplicado aos tempos (0.25 = 4x mais rápido)

	PAINEL DEBUG (moedas grátis, passes falsos...): só aparece no Studio E
	numa experiência de TESTE (lista testGameIds) ou num lugar ainda não
	publicado. Assim, abrir a experiência ORIGINAL no Studio com API Services
	ligado não grava dados falsos no DataStore de verdade (correção P17).

	Para descobrir o GameId: View -> Command Bar -> print(game.GameId)
]]

local RunService = game:GetService("RunService")

local isStudio = RunService:IsStudio()

local Debug = {
	fastTimersInStudio = true,
	studioTimeScale = 0.25,

	-- GameId (id da EXPERIÊNCIA, não do lugar) onde o painel DEBUG pode funcionar.
	testGameIds = {
		[10771365236] = true, -- Potion Party [TEST]
	} :: { [number]: boolean },
}

-- Converte um tempo de configuração para o tempo real (encurtado no Studio).
function Debug.time(seconds: number): number
	if isStudio and Debug.fastTimersInStudio then
		return seconds * Debug.studioTimeScale
	end
	return seconds
end

-- O painel DEBUG pode funcionar aqui?
-- GameId 0 = lugar ainda não publicado (não tem DataStore de verdade).
function Debug.enabled(): boolean
	return isStudio and (game.GameId == 0 or Debug.testGameIds[game.GameId] == true)
end

return Debug
