--!strict
--[[
	FriendshipService.luau
	Caldeirão da Amizade: só funciona com DOIS jogadores, um em cada lado (A e B).
	Cada um escolhe 2 ingredientes; quando os dois marcam "Pronto", o caldeirão
	mistura os 4 e OS DOIS ganham a poção. Receitas de 4 ingredientes só
	existem aqui (são "exclusivas da amizade").
	Se os dois forem amigos no Roblox, a sorte de mutação aumenta.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Types = require(ReplicatedStorage.Shared.Types)
local Social = require(ReplicatedStorage.Shared.Config.Social)
local RecipeKey = require(ReplicatedStorage.Shared.Util.RecipeKey)
local PlayerStats = require(ReplicatedStorage.Shared.Util.PlayerStats)
local Net = require(script.Parent.Parent.Net)
local Announce = require(script.Parent.Parent.Announce)
local Validate = require(script.Parent.Parent.Util.Validate)
local DataService = require(script.Parent.DataService)
local SyncService = require(script.Parent.SyncService)
local RecipeService = require(script.Parent.RecipeService)
local IngredientService = require(script.Parent.IngredientService)
local MutationService = require(script.Parent.MutationService)
local WeatherService = require(script.Parent.WeatherService)
local DiscoveryService = require(script.Parent.DiscoveryService)
local MissionService = require(script.Parent.MissionService)
local FriendService = require(script.Parent.FriendService)
local MapService = require(script.Parent.MapService)

local FRIEND_LUCK_BONUS = 1.5

local event = Net.event("Friendship")
local sides: { [string]: Player } = {} -- "A"/"B" -> jogador
local picks: { [Player]: { string } } = {}
local ready: { [Player]: boolean } = {}
local brewing = false

local FriendshipService = {}

local function sideOf(player: Player): string?
	for side, occupant in sides do
		if occupant == player then
			return side
		end
	end
	return nil
end

local function otherOf(player: Player): Player?
	for _, occupant in sides do
		if occupant ~= player then
			return occupant
		end
	end
	return nil
end

local function sendState()
	for _, player in sides do
		local other = otherOf(player)
		event:FireClient(player, {
			kind = "state",
			mySide = sideOf(player),
			partnerName = if other then other.DisplayName else nil,
			myPicks = picks[player] or {},
			theirPicks = if other then picks[other] or {} else {},
			myReady = ready[player] == true,
			theirReady = if other then ready[other] == true else false,
		})
	end
end

local function leave(player: Player, notify: boolean)
	local side = sideOf(player)
	if not side then
		return
	end
	sides[side] = nil
	picks[player] = nil
	ready[player] = nil
	for _, occupant in sides do
		ready[occupant] = false
	end
	if notify and player.Parent then
		event:FireClient(player, { kind = "closed" })
	end
	sendState()
end

local function isNearCauldron(player: Player): boolean
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return root ~= nil
		and root:IsA("BasePart")
		and (root.Position - MapService.friendshipCenter).Magnitude <= Social.friendshipRadius
end

local function resetReady()
	for _, occupant in sides do
		ready[occupant] = false
	end
end

local function brew()
	local a, b = sides.A, sides.B
	if not a or not b or brewing then
		return
	end

	-- 1) Checar amizade pode esperar uma chamada à web (só na 1ª vez de cada par;
	--    depois fica em cache). Fazemos isso ANTES de gastar qualquer ingrediente.
	brewing = true
	local friends = FriendService.areFriends(a, b)
	brewing = false

	-- 2) Durante a espera alguém pode ter saído, trocado a escolha ou desmarcado
	--    "Pronto". Se algo mudou, não prepara.
	if sides.A ~= a or sides.B ~= b or not ready[a] or not ready[b] then
		sendState()
		return
	end
	local dataA, dataB = DataService.get(a), DataService.get(b)
	local picksA, picksB = picks[a], picks[b]
	if not dataA or not dataB or not picksA or not picksB then
		return
	end
	local ids = table.clone(picksA)
	for _, id in picksB do
		table.insert(ids, id)
	end
	local recipeKey = RecipeKey.fromIds(ids)
	local info = RecipeService.resolve(recipeKey)
	if not info then
		resetReady()
		sendState()
		return
	end

	-- 3) Confere tudo de novo antes de gastar qualquer coisa.
	local function canBrew(player: Player, data: Types.PlayerData, playerPicks: { string }): boolean
		if not IngredientService.hasAll(data, playerPicks) then
			Announce.player(player, "error.notEnoughIngredients", nil, "toast")
			return false
		end
		if PlayerStats.potionCount(data) >= PlayerStats.potionCapacity(data) then
			Announce.player(player, "error.inventoryFull", nil, "toast")
			return false
		end
		return true
	end
	if not canBrew(a, dataA, picksA) or not canBrew(b, dataB, picksB) then
		resetReady()
		sendState()
		return
	end

	-- 4) Daqui até o fim não há nenhuma pausa: gasta e entrega tudo de uma vez.
	IngredientService.consume(dataA, picksA)
	IngredientService.consume(dataB, picksB)

	for _, player in { a, b } do
		local data = if player == a then dataA else dataB
		local luck = PlayerStats.luck(data) * (if friends then FRIEND_LUCK_BONUS else 1)
		local mutation = MutationService.roll(WeatherService.current(), luck)
		local stackKey = RecipeKey.stackKey(recipeKey, mutation)
		data.potions[stackKey] = (data.potions[stackKey] or 0) + 1
		data.stats.brewed += 1
		local isNew = data.discovered[recipeKey] == nil
		if isNew then
			data.discovered[recipeKey] = { t = os.time() }
			DiscoveryService.register(player, recipeKey, info.name)
			DiscoveryService.markRankingDirty(player)
			MissionService.progress(player, "discover", 1)
		end
		MissionService.progress(player, "brew", 1)
		SyncService.push(player)
		event:FireClient(player, {
			kind = "result",
			recipe = info,
			stackKey = stackKey,
			isNew = isNew,
			mutation = mutation,
		})
	end

	picks[a], picks[b] = {}, {}
	resetReady()
	sendState()
end

function FriendshipService.init()
	local function connectPad(prompt: Instance)
		if not prompt:IsA("ProximityPrompt") then
			return
		end
		prompt.Triggered:Connect(function(player)
			local side = prompt:GetAttribute("Side")
			if type(side) ~= "string" or sideOf(player) or not DataService.get(player) then
				return
			end
			if sides[side] then
				Announce.player(player, "announce.sideTaken", nil, "toastInfo")
				return
			end
			sides[side] = player
			picks[player] = {}
			ready[player] = false
			sendState()
		end)
	end
	for _, prompt in CollectionService:GetTagged("PP_FriendshipPad") do
		connectPad(prompt)
	end
	CollectionService:GetInstanceAddedSignal("PP_FriendshipPad"):Connect(connectPad)

	Net.onInvoke("FriendshipPick", function(player, ingredientIds: any)
		local data = DataService.get(player)
		if not data or not sideOf(player) then
			return Net.fail("error.invalid")
		end
		local ids = Validate.ingredientList(ingredientIds, Social.friendshipIngredientsPerPlayer)
		if not ids or #ids ~= Social.friendshipIngredientsPerPlayer then
			return Net.fail("error.invalid")
		end
		if not IngredientService.hasAll(data, ids) then
			return Net.fail("error.notEnoughIngredients")
		end
		picks[player] = ids
		resetReady() -- a mistura mudou: os dois conferem de novo
		sendState()
		return Net.ok()
	end)

	Net.onInvoke("FriendshipReady", function(player, value: any)
		local current = picks[player]
		if not sideOf(player) or not current then
			return Net.fail("error.invalid")
		end
		if value == true and #current ~= Social.friendshipIngredientsPerPlayer then
			return Net.fail("error.pickIngredients")
		end
		ready[player] = value == true
		local other = otherOf(player)
		if ready[player] and other and ready[other] then
			brew()
		else
			sendState()
		end
		return Net.ok()
	end)

	Net.onInvoke("FriendshipLeave", function(player)
		leave(player, true)
		return Net.ok()
	end)

	Players.PlayerRemoving:Connect(function(player)
		leave(player, false)
	end)

	-- Quem se afastar do caldeirão sai do lado.
	task.spawn(function()
		while true do
			task.wait(1)
			for _, occupant in sides do
				if not isNearCauldron(occupant) then
					leave(occupant, true)
				end
			end
		end
	end)
end

return FriendshipService
