--!strict
--[[
	Signal.luau
	Um "evento" simples para módulos conversarem entre si.
		local changed = Signal.new()
		local conn = changed:Connect(function(valor) print(valor) end)
		changed:Fire(42)
		conn:Disconnect()
]]

export type Connection = {
	Disconnect: (self: Connection) -> (),
}

export type Signal = {
	Connect: (self: Signal, handler: (...any) -> ()) -> Connection,
	Fire: (self: Signal, ...any) -> (),
}

local Signal = {}

function Signal.new(): Signal
	local handlers: { [number]: (...any) -> () } = {}
	local nextId = 0

	local signal = {}

	function signal.Connect(_self: Signal, handler: (...any) -> ()): Connection
		nextId += 1
		local id = nextId
		handlers[id] = handler
		local connection = {}
		function connection.Disconnect(_conn: Connection)
			handlers[id] = nil
		end
		return connection :: Connection
	end

	function signal.Fire(_self: Signal, ...: any)
		for _, handler in handlers do
			-- task.spawn: um erro em um ouvinte não quebra os outros
			task.spawn(handler, ...)
		end
	end

	return signal :: Signal
end

return Signal
