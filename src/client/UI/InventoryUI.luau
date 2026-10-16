--!strict
--[[
	InventoryUI.luau
	Lista de poções guardadas: beber ou vender.
	Vender só funciona perto do Balcão de Vendas (o servidor confere).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Shared.Types)
local Mutations = require(ReplicatedStorage.Shared.Config.Mutations)
local Locale = require(ReplicatedStorage.Shared.Locale)
local Format = require(ReplicatedStorage.Shared.Util.Format)
local Describe = require(ReplicatedStorage.Shared.Util.Describe)
local PlayerStats = require(ReplicatedStorage.Shared.Util.PlayerStats)
local RecipeKey = require(ReplicatedStorage.Shared.Util.RecipeKey)
local UI = require(script.Parent.Components)
local Theme = require(script.Parent.Theme)
local Router = require(script.Parent.Router)
local Toast = require(script.Parent.Toast)
local State = require(script.Parent.Parent.State)
local Net = require(script.Parent.Parent.Net)
local SplashController = require(script.Parent.Parent.Controllers.SplashController)

type Entry = { stackKey: string, count: number, info: Types.RecipeInfo, mutation: Types.MutationDef? }

local InventoryUI = {}

local root: Frame
local list: ScrollingFrame
local capacityLabel: TextLabel
local emptyLabel: TextLabel
local isOpen = false
local busy = false

local function drink(stackKey: string)
	if busy then
		return
	end
	busy = true
	local result = Net.request("DrinkPotion", stackKey)
	busy = false
	if result.ok then
		Toast.show(Locale.t("ui.drank", { name = result.data.name }), "good")
		Router.close() -- fecha para o jogador ver a transformação
	end
end

local function sell(stackKey: string, amount: number)
	if busy then
		return
	end
	busy = true
	local result = Net.request("SellPotion", stackKey, amount)
	busy = false
	if result.ok then
		Toast.show(Locale.t("ui.sold", { coins = Format.number(result.data.coins) }), "good")
	end
end

local function render()
	local snapshot = State.snapshot
	if not snapshot or not isOpen then
		return
	end
	local data = snapshot.data

	capacityLabel.Text = Locale.t("ui.capacity", {
		count = PlayerStats.potionCount(data),
		max = PlayerStats.potionCapacity(data),
	})

	local entries: { Entry } = {}
	for stackKey, count in data.potions do
		local recipeKey, mutationId = RecipeKey.splitStack(stackKey)
		local info = snapshot.recipes[recipeKey]
		if count > 0 and info then
			local mutation = if mutationId then Mutations.byId[mutationId] else nil
			table.insert(entries, { stackKey = stackKey, count = count, info = info, mutation = mutation })
		end
	end
	-- Mutadas primeiro (são as mais valiosas), depois por nome.
	table.sort(entries, function(a, b)
		if (a.mutation ~= nil) ~= (b.mutation ~= nil) then
			return a.mutation ~= nil
		end
		if a.info.name ~= b.info.name then
			return a.info.name < b.info.name
		end
		return a.stackKey < b.stackKey
	end)

	UI.clearChildren(list)
	emptyLabel.Visible = #entries == 0

	for index, entry in entries do
		local row: Frame = UI.new("Frame", {
			LayoutOrder = index,
			Size = UDim2.new(1, -10, 0, 76),
			BackgroundColor3 = Theme.colors.panelLight,
			Parent = list,
		})
		UI.corner(row)

		local swatch: Frame = UI.new("Frame", {
			Position = UDim2.fromOffset(8, 8),
			Size = UDim2.fromOffset(60, 60),
			BackgroundColor3 = entry.info.color,
			Parent = row,
		})
		UI.corner(swatch, 30)
		local mutation = entry.mutation
		UI.stroke(swatch, if mutation then mutation.color else Color3.new(1, 1, 1), 3)

		local mutationId = if mutation then mutation.id else nil
		local price = PlayerStats.sellPrice(data, entry.info.value * Mutations.priceMultiplier(mutationId))
		-- RichText permite pintar só um pedaço do texto (o nome da mutação).
		local mutationText = if mutation
			then `  <font color="#{mutation.color:ToHex()}">✨{Locale.name("mutation", mutation.id, mutation.name)}</font>`
			else ""
		UI.label({
			Text = `{entry.info.name}{mutationText}  x{entry.count}`,
			RichText = true,
			Position = UDim2.fromOffset(76, 4),
			Size = UDim2.new(1, -76 - 430, 0, 36),
			TextXAlignment = Enum.TextXAlignment.Left,
			MaxTextSize = 22,
			Parent = row,
		})
		UI.label({
			Text = `{Describe.effect(entry.info.effect)}  •  🪙 {Format.number(price)}`,
			Position = UDim2.fromOffset(76, 40),
			Size = UDim2.new(1, -76 - 430, 0, 30),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = Theme.colors.textDim,
			Font = Theme.fontBody,
			MaxTextSize = 16,
			Parent = row,
		})

		local actions: Frame = UI.new("Frame", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -8, 0.5, 0),
			Size = UDim2.fromOffset(420, 56),
			BackgroundTransparency = 1,
			Parent = row,
		})
		UI.list(actions, Enum.FillDirection.Horizontal, 6, Enum.HorizontalAlignment.Right)
		UI.button({
			Text = Locale.t("ui.drink"),
			LayoutOrder = 1,
			Size = UDim2.fromOffset(96, 56),
			BackgroundColor3 = Theme.colors.good,
			MaxTextSize = 20,
			Parent = actions,
		}, function()
			drink(entry.stackKey)
		end)
		UI.button({
			Text = Locale.t("ui.sell1"),
			LayoutOrder = 2,
			Size = UDim2.fromOffset(96, 56),
			BackgroundColor3 = Theme.colors.gold,
			MaxTextSize = 20,
			Parent = actions,
		}, function()
			sell(entry.stackKey, 1)
		end)
		UI.button({
			Text = Locale.t("ui.sellAll"),
			LayoutOrder = 3,
			Size = UDim2.fromOffset(110, 56),
			BackgroundColor3 = Theme.colors.gold,
			MaxTextSize = 20,
			Parent = actions,
		}, function()
			sell(entry.stackKey, entry.count)
		end)
		UI.button({
			Text = "💦 " .. Locale.t("ui.throw"),
			LayoutOrder = 4,
			Size = UDim2.fromOffset(84, 56),
			BackgroundColor3 = Color3.fromRGB(70, 140, 200),
			MaxTextSize = 18,
			Parent = actions,
		}, function()
			if SplashController.throw(entry.stackKey) then
				Router.close() -- fecha para ver o respingo
			end
		end)
	end
end

function InventoryUI.mount(screen: ScreenGui)
	local content
	root, content = UI.panel(screen, "🧪 " .. Locale.t("ui.potions"), function()
		Router.close()
	end)

	capacityLabel = UI.label({
		Size = UDim2.new(1, 0, 0, 26),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Theme.colors.textDim,
		MaxTextSize = 20,
		Parent = content,
	})
	list = UI.scroll({
		Position = UDim2.fromOffset(0, 32),
		Size = UDim2.new(1, 0, 1, -32),
		Parent = content,
	})
	UI.list(list, Enum.FillDirection.Vertical, 8)
	emptyLabel = UI.label({
		Text = Locale.t("ui.noPotions"),
		Position = UDim2.fromOffset(0, 60),
		Size = UDim2.new(1, 0, 0, 40),
		TextColor3 = Theme.colors.textDim,
		Visible = false,
		Parent = content,
	})

	Router.register("Inventory", {
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

return InventoryUI
