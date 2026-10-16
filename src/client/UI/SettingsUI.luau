--!strict
--[[
	SettingsUI.luau
	Modo Escudo e trilha cosmética.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Monetization = require(ReplicatedStorage.Shared.Config.Monetization)
local Locale = require(ReplicatedStorage.Shared.Locale)
local UI = require(script.Parent.Components)
local Theme = require(script.Parent.Theme)
local Page = require(script.Parent.Page)
local State = require(script.Parent.Parent.State)
local Net = require(script.Parent.Parent.Net)

local SettingsUI = {}

local page: Page.Page
local list: ScrollingFrame
local busy = false

local function request(name: string, ...: any)
	if busy then
		return
	end
	busy = true
	Net.request(name, ...)
	busy = false
end

local function render()
	local snapshot = State.snapshot
	if not snapshot or not page.isOpen() then
		return
	end
	local data = snapshot.data
	UI.clearChildren(list)

	-- Modo Escudo
	local shieldRow = Page.row(list, 1, 76)
	UI.label({
		Text = Locale.t("ui.shield"),
		Position = UDim2.fromOffset(12, 4),
		Size = UDim2.new(1, -180, 0, 34),
		TextXAlignment = Enum.TextXAlignment.Left,
		MaxTextSize = 22,
		Parent = shieldRow,
	})
	UI.label({
		Text = Locale.t("ui.shieldDesc"),
		Position = UDim2.fromOffset(12, 40),
		Size = UDim2.new(1, -180, 0, 30),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Theme.colors.textDim,
		Font = Theme.fontBody,
		MaxTextSize = 15,
		Parent = shieldRow,
	})
	local shieldOn = data.settings.shield
	UI.button({
		Text = if shieldOn then Locale.t("ui.on") else Locale.t("ui.off"),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		Size = UDim2.fromOffset(150, 56),
		BackgroundColor3 = if shieldOn then Theme.colors.good else Theme.colors.disabled,
		Parent = shieldRow,
	}, function()
		request("SetShield", not shieldOn)
	end)

	-- Trilhas
	local trailRow = Page.row(list, 2, 76)
	UI.label({
		Text = Locale.t("ui.trail"),
		Position = UDim2.fromOffset(12, 0),
		Size = UDim2.new(0, 120, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
		MaxTextSize = 22,
		Parent = trailRow,
	})
	local options: Frame = UI.new("Frame", {
		Position = UDim2.fromOffset(130, 10),
		Size = UDim2.new(1, -140, 0, 56),
		BackgroundTransparency = 1,
		Parent = trailRow,
	})
	UI.list(options, Enum.FillDirection.Horizontal, 8)
	local choices: { { id: string?, name: string } } = { { id = nil, name = Locale.t("ui.trailNone") } }
	for id, def in Monetization.cosmetics do
		if data.cosmetics.owned[id] then
			table.insert(choices, { id = id, name = def.name })
		end
	end
	for order, choice in choices do
		local selected = data.cosmetics.trail == choice.id
		UI.button({
			Text = choice.name,
			LayoutOrder = order,
			Size = UDim2.fromOffset(150, 56),
			BackgroundColor3 = if selected then Theme.colors.gold else Theme.colors.panel,
			MaxTextSize = 18,
			Parent = options,
		}, function()
			request("EquipTrail", choice.id or "")
		end)
	end
end

function SettingsUI.mount(screen: ScreenGui)
	page = Page.create(screen, "Settings", "⚙️ " .. Locale.t("ui.settings"), render)
	list = Page.list(page.content, 0)
	State.changed:Connect(render)
end

return SettingsUI
