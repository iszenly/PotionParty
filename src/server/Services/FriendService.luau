--!strict
--[[
	FriendService.luau
	Conta quantos AMIGOS do Roblox cada jogador tem no mesmo servidor e dá
	+10% de moedas por amigo (até o máximo de Config/Social.luau).

	Player:IsFriendsWith faz uma chamada à web (pode demorar ou falhar), então
	guardamos o resultado de cada par de jogadores em cache.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Social = require(ReplicatedStorage.Shared.Config.Social)
local SyncService = require(script.Parent.SyncService)

local counts: { [Player]: number } = {}
local cache: { [string]: boolean } = {}

local FriendService = {}

local function pairKey(a: Player, b: Player): string
	local low, high = math.min(a.UserId, b.UserId), math.max(a.UserId, b.UserId)
	return `{low}:{high}`
end

-- Os dois são amigos no Roblox? (pode esperar uma chamada à web)
function FriendService.areFriends(a: Player, b: Player): boolean
	if a == b then
		return false
	end
	local key = pairKey(a, b)
	local cached = cache[key]
	if cached ~= nil then
		return cached
	end
	local ok, result = pcall(a.IsFriendsWithAsync, a, b.UserId)
	local friends = ok and result == true
	if ok then
		cache[key] = friends
	end
	return friends
end

local function recount(player: Player)
	if player.Parent == nil then
		return
	end
	local total = 0
	for _, other in Players:GetPlayers() do
		if other ~= player and FriendService.areFriends(player, other) then
			total += 1
		end
	end
	counts[player] = total
	player:SetAttribute("PP_Friends", total)
	SyncService.push(player)
end

local function recountAll()
	for _, player in Players:GetPlayers() do
		task.spawn(recount, player)
	end
end

-- Multiplicador de moedas pelo bônus de amigos (1 = sem bônus).
function FriendService.coinMultiplier(player: Player): number
	local friends = counts[player] or 0
	return 1 + math.min(Social.friendBonusMax, friends * Social.friendBonusPerFriend)
end

function FriendService.init()
	SyncService.addSessionProvider("friends", function(player)
		return counts[player] or 0
	end)
	Players.PlayerAdded:Connect(function()
		task.spawn(recountAll)
	end)
	Players.PlayerRemoving:Connect(function(player)
		counts[player] = nil
		local prefix, suffix = `{player.UserId}:`, `:{player.UserId}`
		for key in cache do
			if string.sub(key, 1, #prefix) == prefix or string.sub(key, -#suffix) == suffix then
				cache[key] = nil
			end
		end
		task.defer(recountAll)
	end)
	recountAll()
end

return FriendService
