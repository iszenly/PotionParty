--!strict
--[[
	TradeService.luau
	Troca SEGURA entre dois jogadores (poções e ingredientes; moedas não).

	Passo a passo:
	1. A convida B (TradeRequest). B aceita ou recusa (TradeRespond).
	2. Cada um monta sua oferta (TradeSetOffer). As DUAS ofertas aparecem
	   para os dois o tempo todo.
	3. Os dois marcam "Pronto" (TradeSetReady). Qualquer mudança de oferta
	   desmarca o "Pronto" dos dois.
	4. Depois de alguns segundos com os dois prontos, os dois CONFIRMAM
	   (TradeConfirm). Só então o servidor troca os itens.

	Segurança:
	- tudo é conferido de novo no momento da troca (o jogador ainda tem os
	  itens? cabe na prateleira?);
	- se algum item oferecido sumir (vendeu, bebeu...), a troca é cancelada;
	- se alguém sair do jogo, a troca é cancelada;
	- a troca acontece toda de uma vez, sem esperas no meio, e salvamos os
	  dois perfis logo depois.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Types = require(ReplicatedStorage.Shared.Types)
local Social = require(ReplicatedStorage.Shared.Config.Social)
local Ingredients = require(ReplicatedStorage.Shared.Config.Ingredients)
local Mutations = require(ReplicatedStorage.Shared.Config.Mutations)
local RecipeKey = require(ReplicatedStorage.Shared.Util.RecipeKey)
local PlayerStats = require(ReplicatedStorage.Shared.Util.PlayerStats)
local Net = require(script.Parent.Parent.Net)
local Validate = require(script.Parent.Parent.Util.Validate)
local DataService = require(script.Parent.DataService)
local SyncService = require(script.Parent.SyncService)
local RecipeService = require(script.Parent.RecipeService)

type Offer = Types.TradeOffer
type PlayerData = Types.PlayerData

type Trade = {
	a: Player,
	b: Player,
	offers: { [Player]: Offer },
	ready: { [Player]: boolean },
	confirmed: { [Player]: boolean },
	readyAt: number?, -- os.clock() de quando os dois ficaram prontos
	done: boolean,
}

local tradeEvent = Net.event("Trade")
local trades: { [Player]: Trade } = {}
local requests: { [Player]: { from: Player, at: number } } = {} -- convite pendente, por destinatário

local TradeService = {}

local function emptyOffer(): Offer
	return { potions = {}, ingredients = {} }
end

local function partnerOf(trade: Trade, player: Player): Player
	return if trade.a == player then trade.b else trade.a
end

-- Valor estimado de uma oferta (preço base x mutação; ajuda a ver se é justa).
local function offerValue(offer: Offer): number
	local total = 0
	for stackKey, count in offer.potions do
		local recipeKey, mutationId = RecipeKey.splitStack(stackKey)
		local info = RecipeService.resolve(recipeKey)
		if info then
			total += info.value * Mutations.priceMultiplier(mutationId) * count
		end
	end
	for id, count in offer.ingredients do
		local def = Ingredients.byId[id]
		if def then
			total += def.sellValue * count
		end
	end
	return math.floor(total)
end

local function owns(data: PlayerData, offer: Offer): boolean
	for stackKey, count in offer.potions do
		if (data.potions[stackKey] or 0) < count then
			return false
		end
	end
	for id, count in offer.ingredients do
		if (data.ingredients[id] or 0) < count then
			return false
		end
	end
	return true
end

local function potionTotal(offer: Offer): number
	local total = 0
	for _, count in offer.potions do
		total += count
	end
	return total
end

-- Confere a oferta que veio do cliente e devolve uma cópia limpa (ou nil).
local function cleanOffer(raw: any): Offer?
	if type(raw) ~= "table" or type(raw.potions) ~= "table" or type(raw.ingredients) ~= "table" then
		return nil
	end
	local offer = emptyOffer()
	local stacks = 0
	for key, count in raw.potions do
		stacks += 1
		if stacks > Social.tradeMaxStacks or not Validate.text(key, 160) or not Validate.integer(count, 1, 9999) then
			return nil
		end
		local recipeKey = RecipeKey.splitStack(key)
		if not RecipeService.resolve(recipeKey) then
			return nil
		end
		offer.potions[key] = count
	end
	for id, count in raw.ingredients do
		stacks += 1
		if stacks > Social.tradeMaxStacks or not Validate.ingredientId(id) or not Validate.integer(count, 1, 9999) then
			return nil
		end
		offer.ingredients[id] = count
	end
	return offer
end

local function view(trade: Trade, player: Player): Types.TradeView
	local partner = partnerOf(trade, player)
	local mine, theirs = trade.offers[player], trade.offers[partner]
	local recipes: { [string]: Types.RecipeInfo } = {}
	for _, offer in { mine, theirs } do
		for stackKey in offer.potions do
			local recipeKey = RecipeKey.splitStack(stackKey)
			local info = RecipeService.resolve(recipeKey)
			if info then
				recipes[recipeKey] = info
			end
		end
	end
	local confirmAt: number? = nil
	if trade.readyAt then
		confirmAt = Workspace:GetServerTimeNow() + math.max(0, Social.tradeConfirmDelay - (os.clock() - trade.readyAt))
	end
	return {
		partnerName = partner.DisplayName,
		mine = mine,
		theirs = theirs,
		myReady = trade.ready[player] == true,
		theirReady = trade.ready[partner] == true,
		myConfirmed = trade.confirmed[player] == true,
		theirConfirmed = trade.confirmed[partner] == true,
		confirmAt = confirmAt,
		myValue = offerValue(mine),
		theirValue = offerValue(theirs),
		recipes = recipes,
	}
end

local function sendState(trade: Trade)
	for _, player in { trade.a, trade.b } do
		tradeEvent:FireClient(player, { kind = "state", view = view(trade, player) })
	end
end

local function close(trade: Trade, reason: string)
	if trade.done then
		return
	end
	trade.done = true
	trades[trade.a] = nil
	trades[trade.b] = nil
	for _, player in { trade.a, trade.b } do
		if player.Parent then
			tradeEvent:FireClient(player, { kind = "closed", reason = reason })
		end
	end
end

local function resetReady(trade: Trade)
	table.clear(trade.ready)
	table.clear(trade.confirmed)
	trade.readyAt = nil
end

-- Move os itens de "from" para "to" (já conferidos antes).
local function move(from: PlayerData, to: PlayerData, offer: Offer)
	for stackKey, count in offer.potions do
		local left = from.potions[stackKey] - count
		if left <= 0 then
			(from.potions :: any)[stackKey] = nil
		else
			from.potions[stackKey] = left
		end
		to.potions[stackKey] = (to.potions[stackKey] or 0) + count
	end
	for id, count in offer.ingredients do
		from.ingredients[id] -= count
		to.ingredients[id] = (to.ingredients[id] or 0) + count
	end
end

local function execute(trade: Trade)
	local dataA, dataB = DataService.get(trade.a), DataService.get(trade.b)
	if not dataA or not dataB then
		close(trade, "error.tradeFailed")
		return
	end
	local offerA, offerB = trade.offers[trade.a], trade.offers[trade.b]
	if not owns(dataA, offerA) or not owns(dataB, offerB) then
		close(trade, "error.tradeChanged")
		return
	end
	local function fits(data: PlayerData, giving: Offer, receiving: Offer): boolean
		return PlayerStats.potionCount(data) - potionTotal(giving) + potionTotal(receiving)
			<= PlayerStats.potionCapacity(data)
	end
	if not fits(dataA, offerA, offerB) or not fits(dataB, offerB, offerA) then
		close(trade, "error.tradeCapacity")
		return
	end

	-- Daqui até o fim não há nenhuma espera: a troca é "atômica" neste servidor.
	move(dataA, dataB, offerA)
	move(dataB, dataA, offerB)
	trade.done = true
	trades[trade.a] = nil
	trades[trade.b] = nil

	DataService.save(trade.a)
	DataService.save(trade.b)
	for _, player in { trade.a, trade.b } do
		SyncService.push(player)
		tradeEvent:FireClient(player, { kind = "completed" })
	end
end

function TradeService.init()
	Net.onInvoke("TradeRequest", function(player, targetUserId: any)
		if not Validate.integer(targetUserId, 1, 2 ^ 52) then
			return Net.fail("error.invalid")
		end
		local target = Players:GetPlayerByUserId(targetUserId)
		if not target or target == player then
			return Net.fail("error.invalid")
		end
		if trades[player] or trades[target] then
			return Net.fail("error.tradeBusy")
		end
		if not DataService.get(player) or not DataService.get(target) then
			return Net.fail("error.notLoaded")
		end
		requests[target] = { from = player, at = os.clock() }
		tradeEvent:FireClient(target, { kind = "request", fromName = player.DisplayName, fromUserId = player.UserId })
		return Net.ok()
	end)

	Net.onInvoke("TradeRespond", function(player, fromUserId: any, accept: any)
		local request = requests[player]
		if not request or request.from.UserId ~= fromUserId or os.clock() - request.at > Social.tradeRequestTimeout then
			return Net.fail("error.tradeExpired")
		end
		requests[player] = nil
		local from = request.from
		if accept ~= true then
			if from.Parent then
				tradeEvent:FireClient(from, { kind = "declined", name = player.DisplayName })
			end
			return Net.ok()
		end
		if from.Parent == nil or trades[player] or trades[from] then
			return Net.fail("error.tradeBusy")
		end
		local trade: Trade = {
			a = from,
			b = player,
			offers = { [from] = emptyOffer(), [player] = emptyOffer() },
			ready = {},
			confirmed = {},
			readyAt = nil,
			done = false,
		}
		trades[from] = trade
		trades[player] = trade
		sendState(trade)
		return Net.ok()
	end)

	Net.onInvoke("TradeSetOffer", function(player, rawOffer: any)
		local trade = trades[player]
		local data = DataService.get(player)
		if not trade or not data then
			return Net.fail("error.noTrade")
		end
		local offer = cleanOffer(rawOffer)
		if not offer then
			return Net.fail("error.invalid")
		end
		if not owns(data, offer) then
			return Net.fail("error.tradeNotOwned")
		end
		trade.offers[player] = offer
		resetReady(trade) -- mudou a oferta: os dois precisam conferir de novo
		sendState(trade)
		return Net.ok()
	end)

	Net.onInvoke("TradeSetReady", function(player, value: any)
		local trade = trades[player]
		if not trade then
			return Net.fail("error.noTrade")
		end
		trade.ready[player] = value == true
		table.clear(trade.confirmed)
		local partner = partnerOf(trade, player)
		trade.readyAt = if trade.ready[player] and trade.ready[partner] then os.clock() else nil
		sendState(trade)
		return Net.ok()
	end)

	Net.onInvoke("TradeConfirm", function(player)
		local trade = trades[player]
		if not trade then
			return Net.fail("error.noTrade")
		end
		local partner = partnerOf(trade, player)
		local readyAt = trade.readyAt
		if not (trade.ready[player] and trade.ready[partner]) or not readyAt then
			return Net.fail("error.tradeNotReady")
		end
		if os.clock() - readyAt < Social.tradeConfirmDelay then
			return Net.fail("error.tradeWait")
		end
		trade.confirmed[player] = true
		if trade.confirmed[partner] then
			execute(trade)
		else
			sendState(trade)
		end
		return Net.ok()
	end)

	Net.onInvoke("TradeCancel", function(player)
		local trade = trades[player]
		if trade then
			close(trade, "error.tradeCancelled")
		end
		return Net.ok()
	end)

	Players.PlayerRemoving:Connect(function(player)
		local trade = trades[player]
		if trade then
			close(trade, "error.tradeLeft")
		end
		requests[player] = nil
		for target, request in requests do
			if request.from == player then
				requests[target] = nil
			end
		end
	end)

	-- Se algum item oferecido sumir do inventário, cancela ("se algo mudar").
	task.spawn(function()
		while true do
			task.wait(1)
			local checked: { [Trade]: boolean } = {}
			for _, trade in trades do
				if not checked[trade] then
					checked[trade] = true
					local dataA, dataB = DataService.get(trade.a), DataService.get(trade.b)
					if
						not dataA
						or not dataB
						or not owns(dataA, trade.offers[trade.a])
						or not owns(dataB, trade.offers[trade.b])
					then
						close(trade, "error.tradeChanged")
					end
				end
			end
		end
	end)
end

return TradeService
