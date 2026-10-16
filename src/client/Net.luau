--!strict
--[[
	Net.luau (CLIENTE)
	Chama as RemoteFunctions do servidor.
		local result = Net.request("BuyUpgrade", "BrewSpeed")
		if result.ok then ... end
	Se o servidor recusar, mostra a mensagem de erro traduzida num toast.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Shared.Types)
local Locale = require(ReplicatedStorage.Shared.Locale)
local Toast = require(script.Parent.UI.Toast)

type Result = Types.Result

local remotes = ReplicatedStorage:WaitForChild("Remotes")

local Net = {}

-- Chama sem mostrar erro (para chamadas silenciosas, como GetSnapshot).
function Net.invoke(name: string, ...: any): Result
	local remote = remotes:WaitForChild(name, 10)
	if not remote or not remote:IsA("RemoteFunction") then
		return { ok = false, err = "error.generic" }
	end
	local success, result = pcall(remote.InvokeServer, remote, ...)
	if not success or type(result) ~= "table" then
		return { ok = false, err = "error.generic" }
	end
	return result :: Result
end

-- Chama e mostra um toast de erro se falhar.
function Net.request(name: string, ...: any): Result
	local result = Net.invoke(name, ...)
	if not result.ok then
		Toast.show(Locale.t(result.err or "error.generic"), "bad")
	end
	return result
end

-- Ouve um RemoteEvent do servidor.
function Net.on(name: string, handler: (...any) -> ())
	local remote = remotes:WaitForChild(name)
	assert(remote:IsA("RemoteEvent"), `{name} não é um RemoteEvent`)
	remote.OnClientEvent:Connect(handler)
end

return Net
