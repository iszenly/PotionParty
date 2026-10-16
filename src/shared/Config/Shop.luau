--!strict
--[[
	Shop.luau
	A loja de cada jogador (tycoon): clientes NPC que fazem pedidos.

	Pedidos:
	- por TIPO ("quero a Poção do Galo Foguete"): uma receita que o jogador já
	  descobriu. Paga o preço da poção x recipeOrderMultiplier.
	- por EFEITO ("quero voar"): qualquer poção com aquele traço.
	  Paga x effectOrderMultiplier.
	- ESPECIAL ("quero voar e brilhar"): dois traços ao mesmo tempo.
	  Paga x specialOrderMultiplier.
]]

return {
	plotCount = 6, -- deixe o tamanho do servidor (Game Settings) igual a este número

	baseCustomers = 2, -- clientes ao mesmo tempo (+ Prateleiras Extras + Game Pass Loja Maior)
	bigShopExtraCustomers = 2,
	customerInterval = 20, -- segundos entre a chegada de clientes
	customerPatience = 120, -- segundos que o cliente espera

	recipeOrderMultiplier = 1.5,
	effectOrderMultiplier = 1.3,
	specialOrderMultiplier = 2.5,
	baseSpecialChance = 0.15, -- + Vitrine Mágica por nível
	recipeOrderChance = 0.45, -- chance de o pedido ser por tipo (se já houver receitas descobertas)

	counterRadius = 22, -- distância do balcão para entregar pedidos

	-- Venda automática OFFLINE (calculada quando o jogador volta)
	offlineSaleInterval = 300, -- 1 poção a cada 5 minutos fora do jogo
	offlineMaxSeconds = 4 * 3600, -- conta no máximo 4 horas
	offlineMaxSales = 20, -- no máximo 20 poções
	offlinePriceMultiplier = 0.6, -- vende mais barato que ao vivo
	offlineCoinCap = 5000, -- teto de moedas por volta
	autoSellOfflineMultiplier = 2, -- Game Pass Auto-venda dobra os tetos

	-- Traços usados em pedidos quando o jogador ainda não descobriu nada
	starterTraits = { "Giant", "Mini", "Fly", "Glow", "Speedy" },

	customerNames = {
		"Dona Cotinha",
		"Seu Juca",
		"Mago Bolinha",
		"Bruxa Lili",
		"Pirata Zé",
		"Princesa Nina",
		"Robô B-12",
		"Vovó Fada",
		"Cavaleiro Tito",
		"Duende Pipo",
		"Astronauta Lu",
		"Chef Tonico",
	},
}
