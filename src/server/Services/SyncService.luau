--!strict
--[[
	SyncService.luau
	Envia ao cliente uma "foto" (snapshot) dos seus dados para a interface.

	Sempre que um serviço altera os dados de um jogador, ele chama
	SyncService.push(player). Várias chamadas no mesmo frame viram UM envio só
	(task.defer), para economizar rede.

	O snapshot inclui as informações (nome/efeito/valor) apenas das receitas
	que o jogador já descobriu ou tem no inventário; o resto continua secreto.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Shared.Types)
local RecipeKey = require(ReplicatedStorage.Shared.Util.RecipeKey)
local Net = require(script.Parent.Parent.Net)
local DataService = require(script.Parent.DataService)
local RecipeService = require(script.Parent.RecipeService)

local syncEvent = Net.event("Sync")
local pending: { [Player]: boolean } = {}

local SyncService = {}

-- Outros serviços podem pendurar informações de SESSÃO (não salvas) no snapshot,
-- ex.: pedidos da loja, número de amigos. Assim o SyncService não precisa
-- conhecer esses serviços (evita "require" circular).
local sessionProviders: { [string]: (Player) -> any } = {}

function SyncService.addSessionProvider(name: string, provider: (Player) -> any)
	sessionProviders[name] = provider
end

function SyncService.build(player: Player): Types.Snapshot?
	local data = DataService.get(player)
	if not data then
		return nil
	end

	local recipes: { [string]: Types.RecipeInfo } = {}
	local function include(stackKey: string)
		local recipeKey = RecipeKey.splitStack(stackKey)
		if recipes[recipeKey] == nil then
			local info = RecipeService.resolve(recipeKey)
			if info then
				recipes[recipeKey] = info
			end
		end
	end
	for stackKey, count in data.potions do
		if count > 0 then
			include(stackKey)
		end
	end
	for recipeKey in data.discovered do
		include(recipeKey)
	end

	local session: { [string]: any } = {}
	for name, provider in sessionProviders do
		local ok, value = pcall(provider, player)
		if ok then
			session[name] = value
		else
			warn(`[SyncService] erro no provedor "{name}": {value}`)
		end
	end

	return {
		data = data,
		recipes = recipes,
		serverTime = os.time(),
		session = session :: any,
	}
end

function SyncService.push(player: Player)
	if pending[player] then
		return
	end
	pending[player] = true
	task.defer(function()
		pending[player] = nil
		if player.Parent == nil then
			return
		end
		local snapshot = SyncService.build(player)
		if snapshot then
			syncEvent:FireClient(player, snapshot)
		end
	end)
end

function SyncService.init()
	-- O cliente pede a primeira foto ao entrar (e de novo se perder alguma).
	Net.onInvoke("GetSnapshot", function(player)
		local snapshot = SyncService.build(player)
		if not snapshot then
			return Net.fail("error.notLoaded")
		end
		return Net.ok(snapshot)
	end)

	DataService.loaded:Connect(function(player: Player)
		SyncService.push(player)
	end)
end

return SyncService
