--!strict
--[[
	SplashController.luau
	- throw(stackKey): mira automática no jogador mais próximo dentro do
	  alcance (fácil no celular). Sem ninguém por perto, o frasco cai à frente.
	- Desenha o frasco voando em arco e o "splash" (só visual; quem decide
	  quem foi atingido é o servidor).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Social = require(ReplicatedStorage.Shared.Config.Social)
local Locale = require(ReplicatedStorage.Shared.Locale)
local Net = require(script.Parent.Parent.Net)
local Toast = require(script.Parent.Parent.UI.Toast)

local ARC_HEIGHT = 8

local SplashController = {}

local function rootOf(player: Player): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

local function nearestTarget(): Player?
	local myRoot = rootOf(Players.LocalPlayer)
	if not myRoot then
		return nil
	end
	local best: Player? = nil
	local bestDistance = Social.splashRange
	for _, other in Players:GetPlayers() do
		local root = if other ~= Players.LocalPlayer then rootOf(other) else nil
		if root then
			local distance = (root.Position - myRoot.Position).Magnitude
			if distance <= bestDistance then
				best, bestDistance = other, distance
			end
		end
	end
	return best
end

function SplashController.throw(stackKey: string): boolean
	local target = nearestTarget()
	local result = Net.request("ThrowPotion", stackKey, if target then target.UserId else nil)
	if result.ok then
		Toast.show(Locale.t("ui.thrown"), "good")
	end
	return result.ok
end

-- TODO(asset): modelo de frasco e som de vidro/splash.
local function splashBurst(position: Vector3, color: Color3)
	local anchor = Instance.new("Part")
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Transparency = 1
	anchor.Size = Vector3.one
	anchor.Position = position
	anchor.Parent = Workspace
	local drops = Instance.new("ParticleEmitter")
	drops.Color = ColorSequence.new(color)
	drops.LightEmission = 0.5
	drops.Size = NumberSequence.new(0.6, 0)
	drops.Speed = NumberRange.new(10, 20)
	drops.Lifetime = NumberRange.new(0.4, 0.8)
	drops.SpreadAngle = Vector2.new(180, 180)
	drops.Acceleration = Vector3.new(0, -30, 0)
	drops.Rate = 0
	drops.Parent = anchor
	drops:Emit(45)

	local ring = Instance.new("Part")
	ring.Shape = Enum.PartType.Cylinder
	ring.Anchored = true
	ring.CanCollide = false
	ring.CanQuery = false
	ring.CanTouch = false
	ring.Material = Enum.Material.Neon
	ring.Color = color
	ring.Size = Vector3.new(0.2, 1, 1)
	ring.CFrame = CFrame.new(position - Vector3.new(0, 2, 0)) * CFrame.Angles(0, 0, math.rad(90))
	ring.Parent = Workspace
	local size = Social.splashRadius * 2
	TweenService:Create(ring, TweenInfo.new(0.4), { Size = Vector3.new(0.2, size, size), Transparency = 1 }):Play()
	task.delay(1.2, function()
		anchor:Destroy()
		ring:Destroy()
	end)
end

local function animate(from: Vector3, to: Vector3, color: Color3, travelTime: number)
	local flask = Instance.new("Part")
	flask.Shape = Enum.PartType.Ball
	flask.Anchored = true
	flask.CanCollide = false
	flask.CanQuery = false
	flask.CanTouch = false
	flask.Material = Enum.Material.Neon
	flask.Color = color
	flask.Size = Vector3.one * 1.2
	flask.Position = from
	flask.Parent = Workspace

	local started = os.clock()
	local connection: RBXScriptConnection
	connection = RunService.RenderStepped:Connect(function()
		local alpha = math.clamp((os.clock() - started) / travelTime, 0, 1)
		-- Arco: sobe e desce (parábola) enquanto anda em linha reta.
		flask.Position = from:Lerp(to, alpha) + Vector3.new(0, ARC_HEIGHT * 4 * alpha * (1 - alpha), 0)
		if alpha >= 1 then
			connection:Disconnect()
			flask:Destroy()
			splashBurst(to, color)
		end
	end)
end

function SplashController.start()
	Net.on("Splash", function(from: any, to: any, color: any, travelTime: any)
		if typeof(from) == "Vector3" and typeof(to) == "Vector3" and typeof(color) == "Color3" then
			animate(from, to, color, if type(travelTime) == "number" then travelTime else 0.6)
		end
	end)
end

return SplashController
