--!strict
--[[
	CometController.luau
	Parte visual do Cometa no cliente:
	- anima a bola de fogo caindo até o horário PP_CometImpactAt;
	- no impacto: explosão de brilho, anel de choque e tremida da câmera.
	(Os ingredientes, o núcleo e as recompensas são do servidor.)
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local SHAKE_DISTANCE = 140
local START_OFFSET = Vector3.new(80, 260, 60)

local CometController = {}

local function shakeCamera(duration: number, strength: number)
	local started = os.clock()
	local name = "PP_CometShake"
	local rng = Random.new()
	RunService:BindToRenderStep(name, Enum.RenderPriority.Camera.Value + 1, function()
		local elapsed = os.clock() - started
		local camera = Workspace.CurrentCamera
		if elapsed >= duration or not camera then
			RunService:UnbindFromRenderStep(name)
			return
		end
		local power = strength * (1 - elapsed / duration)
		camera.CFrame = camera.CFrame * CFrame.new(rng:NextNumber(-power, power), rng:NextNumber(-power, power), 0)
	end)
end

-- TODO(asset): efeito final de impacto (partículas, som).
local function impact(position: Vector3)
	local burst = Instance.new("Part")
	burst.Anchored = true
	burst.CanCollide = false
	burst.CanQuery = false
	burst.CanTouch = false
	burst.Transparency = 1
	burst.Size = Vector3.one
	burst.Position = position + Vector3.new(0, 2, 0)
	burst.Parent = Workspace

	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new(Color3.fromRGB(255, 200, 80), Color3.fromRGB(180, 120, 255))
	emitter.LightEmission = 1
	emitter.Size = NumberSequence.new(1.2, 0)
	emitter.Speed = NumberRange.new(20, 45)
	emitter.Lifetime = NumberRange.new(0.8, 1.4)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Drag = 3
	emitter.Rate = 0
	emitter.Parent = burst
	emitter:Emit(140)

	local ring = Instance.new("Part")
	ring.Shape = Enum.PartType.Cylinder
	ring.Anchored = true
	ring.CanCollide = false
	ring.CanQuery = false
	ring.CanTouch = false
	ring.Material = Enum.Material.Neon
	ring.Color = Color3.fromRGB(255, 220, 140)
	ring.Size = Vector3.new(0.3, 2, 2)
	ring.CFrame = CFrame.new(position + Vector3.new(0, 0.4, 0)) * CFrame.Angles(0, 0, math.rad(90))
	ring.Parent = Workspace
	TweenService:Create(ring, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(0.3, 60, 60),
		Transparency = 1,
	}):Play()

	task.delay(2, function()
		burst:Destroy()
		ring:Destroy()
	end)

	local character = Players.LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") and (root.Position - position).Magnitude < SHAKE_DISTANCE then
		shakeCamera(0.7, 0.8)
	end
end

local function animateFall()
	local position = Workspace:GetAttribute("PP_CometPos")
	local impactAt = Workspace:GetAttribute("PP_CometImpactAt")
	if typeof(position) ~= "Vector3" or type(impactAt) ~= "number" then
		return
	end
	local startAt = Workspace:GetServerTimeNow()
	local total = math.max(0.1, impactAt - startAt)
	local from = position + START_OFFSET

	local ball = Instance.new("Part")
	ball.Shape = Enum.PartType.Ball
	ball.Anchored = true
	ball.CanCollide = false
	ball.CanQuery = false
	ball.CanTouch = false
	ball.Material = Enum.Material.Neon
	ball.Color = Color3.fromRGB(255, 150, 60)
	ball.Size = Vector3.one * 8
	ball.Position = from
	ball.Parent = Workspace
	local fire = Instance.new("Fire")
	fire.Size = 14
	fire.Heat = 20
	fire.Parent = ball
	local light = Instance.new("PointLight")
	light.Range = 40
	light.Brightness = 4
	light.Color = ball.Color
	light.Parent = ball

	local connection: RBXScriptConnection
	connection = RunService.RenderStepped:Connect(function()
		local alpha = math.clamp((Workspace:GetServerTimeNow() - startAt) / total, 0, 1)
		ball.Position = from:Lerp(position, alpha * alpha) -- acelera ao cair
		if alpha >= 1 then
			connection:Disconnect()
			ball:Destroy()
			impact(position)
		end
	end)
end

function CometController.start()
	Workspace:GetAttributeChangedSignal("PP_CometState"):Connect(function()
		if Workspace:GetAttribute("PP_CometState") == "falling" then
			animateFall()
		end
	end)
end

return CometController
