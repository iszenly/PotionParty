--!strict
--[[
	MonetizationService.luau
	Game Passes e Developer Products (Config/Monetization.luau).

	GAME PASSES: ao entrar, conferimos com o Roblox quais o jogador tem e
	copiamos para data.passes (assim a conta do PlayerStats funciona igual
	no servidor e no cliente). Ao comprar no jogo, liberamos na hora.

	DEVELOPER PRODUCTS (ProcessReceipt) — feito do jeito "à prova de falhas":
	1. Se o jogador não está no servidor ou os dados não carregaram,
	   respondemos NotProcessedYet (o Roblox tenta de novo depois).
	2. Cada compra tem um PurchaseId único. Guardamos os já entregues em
	   data.receipts: se o Roblox mandar o mesmo recibo de novo, NÃO
	   entregamos duas vezes (idempotente).
	3. Só respondemos PurchaseGranted depois que o ProfileStore confirmou o
	   salvamento com o recibo. Se não confirmar a tempo, NotProcessedYet:
	   o Roblox tenta de novo e o passo 2 impede entrega duplicada.

	A compra é aberta pelo cliente (MarketplaceService:Prompt...), mas quem
	entrega é sempre o servidor.
]]

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Types = require(ReplicatedStorage.Shared.Types)
local Monetization = require(ReplicatedStorage.Shared.Config.Monetization)
local Ingredients = require(ReplicatedStorage.Shared.Config.Ingredients)
local Announce = require(script.Parent.Parent.Announce)
local DataService = require(script.Parent.DataService)
local SyncService = require(script.Parent.SyncService)
local IngredientService = require(script.Parent.IngredientService)
local SettingsService = require(script.Parent.SettingsService)

type PlayerData = Types.PlayerData

local MAX_RECEIPTS = 100 -- recibos guardados por jogador
local LOAD_WAIT = 10 -- segundos esperando os dados carregarem
local SAVE_WAIT = 15 -- segundos esperando o salvamento confirmar

local MonetizationService = {}

local function refreshPasses(player: Player, data: PlayerData)
	for _, def in Monetization.passes do
		if def.id ~= 0 then
			local ok, owns = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, def.id)
			if ok then
				(data.passes :: any)[def.key] = if owns then true else nil
			end
		elseif not RunService:IsStudio() then
			-- Pass sem ID configurado não vale em servidor real (no Studio o DEBUG pode ligar).
			(data.passes :: any)[def.key] = nil
		end
	end
	SyncService.push(player)
end

local function grant(player: Player, data: PlayerData, product: Monetization.ProductDef)
	local reward = product.grant
	if reward.ingredients then
		for id, amount in reward.ingredients do
			if Ingredients.byId[id] then
				IngredientService.add(data, id, amount)
			end
		end
	end
	if reward.finishBrews then
		for _, slot in data.cauldrons do
			slot.finishAt = math.min(slot.finishAt, os.time())
		end
	end
	if reward.cosmetic then
		data.cosmetics.owned[reward.cosmetic] = true
		data.cosmetics.trail = reward.cosmetic
		SettingsService.applyTrail(player)
	end
end

-- Mantém só os MAX_RECEIPTS recibos mais recentes.
local function pruneReceipts(data: PlayerData)
	local list: { { id: string, time: number } } = {}
	for id, time in data.receipts do
		table.insert(list, { id = id, time = time })
	end
	if #list <= MAX_RECEIPTS then
		return
	end
	table.sort(list, function(a, b)
		return a.time > b.time
	end)
	for i = MAX_RECEIPTS + 1, #list do
		(data.receipts :: any)[list[i].id] = nil
	end
end

local function waitForProfile(player: Player): any
	local deadline = os.clock() + LOAD_WAIT
	while os.clock() < deadline and player.Parent do
		local profile = DataService.getProfile(player)
		if profile then
			return profile
		end
		task.wait(0.5)
	end
	return nil
end

local function waitForSave(profile: any, purchaseId: string): boolean
	profile:Save()
	local deadline = os.clock() + SAVE_WAIT
	while os.clock() < deadline do
		if not profile:IsActive() then
			return false
		end
		local saved = profile.LastSavedData
		if saved and saved.receipts and saved.receipts[purchaseId] then
			return true
		end
		task.wait(0.5)
	end
	return false
end

local function processReceipt(receipt: { [string]: any }): Enum.ProductPurchaseDecision
	local product = Monetization.productById[receipt.ProductId]
	if not product then
		warn(`[Monetization] produto desconhecido: {receipt.ProductId} (confira os IDs em Monetization.luau)`)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local player = Players:GetPlayerByUserId(receipt.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local profile = waitForProfile(player)
	if not profile then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local data = profile.Data :: PlayerData
	local purchaseId = tostring(receipt.PurchaseId)
	if not data.receipts[purchaseId] then
		grant(player, data, product)
		data.receipts[purchaseId] = os.time()
		pruneReceipts(data)
		SyncService.push(player)
		Announce.player(player, "announce.purchaseThanks", { name = product.name }, "world")
	end

	if waitForSave(profile, purchaseId) then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	return Enum.ProductPurchaseDecision.NotProcessedYet
end

function MonetizationService.init()
	MarketplaceService.ProcessReceipt = processReceipt

	DataService.loaded:Connect(function(player: Player, data: PlayerData)
		refreshPasses(player, data)
	end)

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		local def = Monetization.passById[passId]
		local data = DataService.get(player)
		if purchased and def and data then
			data.passes[def.key] = true
			SyncService.push(player)
			Announce.player(player, "announce.purchaseThanks", { name = def.name }, "world")
		end
	end)
end

return MonetizationService
