--!strict
--[[
	Banner.luau
	Avisos grandes no topo da tela (clima, cometa, descobertas mundiais).
	Os avisos entram numa fila e aparecem um de cada vez.

	Estilos:
		"info"    roxo claro
		"weather" azul
		"comet"   roxo
		"world"   dourado + confete + flash (Descoberta Mundial / segredo da semana)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Locale = require(ReplicatedStorage.Shared.Locale)
local UI = require(script.Parent.Components)
local Theme = require(script.Parent.Theme)
local Toast = require(script.Parent.Toast)
local Net = require(script.Parent.Parent.Net)

local MAX_QUEUE = 5
local SHOW_SECONDS = 3.5
local WORLD_SHOW_SECONDS = 5

local STYLE_COLORS: { [string]: Color3 } = {
	info = Theme.colors.panelLight,
	weather = Color3.fromRGB(60, 110, 190),
	comet = Color3.fromRGB(140, 80, 210),
	world = Theme.colors.gold,
}

type Item = { text: string, style: string }

local screen: ScreenGui
local container: Frame
local queue: { Item } = {}
local showing = false

local Banner = {}

local function flash(color: Color3)
	local frame: Frame = UI.new("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = color,
		BackgroundTransparency = 0.35,
		ZIndex = 50,
		Parent = screen,
	})
	local tween = TweenService:Create(frame, TweenInfo.new(0.6), { BackgroundTransparency = 1 })
	tween:Play()
	tween.Completed:Connect(function()
		frame:Destroy()
	end)
end

-- Confete caindo (só interface, nada no mundo 3D).
local function confetti()
	local colors = {
		Color3.fromRGB(255, 90, 90),
		Color3.fromRGB(255, 210, 60),
		Color3.fromRGB(90, 200, 255),
		Color3.fromRGB(140, 255, 120),
		Color3.fromRGB(220, 120, 255),
	}
	local rng = Random.new()
	for _ = 1, 40 do
		local piece: Frame = UI.new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(rng:NextNumber(0.05, 0.95), 0, 0, -20),
			Size = UDim2.fromOffset(rng:NextInteger(8, 14), rng:NextInteger(12, 20)),
			BackgroundColor3 = colors[rng:NextInteger(1, #colors)],
			Rotation = rng:NextNumber(0, 360),
			ZIndex = 60,
			Parent = screen,
		})
		local duration = rng:NextNumber(1.8, 3)
		local tween =
			TweenService:Create(piece, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				Position = UDim2.fromScale(piece.Position.X.Scale + rng:NextNumber(-0.1, 0.1), 1.1),
				Rotation = piece.Rotation + rng:NextNumber(-540, 540),
			})
		tween:Play()
		tween.Completed:Connect(function()
			piece:Destroy()
		end)
	end
end

local function display(item: Item)
	local isWorld = item.style == "world"
	local label = UI.label({
		Text = item.text,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, -90),
		Size = UDim2.new(1, 0, 0, 60),
		BackgroundColor3 = STYLE_COLORS[item.style] or STYLE_COLORS.info,
		BackgroundTransparency = 0.05,
		TextColor3 = if isWorld then Theme.colors.stroke else Theme.colors.text,
		MaxTextSize = 26,
		ZIndex = 40,
		Parent = container,
	})
	UI.corner(label, 16)
	UI.stroke(label, Theme.colors.stroke, 3)
	UI.padding(label, 8)

	if isWorld then
		flash(Theme.colors.gold)
		confetti()
	end

	TweenService:Create(label, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.fromScale(0.5, 0),
	}):Play()
	task.wait(if isWorld then WORLD_SHOW_SECONDS else SHOW_SECONDS)
	local out = TweenService:Create(label, TweenInfo.new(0.3), {
		Position = UDim2.new(0.5, 0, 0, -90),
		BackgroundTransparency = 1,
		TextTransparency = 1,
	})
	out:Play()
	out.Completed:Wait()
	label:Destroy()
end

local function run()
	showing = true
	while #queue > 0 do
		local item = table.remove(queue, 1)
		if item then
			display(item)
		end
	end
	showing = false
end

function Banner.show(text: string, style: string?)
	table.insert(queue, { text = text, style = style or "info" })
	while #queue > MAX_QUEUE do
		table.remove(queue, 1)
	end
	if not showing then
		task.spawn(run)
	end
end

function Banner.mount(overlay: ScreenGui)
	screen = overlay
	container = UI.new("Frame", {
		Name = "Banners",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 56),
		Size = UDim2.new(0.8, 0, 0, 60),
		BackgroundTransparency = 1,
		ClipsDescendants = false,
		Parent = overlay,
	})
	UI.new("UISizeConstraint", { MaxSize = Vector2.new(700, 60), Parent = container })

	-- Anúncios enviados pelo servidor (Announce.luau).
	Net.on("Announce", function(payload: any)
		if type(payload) ~= "table" or type(payload.key) ~= "string" then
			return
		end
		local text = Locale.t(payload.key, payload.params)
		if payload.style == "toast" then
			-- Mensagens de erro ("error.*") ficam vermelhas; as outras, verdes (correção P11).
			local isError = string.sub(payload.key, 1, 6) == "error."
			Toast.show(text, if isError then "bad" else "good")
		elseif payload.style == "toastInfo" then
			Toast.show(text, "info")
		else
			Banner.show(text, payload.style)
		end
	end)
end

return Banner
