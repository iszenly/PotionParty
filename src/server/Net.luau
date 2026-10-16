--!strict
--[[
	Net.luau (SERVIDOR)
	Cria os RemoteEvents/RemoteFunctions em ReplicatedStorage.Remotes e envolve
	cada handler com:
		1. rate limit (Config/Remotes.luau);
		2. pcall, para um erro no handler não travar o cliente;
		3. resposta padrão { ok, err, data }.

	Cada handler ainda é responsável por validar os próprios argumentos
	(tipo, valor, distância) usando Util/Validate e MapService.isNear.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Shared.Types)
local RemoteLimits = require(ReplicatedStorage.Shared.Config.Remotes)
local RateLimiter = require(script.Parent.Util.RateLimiter)

type Result = Types.Result

local folder = Instance.new("Folder")
folder.Name = "Remotes"
folder.Parent = ReplicatedStorage

local Net = {}

function Net.ok(data: any?): Result
	return { ok = true, data = data }
end

function Net.fail(err: string): Result
	return { ok = false, err = err }
end

-- Registra uma RemoteFunction (o cliente pede, o servidor responde).
function Net.onInvoke(name: string, handler: (player: Player, ...any) -> Result)
	assert(folder:FindFirstChild(name) == nil, `Remote duplicado: {name}`)
	local remote = Instance.new("RemoteFunction")
	remote.Name = name
	local limit = RemoteLimits[name] or RemoteLimits.default

	remote.OnServerInvoke = function(player: Player, ...: any): Result
		if not RateLimiter.allow(player, name, limit.rate, limit.burst) then
			return Net.fail("error.rateLimited")
		end
		local success, result = pcall(handler, player, ...)
		if not success then
			warn(`[Net] erro em {name} ({player.Name}): {result}`)
			return Net.fail("error.generic")
		end
		return result
	end

	remote.Parent = folder
end

-- Cria um RemoteEvent (o servidor avisa o cliente).
function Net.event(name: string): RemoteEvent
	assert(folder:FindFirstChild(name) == nil, `Remote duplicado: {name}`)
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = folder
	return remote
end

return Net
