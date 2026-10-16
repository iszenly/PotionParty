--!strict
--[[
	WeatherService.luau
	Alterna o clima do servidor: céu limpo -> evento -> céu limpo...

	O estado fica em atributos do Workspace (assim quem entra depois já sabe
	o clima atual):
		PP_Weather        id do evento ("Storm", "FullMoon") ou nil = céu limpo
		PP_WeatherEndsAt  os.time() de quando o evento acaba
	O cliente (WeatherController) muda o céu e mostra o aviso.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Types = require(ReplicatedStorage.Shared.Types)
local Weather = require(ReplicatedStorage.Shared.Config.Weather)
local Debug = require(ReplicatedStorage.Shared.Config.Debug)

local rng = Random.new()
local current: string? = nil
local nextChangeAt = 0 -- os.clock() da próxima troca

local WeatherService = {}

-- Clima atual (nil = céu limpo). Usado pelo sorteio de mutações.
function WeatherService.current(): string?
	return current
end

local function startClear()
	current = nil
	Workspace:SetAttribute("PP_Weather", nil)
	Workspace:SetAttribute("PP_WeatherEndsAt", nil)
	nextChangeAt = os.clock() + Debug.time(rng:NextNumber(Weather.clearMin, Weather.clearMax))
end

local function startEvent(def: Types.WeatherDef)
	local duration = Debug.time(def.duration)
	current = def.id
	Workspace:SetAttribute("PP_Weather", def.id)
	Workspace:SetAttribute("PP_WeatherEndsAt", os.time() + duration)
	nextChangeAt = os.clock() + duration
end

-- Sorteia um evento levando em conta o "weight" de cada um.
local function pickEvent(): Types.WeatherDef?
	local total = 0
	for _, def in Weather.events do
		total += def.weight
	end
	if total <= 0 then
		return nil
	end
	local roll = rng:NextNumber(0, total)
	for _, def in Weather.events do
		roll -= def.weight
		if roll <= 0 then
			return def
		end
	end
	return Weather.events[#Weather.events]
end

-- Força um clima (usado pelo painel de debug). nil = céu limpo.
function WeatherService.force(weatherId: string?)
	local def = if weatherId then Weather.byId[weatherId] else nil
	if def then
		startEvent(def)
	else
		startClear()
	end
end

function WeatherService.init()
	startClear()
	task.spawn(function()
		while true do
			task.wait(1)
			if os.clock() >= nextChangeAt then
				local event = if current == nil then pickEvent() else nil
				if event then
					startEvent(event)
				else
					startClear()
				end
			end
		end
	end)
end

return WeatherService
