--!strict
--[[
	Toast.luau
	Mensagens curtas que aparecem embaixo da tela e somem sozinhas.
		Toast.show("Comprado!", "good")
]]

local TweenService = game:GetService("TweenService")

local UI = require(script.Parent.Components)
local Theme = require(script.Parent.Theme)

local MAX_VISIBLE = 3
local DURATION = 2.5

local container: Frame? = nil

local Toast = {}

function Toast.mount(screen: ScreenGui)
	local frame: Frame = UI.new("Frame", {
		Name = "Toasts",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -16),
		Size = UDim2.new(0.8, 0, 0, 3 * 50),
		BackgroundTransparency = 1,
		Parent = screen,
	})
	local layout = UI.list(frame, Enum.FillDirection.Vertical, 6, Enum.HorizontalAlignment.Center)
	layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	container = frame
end

function Toast.show(text: string, kind: ("good" | "bad" | "info")?)
	local frame = container
	if not frame then
		return
	end
	local color = if kind == "good"
		then Theme.colors.good
		elseif kind == "bad" then Theme.colors.bad
		else Theme.colors.panelLight

	-- Remove os mais antigos se tiver muitos na tela.
	local existing = {}
	for _, child in frame:GetChildren() do
		if child:IsA("TextLabel") then
			table.insert(existing, child)
		end
	end
	if #existing >= MAX_VISIBLE then
		existing[1]:Destroy()
	end

	local label = UI.label({
		Text = text,
		Size = UDim2.new(1, 0, 0, 44),
		BackgroundTransparency = 0.1,
		BackgroundColor3 = color,
		MaxTextSize = 22,
		Parent = frame,
	})
	UI.corner(label, 12)
	UI.padding(label, 6)

	task.delay(DURATION, function()
		if label.Parent then
			local tween =
				TweenService:Create(label, TweenInfo.new(0.3), { BackgroundTransparency = 1, TextTransparency = 1 })
			tween:Play()
			tween.Completed:Wait()
			label:Destroy()
		end
	end)
end

return Toast
