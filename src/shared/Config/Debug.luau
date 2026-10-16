--!strict
--[[
	Debug.luau
	Ajustes para testar no Studio. NADA aqui vale em servidores reais.

	fastTimersInStudio: encurta os tempos de clima e cometa no Studio
	studioTimeScale:    fator aplicado aos tempos (0.25 = 4x mais rápido)
	No Studio também aparece um painel "DEBUG" com atalhos (clima, cometa, moedas).
]]

local RunService = game:GetService("RunService")

local isStudio = RunService:IsStudio()

local Debug = {
	fastTimersInStudio = true,
	studioTimeScale = 0.25,
}

-- Converte um tempo de configuração para o tempo real (encurtado no Studio).
function Debug.time(seconds: number): number
	if isStudio and Debug.fastTimersInStudio then
		return seconds * Debug.studioTimeScale
	end
	return seconds
end

function Debug.enabled(): boolean
	return isStudio
end

return Debug
