--!strict
--[[
	State.luau (CLIENTE)
	Guarda a última "foto" (snapshot) dos dados que o servidor mandou.
	As telas leem State.snapshot e redesenham quando State.changed dispara.
	O cliente NUNCA altera estes dados: só pede ao servidor via Net.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Types = require(ReplicatedStorage.Shared.Types)
local Signal = require(ReplicatedStorage.Shared.Util.Signal)
local Net = require(script.Parent.Net)

local State = {
	snapshot = nil :: Types.Snapshot?,
	changed = Signal.new(),
}

-- Horário do servidor (Unix, em segundos). Use para os timers do caldeirão.
function State.serverNow(): number
	return Workspace:GetServerTimeNow()
end

local function set(snapshot: Types.Snapshot)
	State.snapshot = snapshot
	State.changed:Fire(snapshot)
end

function State.start()
	Net.on("Sync", function(snapshot: Types.Snapshot)
		set(snapshot)
	end)

	-- Pede a primeira foto; os dados podem demorar alguns segundos para carregar.
	task.spawn(function()
		while State.snapshot == nil do
			local result = Net.invoke("GetSnapshot")
			if result.ok and State.snapshot == nil then
				set(result.data :: Types.Snapshot)
				break
			end
			task.wait(1)
		end
	end)
end

return State
