--!strict
--[[
	Weather.luau
	Clima do servidor. O WeatherService alterna:
		céu limpo (tempo sorteado entre clearMin e clearMax)
		-> um evento sorteado pelo "weight" (dura "duration")
		-> céu limpo -> ...
	Durante um evento, poções coletadas podem ganhar a mutação ligada a ele
	(veja Mutations.luau, campo "weather").

	"lighting" muda o visual do céu no cliente (propriedades do serviço Lighting).
]]

local Types = require(script.Parent.Parent.Types)

local events: { Types.WeatherDef } = {
	{
		id = "Storm",
		name = "Tempestade",
		icon = "⛈️",
		duration = 150,
		weight = 1,
		hint = "Poções coletadas agora podem sair Eletrificadas!",
		lighting = {
			ClockTime = 17.6,
			Brightness = 0.7,
			Ambient = Color3.fromRGB(60, 60, 85),
			OutdoorAmbient = Color3.fromRGB(70, 70, 95),
			FogColor = Color3.fromRGB(60, 62, 78),
			FogEnd = 350,
		},
	},
	{
		id = "FullMoon",
		name = "Lua Cheia",
		icon = "🌕",
		duration = 150,
		weight = 1,
		hint = "Poções coletadas agora podem sair Assombradas!",
		lighting = {
			ClockTime = 0,
			Brightness = 1.2,
			Ambient = Color3.fromRGB(95, 65, 140),
			OutdoorAmbient = Color3.fromRGB(110, 80, 165),
			FogColor = Color3.fromRGB(60, 40, 95),
			FogEnd = 600,
		},
	},
}

local byId: { [string]: Types.WeatherDef } = {}
for _, def in events do
	byId[def.id] = def
end

return {
	events = events,
	byId = byId,
	clearMin = 180, -- segundos de céu limpo entre eventos
	clearMax = 300,
}
