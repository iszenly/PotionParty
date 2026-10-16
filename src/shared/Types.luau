--!strict
--[[
	Types.luau
	Tipos compartilhados entre servidor e cliente.

	Em Luau, "export type" cria um tipo que outros módulos podem usar com:
		local Types = require(ReplicatedStorage.Shared.Types)
		local data: Types.PlayerData = ...
	Tipos não existem em tempo de execução; servem só para o editor apontar erros.
]]

-- Raridades possíveis de um ingrediente.
export type Rarity = "Common" | "Uncommon" | "Rare" | "Epic" | "Legendary"

-- As 4 "partes" que compõem o efeito de uma poção.
export type TraitCategory = "size" | "form" | "movement" | "visual"

-- Tipos de efeito visual que o EffectService sabe aplicar.
export type VisualKind = "Light" | "Fire" | "Sparkles" | "Particles" | "Rainbow" | "Highlight"

export type RarityDef = {
	order: number, -- 1 = mais comum
	name: string, -- nome em português (tradução em Locale/en)
	color: Color3,
	brewSeconds: number, -- segundos extras de preparo por ingrediente desta raridade
}

export type IngredientDef = {
	id: string, -- identificador em inglês, usado no código e nos dados salvos (NUNCA mude depois de lançar)
	name: string, -- nome em português
	rarity: Rarity,
	color: Color3,
	price: number, -- preço de compra no mercado
	sellValue: number, -- quanto este ingrediente vale dentro de uma poção
	unlockPrice: number, -- 0 = já começa liberado
	traits: { [string]: number }, -- atributos: id do traço -> peso
	cometOnly: boolean?, -- true = não é vendido no mercado; só vem do Cometa
}

export type TraitDef = {
	id: string,
	category: TraitCategory,
	name: string,
	-- size
	scale: number?,
	-- form
	color: Color3?,
	material: Enum.Material?,
	transparency: number?,
	prop: string?, -- peça decorativa placeholder ("FrogEyes", "CloudPuffs")
	-- movement
	speedMult: number?,
	jumpMult: number?,
	antiGravity: number?, -- 0..1: fração da gravidade cancelada
	canFly: boolean?, -- libera o controle de subir segurando pulo
	-- visual
	visualKind: VisualKind?,
	visualColor: Color3?,
}

export type UpgradeDef = {
	id: string,
	name: string,
	description: string,
	maxLevel: number,
	valuePerLevel: number,
	baseCost: number,
	costGrowth: number,
	costs: { number }?, -- se existir, usa estes preços fixos em vez da fórmula
}

export type MutationDef = {
	id: string,
	name: string, -- "Dourada", "Eletrificada"...
	chance: number, -- 0.01 = 1%
	priceMultiplier: number,
	color: Color3, -- cor do selo na interface
	weather: string?, -- só pode acontecer durante este clima
	durationMultiplier: number?, -- multiplica a duração do efeito
	fixedDuration: number?, -- substitui a duração do efeito (segundos)
	overlay: string?, -- traço extra aplicado por cima do efeito normal
}

export type WeatherDef = {
	id: string,
	name: string,
	icon: string,
	duration: number, -- segundos
	weight: number, -- chance relativa de ser sorteado
	hint: string, -- frase do anúncio
	lighting: { [string]: any }, -- propriedades do Lighting durante o evento (aplicadas no cliente)
}

-- Uma poção tem no máximo um traço por categoria.
export type PotionEffect = {
	size: string?,
	form: string?,
	movement: string?,
	visual: string?,
	duration: number,
}

-- Informações de uma receita já resolvida pelo servidor.
export type RecipeInfo = {
	key: string,
	name: string,
	ingredients: { string },
	effect: PotionEffect,
	value: number,
	color: Color3,
	isSpecial: boolean,
}

export type CauldronSlot = {
	key: string, -- chave da receita sendo preparada
	startedAt: number, -- os.time() do início
	finishAt: number, -- os.time() de quando fica pronta
}

-- Uma receita no Grimório do jogador.
export type DiscoveryEntry = {
	t: number, -- os.time() da primeira vez que o jogador criou
	by: string?, -- nome do descobridor MUNDIAL; nil = ainda não registrado
	byId: number?, -- UserId do descobridor mundial
	first: boolean?, -- true = este jogador foi o primeiro do mundo
}

-- Tudo o que é salvo do jogador. Só pode conter números, strings, booleanos e tabelas.
export type PlayerData = {
	version: number,
	coins: number,
	ingredients: { [string]: number },
	unlocked: { [string]: boolean },
	potions: { [string]: number }, -- chave da pilha -> quantidade
	upgrades: { [string]: number },
	cauldrons: { [string]: CauldronSlot }, -- "1", "2"... (chaves texto para o DataStore aceitar buracos)
	discovered: { [string]: DiscoveryEntry }, -- chave da receita -> registro do Grimório
	worldFirsts: number, -- quantas receitas este jogador descobriu primeiro no mundo
	weekly: { week: number, claimed: { [string]: boolean } }, -- secretas da semana já premiadas
	streak: { count: number, lastClaimDay: number },
	missions: { day: number, list: { MissionState } },
	rebirths: number,
	lastLogout: number,
	settings: { shield: boolean },
	stats: { brewed: number, sold: number, drunk: number, coinsEarned: number },
	shop: { likes: number, visits: number, served: number },
	likesGiven: { day: number, users: { [string]: boolean } }, -- lojas curtidas hoje
	passes: { [string]: boolean }, -- Game Passes (cópia; a verdade é o Roblox, conferida ao entrar)
	receipts: { [string]: number }, -- compras já entregues (PurchaseId -> os.time)
	cosmetics: { owned: { [string]: boolean }, trail: string? },
}

-- Uma missão diária.
export type MissionState = {
	id: string, -- tipo da missão (Config/Missions.luau)
	target: number,
	progress: number,
	reward: number,
	claimed: boolean,
}

-- Pedido de um cliente NPC na loja do jogador.
export type Order = {
	id: string,
	customerName: string,
	kind: "recipe" | "effect",
	recipeKey: string?, -- pedido por tipo: a receita exata
	recipeName: string?,
	traits: { string }?, -- pedido por efeito: todos estes traços
	multiplier: number, -- multiplica o preço da poção entregue
	special: boolean,
	expiresAt: number, -- os.time()
}

-- Estado da sessão (não é salvo): vem junto do snapshot.
export type SessionInfo = {
	orders: { Order }?,
	plot: number?,
	friends: number?,
}

-- O que o servidor envia para o cliente desenhar a interface.
export type Snapshot = {
	data: PlayerData,
	recipes: { [string]: RecipeInfo },
	serverTime: number,
	session: SessionInfo,
}

-- Oferta de um lado da troca.
export type TradeOffer = {
	potions: { [string]: number },
	ingredients: { [string]: number },
}

-- O que cada jogador vê da troca.
export type TradeView = {
	partnerName: string,
	mine: TradeOffer,
	theirs: TradeOffer,
	myReady: boolean,
	theirReady: boolean,
	myConfirmed: boolean,
	theirConfirmed: boolean,
	confirmAt: number?, -- horário do servidor a partir do qual pode confirmar
	myValue: number,
	theirValue: number,
	recipes: { [string]: RecipeInfo }, -- nomes das poções oferecidas pelos dois
}

-- Resposta padrão de toda RemoteFunction.
export type Result = {
	ok: boolean,
	err: string?, -- chave de texto do Locale (ex.: "error.notEnoughCoins")
	data: any?,
}

-- Dica de receita secreta da semana (a receita em si NÃO vai para o cliente).
export type WeeklySecret = {
	hint: string,
	reward: number,
	found: boolean,
}

export type GrimoireInfo = {
	secrets: { WeeklySecret },
	weekEndsAt: number,
	totalCombinations: number,
}

export type RankingEntry = {
	rank: number,
	name: string,
	value: number,
}

return {}
