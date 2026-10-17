--!strict
--[[
	Announce.luau (SERVIDOR)
	Mostra um aviso grande (banner) na tela dos jogadores.
	O texto é uma chave do Locale; o cliente traduz e preenche os parâmetros.

		Announce.all("announce.cometIncoming")
		Announce.player(player, "announce.cometReward", { amount = 1, name = "Poeira" })

	style: "info" (padrão), "comet", "world" (efeito especial dourado com confete)
	       "toast"     mensagem pequena embaixo (vermelha se a chave for "error.*", senão verde)
	       "toastInfo" mensagem pequena neutra (avisos que não são erro nem sucesso)
]]

local Net = require(script.Parent.Net)

local event = Net.event("Announce")

local Announce = {}

function Announce.all(key: string, params: { [string]: any }?, style: string?)
	event:FireAllClients({ key = key, params = params, style = style or "info" })
end

function Announce.player(player: Player, key: string, params: { [string]: any }?, style: string?)
	event:FireClient(player, { key = key, params = params, style = style or "info" })
end

return Announce
