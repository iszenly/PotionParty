--!strict
--[[
	WeatherController.luau
	Mostra o clima do servidor no cliente:
	- muda o céu (Lighting) com uma transição suave;
	- chuva e relâmpagos na Tempestade; luzinhas roxas na Lua Cheia;
	- aviso (banner) quando o clima muda.
	O servidor só diz QUAL é o clima (atributo PP_Weather no Workspace);
	todo o visual é local, o que economiza rede e deixa as animações suaves.
]]

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Weather = require(ReplicatedStorage.Shared.Config.Weather)
local Locale = require(ReplicatedStorage.Shared.Locale)
local Banner = require(script.Parent.Parent.UI.Banner)

local TRANSITION = TweenInfo.new(3, Enum.EasingStyle.Sine)

local WeatherController = {}

local original: { [string]: any } = {} -- valores do Lighting antes de qualquer clima
local rain: ParticleEmitter? = nil
local wisps: ParticleEmitter? = nil
local current: string? = nil

-- TODO(asset): texturas próprias para chuva e luzinhas.
local function buildEffects()
	local part = Instance.new("Part")
	part.Name = "PP_WeatherFollower"
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Transparency = 1
	part.Size = Vector3.new(90, 1, 90)
	part.Parent = Workspace

	local rainEmitter = Instance.new("ParticleEmitter")
	rainEmitter.EmissionDirection = Enum.NormalId.Bottom
	rainEmitter.Orientation = Enum.ParticleOrientation.VelocityParallel
	rainEmitter.Color = ColorSequence.new(Color3.fromRGB(180, 200, 255))
	rainEmitter.Transparency = NumberSequence.new(0.35)
	rainEmitter.Size = NumberSequence.new(0.12)
	rainEmitter.Speed = NumberRange.new(70, 80)
	rainEmitter.Lifetime = NumberRange.new(0.6, 0.8)
	rainEmitter.Rate = 350
	rainEmitter.Enabled = false
	rainEmitter.Parent = part
	rain = rainEmitter

	local wispEmitter = Instance.new("ParticleEmitter")
	wispEmitter.EmissionDirection = Enum.NormalId.Bottom
	wispEmitter.Color = ColorSequence.new(Color3.fromRGB(190, 140, 255))
	wispEmitter.LightEmission = 1
	wispEmitter.Size = NumberSequence.new(0.35)
	wispEmitter.Speed = NumberRange.new(2, 5)
	wispEmitter.Lifetime = NumberRange.new(4, 6)
	wispEmitter.SpreadAngle = Vector2.new(40, 40)
	wispEmitter.Rate = 18
	wispEmitter.Enabled = false
	wispEmitter.Parent = part
	wisps = wispEmitter

	local correction = Instance.new("ColorCorrectionEffect")
	correction.Name = "PP_WeatherFlash"
	correction.Parent = Lighting

	-- A peça acompanha a câmera para a chuva estar sempre "em cima" do jogador.
	RunService.RenderStepped:Connect(function()
		local camera = Workspace.CurrentCamera
		if camera then
			part.CFrame = CFrame.new(camera.CFrame.Position + Vector3.new(0, 25, 0))
		end
	end)

	-- Relâmpagos durante a tempestade.
	task.spawn(function()
		local rng = Random.new()
		while true do
			task.wait(rng:NextNumber(4, 10))
			if current == "Storm" then
				correction.Brightness = 0.6
				TweenService:Create(correction, TweenInfo.new(0.4), { Brightness = 0 }):Play()
			end
		end
	end)
end

local function apply(weatherId: string?, announce: boolean)
	local def = if weatherId then Weather.byId[weatherId] else nil
	local previous = current
	current = if def then def.id else nil

	local target: { [string]: any } = {}
	if def then
		for property, value in def.lighting do
			if original[property] == nil then
				original[property] = (Lighting :: any)[property]
			end
			target[property] = value
		end
	end
	-- Propriedades que o novo clima não usa voltam ao original.
	for property, value in original do
		if target[property] == nil then
			target[property] = value
		end
	end
	TweenService:Create(Lighting, TRANSITION, target):Play()

	if rain then
		rain.Enabled = current == "Storm"
	end
	if wisps then
		wisps.Enabled = current == "FullMoon"
	end

	if not announce then
		return
	end
	if def then
		local name = Locale.name("weather", def.id, def.name)
		local hint = Locale.name("weatherHint", def.id, def.hint)
		Banner.show(`{def.icon} {name}! {hint}`, "weather")
	elseif previous then
		Banner.show(Locale.t("announce.weatherEnd"), "weather")
	end
end

function WeatherController.start()
	buildEffects()
	local function read(): string?
		local value = Workspace:GetAttribute("PP_Weather")
		return if type(value) == "string" then value else nil
	end
	apply(read(), read() ~= nil)
	Workspace:GetAttributeChangedSignal("PP_Weather"):Connect(function()
		apply(read(), true)
	end)
end

return WeatherController
