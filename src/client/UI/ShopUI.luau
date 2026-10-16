--!strict
--[[
	ShopUI.luau
	Pedidos dos clientes NPC da sua loja. Para cada pedido mostramos as poções
	do seu inventário que servem (as mais baratas primeiro, para você não
	gastar sem querer uma poção mutada valiosa). Entregar exige estar perto do
	balcão da sua loja (o servidor confere).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Shared.Types)
local Mutations = require(ReplicatedStorage.Shared.Config.Mutations)
local Locale = require(ReplicatedStorage.Shared.Locale)
local Format = require(ReplicatedStorage.Shared.Util.Format)
local RecipeKey = require(ReplicatedStorage.Shared.Util.RecipeKey)
local PlayerStats = require(ReplicatedStorage.Shared.Util.PlayerStats)
local OrderMatch = require(ReplicatedStorage.Shared.Util.OrderMatch)
local UI = require(script.Parent.Components)
local Theme = require(script.Parent.Theme)
local Toast = require(script.Parent.Toast)
local Page = require(script.Parent.Page)
local State = require(script.Parent.Parent.State)
local Net = require(script.Parent.Parent.Net)

type Match = { stackKey: string, label: string, price: number }

local MAX_OPTIONS = 3

local ShopUI = {}

local page: Page.Page
local statsLabel: TextLabel
local list: ScrollingFrame
local timers: { { label: TextLabel, expiresAt: number } } = {}
local busy = false

local function matchesFor(snapshot: Types.Snapshot, order: Types.Order): { Match }
	local data = snapshot.data
	local found: { Match } = {}
	for stackKey, count in data.potions do
		local recipeKey, mutationId = RecipeKey.splitStack(stackKey)
		local info = snapshot.recipes[recipeKey]
		if count > 0 and info and OrderMatch.matches(order, recipeKey, info) then
			local mutation = if mutationId then Mutations.byId[mutationId] else nil
			local unit = PlayerStats.sellPrice(data, info.value * Mutations.priceMultiplier(mutationId))
			table.insert(found, {
				stackKey = stackKey,
				label = info.name .. (if mutation then ` ✨{mutation.name}` else "") .. ` x{count}`,
				price = math.floor(unit * order.multiplier + 0.5),
			})
		end
	end
	table.sort(found, function(a, b)
		return a.price < b.price
	end)
	return found
end

local function deliver(orderId: string, stackKey: string)
	if busy then
		return
	end
	busy = true
	local result = Net.request("ShopDeliver", orderId, stackKey)
	busy = false
	if result.ok then
		Toast.show(Locale.t("ui.delivered", { coins = Format.number(result.data.coins) }), "good")
	end
end

local function render()
	local snapshot = State.snapshot
	if not snapshot or not page.isOpen() then
		return
	end
	local shop = snapshot.data.shop
	statsLabel.Text = Locale.t("ui.shopStats", {
		likes = Format.number(shop.likes),
		visits = Format.number(shop.visits),
		served = Format.number(shop.served),
	})

	UI.clearChildren(list)
	table.clear(timers)
	local orders: { Types.Order } = snapshot.session.orders or {}
	if #orders == 0 then
		local row = Page.row(list, 1, 56)
		UI.label({
			Text = Locale.t("ui.noOrders"),
			Size = UDim2.fromScale(1, 1),
			TextColor3 = Theme.colors.textDim,
			Parent = row,
		})
		return
	end

	for index, order in orders do
		local row = Page.row(list, index, 116)
		if order.special then
			UI.stroke(row, Theme.colors.gold, 3)
		end
		UI.label({
			Text = `🧑 {order.customerName}: "{OrderMatch.describe(order)}"`,
			Position = UDim2.fromOffset(12, 4),
			Size = UDim2.new(1, -100, 0, 32),
			TextXAlignment = Enum.TextXAlignment.Left,
			MaxTextSize = 20,
			Parent = row,
		})
		local timer = UI.label({
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -10, 0, 4),
			Size = UDim2.fromOffset(80, 32),
			TextXAlignment = Enum.TextXAlignment.Right,
			TextColor3 = Theme.colors.textDim,
			MaxTextSize = 18,
			Parent = row,
		})
		table.insert(timers, { label = timer, expiresAt = order.expiresAt })
		UI.label({
			Text = if order.special
				then Locale.t("ui.orderSpecial", { mult = order.multiplier })
				else Locale.t("ui.orderPays", { mult = order.multiplier }),
			Position = UDim2.fromOffset(12, 34),
			Size = UDim2.new(1, -24, 0, 22),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = Theme.colors.gold,
			Font = Theme.fontBody,
			MaxTextSize = 15,
			Parent = row,
		})

		local options: Frame = UI.new("Frame", {
			Position = UDim2.fromOffset(8, 60),
			Size = UDim2.new(1, -16, 0, 50),
			BackgroundTransparency = 1,
			Parent = row,
		})
		UI.list(options, Enum.FillDirection.Horizontal, 6)
		local matches = matchesFor(snapshot, order)
		if #matches == 0 then
			UI.label({
				Text = Locale.t("ui.noMatch"),
				Size = UDim2.fromScale(1, 1),
				TextColor3 = Theme.colors.textDim,
				TextXAlignment = Enum.TextXAlignment.Left,
				MaxTextSize = 16,
				Parent = options,
			})
		end
		for order2 = 1, math.min(MAX_OPTIONS, #matches) do
			local match = matches[order2]
			UI.button({
				Text = `{Locale.t("ui.deliver")}: {match.label} (🪙{Format.number(match.price)})`,
				LayoutOrder = order2,
				Size = UDim2.new(1 / MAX_OPTIONS, -6, 1, 0),
				BackgroundColor3 = Theme.colors.good,
				MaxTextSize = 15,
				Parent = options,
			}, function()
				deliver(order.id, match.stackKey)
			end)
		end
	end
end

-- Quantos clientes estão esperando (para a fichinha do HUD).
function ShopUI.waitingCount(): number
	local snapshot = State.snapshot
	local orders = if snapshot then snapshot.session.orders else nil
	return if orders then #orders else 0
end

function ShopUI.mount(screen: ScreenGui)
	page = Page.create(screen, "Shop", "🏪 " .. Locale.t("ui.myShop"), render)
	statsLabel = UI.label({
		Size = UDim2.new(1, -220, 0, 40),
		TextXAlignment = Enum.TextXAlignment.Left,
		MaxTextSize = 20,
		Parent = page.content,
	})
	UI.button({
		Text = Locale.t("ui.goToShop"),
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.fromOffset(210, 40),
		BackgroundColor3 = Theme.colors.good,
		MaxTextSize = 18,
		Parent = page.content,
	}, function()
		Net.request("VisitShop", Players.LocalPlayer.UserId)
	end)
	list = Page.list(page.content, 48)
	State.changed:Connect(render)

	task.spawn(function()
		while true do
			task.wait(1)
			if page.isOpen() then
				local now = State.serverNow()
				for _, timer in timers do
					timer.label.Text = "⏳ " .. Format.time(timer.expiresAt - now)
				end
			end
		end
	end)
end

return ShopUI
