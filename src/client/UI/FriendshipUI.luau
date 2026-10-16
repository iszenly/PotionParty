--!strict
--[[
	FriendshipUI.luau
	Tela do Caldeirão da Amizade. Abre sozinha quando você entra num dos lados.
	Escolha 2 ingredientes, veja o que o outro colocou e marquem "Pronto!".
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Social = require(ReplicatedStorage.Shared.Config.Social)
local Ingredients = require(ReplicatedStorage.Shared.Config.Ingredients)
local Locale = require(ReplicatedStorage.Shared.Locale)
local UI = require(script.Parent.Components)
local Theme = require(script.Parent.Theme)
local Router = require(script.Parent.Router)
local Page = require(script.Parent.Page)
local RevealPopup = require(script.Parent.RevealPopup)
local State = require(script.Parent.Parent.State)
local Net = require(script.Parent.Parent.Net)

type FriendshipState = {
	partnerName: string?,
	myPicks: { string },
	theirPicks: { string },
	myReady: boolean,
	theirReady: boolean,
}

local FriendshipUI = {}

local page: Page.Page
local statusLabel: TextLabel
local slotsRow: Frame
local grid: ScrollingFrame
local readyButton: TextButton
local state: FriendshipState? = nil
local localPicks: { string } = {}

local function name(id: string): string
	local def = Ingredients.byId[id]
	return Locale.name("ingredient", id, if def then def.name else id)
end

local function namesOf(ids: { string }): string
	local list: { string } = {}
	for _, id in ids do
		table.insert(list, name(id))
	end
	return table.concat(list, " + ")
end

local function countPicked(id: string): number
	local total = 0
	for _, picked in localPicks do
		if picked == id then
			total += 1
		end
	end
	return total
end

local render: () -> ()

local function sendPicks()
	if #localPicks == Social.friendshipIngredientsPerPlayer then
		Net.request("FriendshipPick", localPicks)
	elseif state and state.myReady then
		Net.request("FriendshipReady", false)
	end
end

render = function()
	local current = state
	local snapshot = State.snapshot
	if not current or not snapshot or not page.isOpen() then
		return
	end
	if current.partnerName then
		local theirs = if #current.theirPicks > 0 then namesOf(current.theirPicks) else "…"
		statusLabel.Text = Locale.t("ui.partnerPicks", { name = current.partnerName })
			.. ` {theirs}`
			.. (if current.theirReady then "  ✅" else "")
	else
		statusLabel.Text = Locale.t("ui.friendshipWaiting")
	end

	UI.clearChildren(slotsRow)
	for index = 1, Social.friendshipIngredientsPerPlayer do
		local id = localPicks[index]
		local def = if id then Ingredients.byId[id] else nil
		UI.button({
			Text = if def then name(def.id) else "+",
			LayoutOrder = index,
			Size = UDim2.fromOffset(110, 56),
			BackgroundColor3 = if def then def.color else Theme.colors.panelLight,
			TextStrokeTransparency = 0.3,
			MaxTextSize = 16,
			Parent = slotsRow,
		}, function()
			if localPicks[index] and not current.myReady then
				table.remove(localPicks, index)
				sendPicks()
				render()
			end
		end)
	end

	UI.clearChildren(grid)
	for order, def in Ingredients.list do
		local available = (snapshot.data.ingredients[def.id] or 0) - countPicked(def.id)
		if (snapshot.data.ingredients[def.id] or 0) > 0 then
			local tile = UI.button({
				Text = `{name(def.id)}\nx{available}`,
				LayoutOrder = order,
				BackgroundColor3 = if available > 0 then Theme.colors.panelLight else Theme.colors.disabled,
				MaxTextSize = 15,
				Parent = grid,
			}, function()
				if current.myReady or available <= 0 or #localPicks >= Social.friendshipIngredientsPerPlayer then
					return
				end
				table.insert(localPicks, def.id)
				sendPicks()
				render()
			end)
			UI.stroke(tile, def.color, 3)
		end
	end

	local canReady = current.partnerName ~= nil and #localPicks == Social.friendshipIngredientsPerPlayer
	readyButton.Text = if current.myReady then "✅ " .. Locale.t("ui.tradeUnready") else Locale.t("ui.tradeReady")
	readyButton.BackgroundColor3 = if current.myReady
		then Theme.colors.panelLight
		elseif canReady then Theme.colors.good
		else Theme.colors.disabled
end

function FriendshipUI.mount(screen: ScreenGui)
	page = Page.create(screen, "Friendship", "💞 " .. Locale.t("ui.friendshipTitle"), function()
		render()
	end, function()
		Net.request("FriendshipLeave")
	end)
	statusLabel = UI.label({
		Size = UDim2.new(1, 0, 0, 28),
		TextXAlignment = Enum.TextXAlignment.Left,
		MaxTextSize = 19,
		Parent = page.content,
	})
	UI.label({
		Text = Locale.t("ui.friendshipPick"),
		Position = UDim2.fromOffset(0, 32),
		Size = UDim2.new(0.4, 0, 0, 56),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Theme.colors.textDim,
		MaxTextSize = 18,
		Parent = page.content,
	})
	slotsRow = UI.new("Frame", {
		Position = UDim2.new(0.4, 0, 0, 32),
		Size = UDim2.new(0.6, 0, 0, 56),
		BackgroundTransparency = 1,
		Parent = page.content,
	})
	UI.list(slotsRow, Enum.FillDirection.Horizontal, 8)
	grid = UI.scroll({
		Position = UDim2.fromOffset(0, 94),
		Size = UDim2.new(1, 0, 1, -94 - 58),
		Parent = page.content,
	})
	UI.new("UIGridLayout", {
		CellSize = UDim2.fromOffset(110, 56),
		CellPadding = UDim2.fromOffset(6, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = grid,
	})
	readyButton = UI.button({
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(0.5, 1),
		Size = UDim2.new(0.6, 0, 0, 52),
		Parent = page.content,
	}, function()
		local current = state
		if not current then
			return
		end
		if
			not current.myReady and (current.partnerName == nil or #localPicks ~= Social.friendshipIngredientsPerPlayer)
		then
			return
		end
		Net.request("FriendshipReady", not current.myReady)
	end)

	Net.on("Friendship", function(message: any)
		if type(message) ~= "table" then
			return
		end
		if message.kind == "state" then
			state = message :: FriendshipState
			-- Se o servidor limpou a escolha (depois de preparar), limpa aqui também.
			if
				#message.myPicks == 0
				and not message.myReady
				and #localPicks == Social.friendshipIngredientsPerPlayer
			then
				localPicks = {}
			elseif #message.myPicks == Social.friendshipIngredientsPerPlayer then
				localPicks = table.clone(message.myPicks)
			end
			if Router.current() ~= "Friendship" then
				Router.open("Friendship")
			end
			render()
		elseif message.kind == "result" then
			localPicks = {}
			RevealPopup.show(message.recipe, message.isNew, message.stackKey, message.mutation)
		elseif message.kind == "closed" then
			state = nil
			localPicks = {}
			if Router.current() == "Friendship" then
				Router.close()
			end
		end
	end)
	State.changed:Connect(function()
		render()
	end)
end

return FriendshipUI
