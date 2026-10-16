--!strict
--[[
	MarketUI.luau
	Mercado de ingredientes: comprar os liberados e liberar os bloqueados.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Ingredients = require(ReplicatedStorage.Shared.Config.Ingredients)
local Rarities = require(ReplicatedStorage.Shared.Config.Rarities)
local Locale = require(ReplicatedStorage.Shared.Locale)
local Format = require(ReplicatedStorage.Shared.Util.Format)
local UI = require(script.Parent.Components)
local Theme = require(script.Parent.Theme)
local Router = require(script.Parent.Router)
local Toast = require(script.Parent.Toast)
local State = require(script.Parent.Parent.State)
local Net = require(script.Parent.Parent.Net)

local MarketUI = {}

local root: Frame
local list: ScrollingFrame
local isOpen = false
local busy = false

local function request(name: string, ...: any): boolean
	if busy then
		return false
	end
	busy = true
	local result = Net.request(name, ...)
	busy = false
	return result.ok
end

local function render()
	local snapshot = State.snapshot
	if not snapshot or not isOpen then
		return
	end
	local data = snapshot.data
	UI.clearChildren(list)

	for index, def in Ingredients.list do
		local unlocked = data.unlocked[def.id] == true
		local rarity = Rarities[def.rarity]
		local name = Locale.name("ingredient", def.id, def.name)

		local row: Frame = UI.new("Frame", {
			LayoutOrder = index,
			Size = UDim2.new(1, -10, 0, 70),
			BackgroundColor3 = Theme.colors.panelLight,
			Parent = list,
		})
		UI.corner(row)

		local dot: Frame = UI.new("Frame", {
			Position = UDim2.fromOffset(10, 11),
			Size = UDim2.fromOffset(48, 48),
			BackgroundColor3 = def.color,
			BackgroundTransparency = if unlocked then 0 else 0.6,
			Parent = row,
		})
		UI.corner(dot, 24)
		UI.stroke(dot, rarity.color, 3)

		UI.label({
			Text = name,
			Position = UDim2.fromOffset(68, 4),
			Size = UDim2.new(1, -68 - 250, 0, 32),
			TextXAlignment = Enum.TextXAlignment.Left,
			MaxTextSize = 22,
			Parent = row,
		})
		local subtitle = Locale.name("rarity", def.rarity, rarity.name)
		if def.cometOnly or unlocked then
			subtitle ..= "  •  " .. Locale.t("ui.owned", { count = data.ingredients[def.id] or 0 })
		else
			subtitle ..= "  •  " .. Locale.t("ui.locked")
		end
		UI.label({
			Text = subtitle,
			Position = UDim2.fromOffset(68, 36),
			Size = UDim2.new(1, -68 - 250, 0, 26),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = rarity.color,
			Font = Theme.fontBody,
			MaxTextSize = 16,
			Parent = row,
		})

		local actions: Frame = UI.new("Frame", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -8, 0.5, 0),
			Size = UDim2.fromOffset(240, 54),
			BackgroundTransparency = 1,
			Parent = row,
		})
		UI.list(actions, Enum.FillDirection.Horizontal, 6, Enum.HorizontalAlignment.Right)

		if def.cometOnly then
			-- Não está à venda: só cai do Cometa.
			UI.label({
				Text = Locale.t("ui.cometOnly"),
				Size = UDim2.fromOffset(200, 54),
				TextColor3 = Theme.colors.gold,
				MaxTextSize = 18,
				Parent = actions,
			})
		elseif unlocked then
			for order, amount in { 1, 5 } do
				local price = def.price * amount
				UI.button({
					Text = Locale.t(
						if amount == 1 then "ui.buy1" else "ui.buy5",
						{ price = "🪙" .. Format.number(price) }
					),
					LayoutOrder = order,
					Size = UDim2.fromOffset(116, 54),
					BackgroundColor3 = if data.coins >= price then Theme.colors.good else Theme.colors.disabled,
					MaxTextSize = 18,
					Parent = actions,
				}, function()
					if request("BuyIngredient", def.id, amount) then
						Toast.show(Locale.t("ui.bought"), "good")
					end
				end)
			end
		else
			UI.button({
				Text = Locale.t("ui.unlock", { price = "🪙" .. Format.number(def.unlockPrice) }),
				Size = UDim2.fromOffset(200, 54),
				BackgroundColor3 = if data.coins >= def.unlockPrice then Theme.colors.gold else Theme.colors.disabled,
				MaxTextSize = 18,
				Parent = actions,
			}, function()
				if request("UnlockIngredient", def.id) then
					Toast.show(Locale.t("ui.unlocked", { name = name }), "good")
				end
			end)
		end
	end
end

function MarketUI.mount(screen: ScreenGui)
	local content
	root, content = UI.panel(screen, "🧺 " .. Locale.t("ui.market"), function()
		Router.close()
	end)
	list = UI.scroll({ Size = UDim2.fromScale(1, 1), Parent = content })
	UI.list(list, Enum.FillDirection.Vertical, 8)

	Router.register("Market", {
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

return MarketUI
