--!strict
--[[
	SocialUI.luau
	Lista dos jogadores do servidor: visitar a loja e convidar para troca.
	Mostra o bônus de moedas por amigos no servidor.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Social = require(ReplicatedStorage.Shared.Config.Social)
local Locale = require(ReplicatedStorage.Shared.Locale)
local UI = require(script.Parent.Components)
local Theme = require(script.Parent.Theme)
local Toast = require(script.Parent.Toast)
local Router = require(script.Parent.Router)
local Page = require(script.Parent.Page)
local State = require(script.Parent.Parent.State)
local Net = require(script.Parent.Parent.Net)

local SocialUI = {}

local page: Page.Page
local header: TextLabel
local list: ScrollingFrame
local friendCache: { [number]: boolean } = {}

local render: () -> ()

local function checkFriend(userId: number)
	if friendCache[userId] ~= nil then
		return
	end
	friendCache[userId] = false
	task.spawn(function()
		local ok, result = pcall(Players.LocalPlayer.IsFriendsWithAsync, Players.LocalPlayer, userId)
		friendCache[userId] = ok and result == true
		render()
	end)
end

render = function()
	if not page.isOpen() then
		return
	end
	local snapshot = State.snapshot
	local friends = if snapshot and snapshot.session.friends then snapshot.session.friends else 0
	local percent = math.floor(math.min(Social.friendBonusMax, friends * Social.friendBonusPerFriend) * 100 + 0.5)
	header.Text = Locale.t("ui.friendBonus", { percent = percent })

	UI.clearChildren(list)
	local others = {}
	for _, player in Players:GetPlayers() do
		if player ~= Players.LocalPlayer then
			table.insert(others, player)
		end
	end
	if #others == 0 then
		local row = Page.row(list, 1, 56)
		UI.label({
			Text = Locale.t("ui.noPlayers"),
			Size = UDim2.fromScale(1, 1),
			TextColor3 = Theme.colors.textDim,
			Parent = row,
		})
		return
	end
	for index, player in others do
		checkFriend(player.UserId)
		local row = Page.row(list, index, 64)
		UI.label({
			Text = player.DisplayName .. (if friendCache[player.UserId] then `  {Locale.t("ui.friendTag")}` else ""),
			Position = UDim2.fromOffset(12, 0),
			Size = UDim2.new(1, -250, 1, 0),
			TextXAlignment = Enum.TextXAlignment.Left,
			MaxTextSize = 22,
			Parent = row,
		})
		local actions: Frame = UI.new("Frame", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -8, 0.5, 0),
			Size = UDim2.fromOffset(230, 52),
			BackgroundTransparency = 1,
			Parent = row,
		})
		UI.list(actions, Enum.FillDirection.Horizontal, 8, Enum.HorizontalAlignment.Right)
		UI.button({
			Text = "🏪 " .. Locale.t("ui.visit"),
			LayoutOrder = 1,
			Size = UDim2.fromOffset(110, 52),
			BackgroundColor3 = Theme.colors.good,
			MaxTextSize = 18,
			Parent = actions,
		}, function()
			if Net.request("VisitShop", player.UserId).ok then
				Router.close()
			end
		end)
		if Social.tradingEnabled then
			UI.button({
				Text = "🤝 " .. Locale.t("ui.trade"),
				LayoutOrder = 2,
				Size = UDim2.fromOffset(110, 52),
				MaxTextSize = 18,
				Parent = actions,
			}, function()
				if Net.request("TradeRequest", player.UserId).ok then
					Toast.show(Locale.t("ui.tradeSent"), "good")
				end
			end)
		end
	end
end

function SocialUI.mount(screen: ScreenGui)
	page = Page.create(screen, "Players", "👥 " .. Locale.t("ui.players"), function()
		render()
	end)
	header = UI.label({
		Size = UDim2.new(1, 0, 0, 26),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Theme.colors.gold,
		MaxTextSize = 20,
		Parent = page.content,
	})
	list = Page.list(page.content, 32)
	State.changed:Connect(function()
		render()
	end)
	Players.PlayerAdded:Connect(function()
		render()
	end)
	Players.PlayerRemoving:Connect(function()
		task.defer(render)
	end)
end

return SocialUI
