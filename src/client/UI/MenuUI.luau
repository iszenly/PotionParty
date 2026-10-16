--!strict
--[[
	MenuUI.luau
	Menu com botões grandes para as telas que não cabem no HUD.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Locale = require(ReplicatedStorage.Shared.Locale)
local UI = require(script.Parent.Components)
local Theme = require(script.Parent.Theme)
local Router = require(script.Parent.Router)
local Page = require(script.Parent.Page)

local MenuUI = {}

local ENTRIES: { { icon: string, key: string, page: string, color: Color3 } } = {
	{ icon = "🎯", key = "ui.missions", page = "Missions", color = Color3.fromRGB(80, 160, 220) },
	{ icon = "🎁", key = "ui.daily", page = "Daily", color = Color3.fromRGB(230, 120, 80) },
	{ icon = "🏪", key = "ui.myShop", page = "Shop", color = Color3.fromRGB(90, 180, 110) },
	{ icon = "👥", key = "ui.players", page = "Players", color = Color3.fromRGB(150, 100, 220) },
	{ icon = "🧙", key = "ui.rebirth", page = "Rebirth", color = Color3.fromRGB(200, 90, 160) },
	{ icon = "💎", key = "ui.store", page = "Store", color = Theme.colors.gold },
	{ icon = "⚙️", key = "ui.settings", page = "Settings", color = Theme.colors.disabled },
}

function MenuUI.mount(screen: ScreenGui)
	local page = Page.create(screen, "Menu", "☰ " .. Locale.t("ui.menu"))
	local grid = UI.scroll({ Size = UDim2.fromScale(1, 1), Parent = page.content })
	UI.new("UIGridLayout", {
		CellSize = UDim2.fromOffset(170, 80),
		CellPadding = UDim2.fromOffset(10, 10),
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Parent = grid,
	})
	UI.padding(grid, 6)
	for order, entry in ENTRIES do
		UI.button({
			Text = `{entry.icon} {Locale.t(entry.key)}`,
			LayoutOrder = order,
			BackgroundColor3 = entry.color,
			MaxTextSize = 24,
			Parent = grid,
		}, function()
			Router.open(entry.page)
		end)
	end
end

return MenuUI
