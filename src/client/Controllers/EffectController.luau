--!strict
--[[
	EffectController.luau
	Partes dos efeitos que precisam rodar no cliente:
	- Voo: com o atributo PP_Fly no personagem, segurar pulo faz subir.
	  (O servidor já colocou a força antigravidade; aqui só damos o impulso.
	  O personagem é fisicamente controlado pelo próprio cliente no Roblox.)
	- Arco-íris: anima a cor dos Highlights com a tag "PP_Rainbow" localmente,
	  para não gastar rede mandando cor do servidor a cada frame.
]]

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Economy = require(ReplicatedStorage.Shared.Config.Economy)
local Net = require(script.Parent.Parent.Net)

local EffectController = {}

local flashFrame: Frame? = nil

-- Tela colorida que pisca (só para quem se transformou).
local function screenFlash(color: Color3)
	local frame = flashFrame
	if not frame then
		return
	end
	frame.BackgroundColor3 = color
	frame.BackgroundTransparency = 0.3
	TweenService:Create(frame, TweenInfo.new(0.5), { BackgroundTransparency = 1 }):Play()
end

-- "Empurrãozinho" na câmera (campo de visão abre e volta).
local function fovPunch()
	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end
	local base = camera.FieldOfView
	local tween = TweenService:Create(
		camera,
		TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true),
		{ FieldOfView = base + 12 }
	)
	tween:Play()
	tween.Completed:Connect(function()
		camera.FieldOfView = base
	end)
end

--[[
	Animação de transformação: uma bolha brilhante que estoura + estrelinhas.
	Roda em TODOS os clientes (o servidor manda o evento "Transformed").
	TODO(asset): som de transformação e partículas com textura própria.
]]
local function puff(character: Model, color: Color3)
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return
	end
	local bubble = Instance.new("Part")
	bubble.Shape = Enum.PartType.Ball
	bubble.Anchored = true
	bubble.CanCollide = false
	bubble.CanQuery = false
	bubble.CanTouch = false
	bubble.Material = Enum.Material.Neon
	bubble.Color = color
	bubble.Transparency = 0.25
	bubble.Size = Vector3.one * 2
	bubble.Position = root.Position
	bubble.Parent = Workspace

	local stars = Instance.new("ParticleEmitter")
	stars.Color = ColorSequence.new(color, Color3.new(1, 1, 1))
	stars.LightEmission = 1
	stars.Size = NumberSequence.new(0.6, 0)
	stars.Speed = NumberRange.new(8, 16)
	stars.Lifetime = NumberRange.new(0.5, 0.9)
	stars.SpreadAngle = Vector2.new(180, 180)
	stars.Drag = 4
	stars.Rate = 0
	stars.Parent = bubble
	stars:Emit(40)

	TweenService:Create(bubble, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.one * 10,
		Transparency = 1,
	}):Play()
	task.delay(1.5, function()
		bubble:Destroy()
	end)

	if character == Players.LocalPlayer.Character then
		screenFlash(color)
		fovPunch()
	end
end

function EffectController.start()
	local player = Players.LocalPlayer

	local flashGui = Instance.new("ScreenGui")
	flashGui.Name = "PotionPartyFlash"
	flashGui.IgnoreGuiInset = true
	flashGui.ResetOnSpawn = false
	flashGui.DisplayOrder = 5
	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel = 0
	frame.Active = false
	frame.Parent = flashGui
	flashGui.Parent = player:WaitForChild("PlayerGui")
	flashFrame = frame

	Net.on("Transformed", function(character: any, color: any)
		if typeof(character) == "Instance" and character:IsA("Model") and typeof(color) == "Color3" then
			puff(character, color)
		end
	end)

	-- JumpRequest dispara quando o jogador aperta/segura pulo (teclado, toque ou controle).
	UserInputService.JumpRequest:Connect(function()
		local character = player.Character
		if not character or character:GetAttribute("PP_Fly") ~= true then
			return
		end
		local root = character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			local velocity = root.AssemblyLinearVelocity
			root.AssemblyLinearVelocity = Vector3.new(velocity.X, Economy.flyUpSpeed, velocity.Z)
		end
	end)

	RunService.RenderStepped:Connect(function()
		local hue = (os.clock() * 0.35) % 1
		for _, instance in CollectionService:GetTagged("PP_Rainbow") do
			if instance:IsA("Highlight") then
				instance.FillColor = Color3.fromHSV(hue, 0.8, 1)
				instance.OutlineColor = Color3.fromHSV((hue + 0.5) % 1, 0.8, 1)
			end
		end
	end)
end

return EffectController
