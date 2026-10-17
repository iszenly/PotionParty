--!strict
--[[
	Social.luau
	Números dos sistemas sociais: bônus de amigos, respingo, troca,
	Caldeirão da Amizade e curtidas.
]]

return {
	-- Bônus de moedas por amigo do Roblox no mesmo servidor
	friendBonusPerFriend = 0.10, -- +10% por amigo
	friendBonusMax = 0.50, -- no máximo +50%

	-- Respingo (arremessar poção)
	splashRange = 40, -- alcance máximo em studs
	splashRadius = 7, -- raio do respingo no impacto
	splashDuration = 8, -- segundos que o alvo fica transformado
	splashCooldown = 2, -- segundos entre arremessos do mesmo jogador
	splashTravelTime = 0.6, -- tempo de voo do frasco
	splashImmunity = 10, -- segundos imune a novos respingos depois de ser atingido

	-- Troca
	-- Interruptor geral: false desliga as trocas para todos (o botão "Trocar" some).
	-- Mudar este valor exige publicar o jogo de novo (servidores novos usam o valor novo).
	-- Antes de liberar trocas ao público, reavaliar o risco P1 (veja README, "Riscos conhecidos").
	tradingEnabled = true,
	tradeMaxStacks = 6, -- tipos diferentes de item por lado
	tradeRequestTimeout = 20, -- segundos para aceitar um convite
	tradeConfirmDelay = 3, -- segundos de espera depois que os dois ficam "prontos" (evita golpe de troca rápida)

	-- Caldeirão da Amizade
	friendshipIngredientsPerPlayer = 2,
	friendshipRadius = 14, -- distância máxima do caldeirão para continuar participando
}
