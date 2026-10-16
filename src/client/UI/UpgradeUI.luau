--!strict
--[[
	UpgradeUI.luau
	Loja de melhorias (pode ser aberta de qualquer lugar pelo HUD).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Upgrades = require(ReplicatedStorage.Shared.Config.Upgrades)
local Locale = require(ReplicatedStorage.Shared.Locale)
local Format = require(ReplicatedStorage.Shared.Util.Format)
local UI = require(script.Parent.Components)
local Theme = require(script.Parent.Theme)
local Router = require(script.Parent.Router)
local Toast = require(script.Parent.Toast)
local State = require(script.Parent.Parent.State)
local Net = require(script.Parent.Parent.Net)

local UpgradeUI = {}

local root: Frame
local list: ScrollingFrame
local isOpen = false
local busy = false

local function render()
	local snapshot = State.snapshot
	if not snapshot or not isOpen then
		return
	end
	local data = snapshot.data
	UI.clearChildren(list)

	for index, def in Upgrades.list do
		local level = data.upgrades[def.id] or 0
		local cost = Upgrades.costFor(def, level)
		local name = Locale.name("upgrade", def.id, def.name)

		local row: Frame = UI.new("Frame", {
			LayoutOrder = index,
			Size = UDim2.new(1, -10, 0, 76),
			BackgroundColor3 = Theme.colors.panelLight,
			Parent = list,
		})
		UI.corner(row)

		UI.label({
			Text = `{name}  ({Locale.t("ui.level", { level = level, max = def.maxLevel })})`,
			Position = UDim2.fromOffset(12, 4),
			Size = UDim2.new(1, -12 - 220, 0, 36),
			TextXAlignment = Enum.TextXAlignment.Left,
			MaxTextSize = 22,
			Parent = row,
		})
		UI.label({
			Text = Locale.name("upgradeDesc", def.id, def.description),
			Position = UDim2.fromOffset(12, 40),
			Size = UDim2.new(1, -12 - 220, 0, 30),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = Theme.colors.textDim,
			Font = Theme.fontBody,
			MaxTextSize = 16,
			Parent = row,
		})

		local canBuy = cost ~= nil and data.coins >= cost
		UI.button({
			Text = if cost
				then Locale.t("ui.upgradeBuy", { price = "🪙" .. Format.number(cost) })
				else Locale.t("ui.maxed"),
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -8, 0.5, 0),
			Size = UDim2.fromOffset(204, 56),
			BackgroundColor3 = if canBuy then Theme.colors.good else Theme.colors.disabled,
			MaxTextSize = 20,
			Parent = row,
		}, function()
			if busy or cost == nil then
				return
			end
			busy = true
			local result = Net.request("BuyUpgrade", def.id)
			busy = false
			if result.ok then
				Toast.show(Locale.t("ui.upgraded", { name = name }), "good")
			end
		end)
	end
end

function UpgradeUI.mount(screen: ScreenGui)
	local content
	root, content = UI.panel(screen, "⬆️ " .. Locale.t("ui.upgrades"), function()
		Router.close()
	end)
	list = UI.scroll({ Size = UDim2.fromScale(1, 1), Parent = content })
	UI.list(list, Enum.FillDirection.Vertical, 8)

	Router.register("Upgrades", {
		open = function()
			isOpen = true
			root.Visible = true
			render()
		end,
		close = function()
			isOpen = false
			root.Visible = false
		end,
	})
	State.changed:Connect(render)
end

return UpgradeUI
