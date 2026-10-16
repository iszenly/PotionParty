--!strict
--[[
	DailyUI.luau
	Recompensa diária com sequência. Abre sozinha uma vez por sessão quando
	há prêmio para pegar.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Daily = require(ReplicatedStorage.Shared.Config.Daily)
local Locale = require(ReplicatedStorage.Shared.Locale)
local Format = require(ReplicatedStorage.Shared.Util.Format)
local UI = require(script.Parent.Components)
local Theme = require(script.Parent.Theme)
local Toast = require(script.Parent.Toast)
local Router = require(script.Parent.Router)
local Page = require(script.Parent.Page)
local State = require(script.Parent.Parent.State)
local Net = require(script.Parent.Parent.Net)

local DailyUI = {}

local page: Page.Page
local streakLabel: TextLabel
local cards: ScrollingFrame
local claimButton: TextButton
local busy = false

local function today(): number
	return math.floor(State.serverNow() / 86400)
end

-- (pode pegar hoje?, dia da sequência que será pego/foi pego hoje)
local function status(): (boolean, number)
	local snapshot = State.snapshot
	if not snapshot then
		return false, 1
	end
	local streak = snapshot.data.streak
	local day = today()
	if streak.lastClaimDay == day then
		return false, streak.count
	elseif streak.lastClaimDay == day - 1 then
		return true, streak.count + 1
	end
	return true, 1
end

function DailyUI.canClaim(): boolean
	return (status())
end

local function render()
	if not page.isOpen() then
		return
	end
	local claimable, streakDay = status()
	local highlight = ((streakDay - 1) % #Daily.rewards) + 1
	streakLabel.Text = Locale.t("ui.dailyStreak", { n = streakDay })

	UI.clearChildren(cards)
	for index, reward in Daily.rewards do
		local isToday = index == highlight
		local card: Frame = UI.new("Frame", {
			LayoutOrder = index,
			Size = UDim2.fromOffset(92, 120),
			BackgroundColor3 = if isToday then Theme.colors.gold else Theme.colors.panelLight,
			Parent = cards,
		})
		UI.corner(card)
		UI.label({
			Text = Locale.t("ui.dailyDay", { n = index }),
			Size = UDim2.new(1, 0, 0, 30),
			TextColor3 = if isToday then Theme.colors.stroke else Theme.colors.text,
			MaxTextSize = 20,
			Parent = card,
		})
		UI.label({
			Text = `🪙\n{Format.number(reward.coins)}` .. (if reward.ingredients then "\n+🧺" else ""),
			Position = UDim2.fromOffset(0, 30),
			Size = UDim2.new(1, 0, 1, -34),
			TextColor3 = if isToday then Theme.colors.stroke else Theme.colors.gold,
			MaxTextSize = 20,
			Parent = card,
		})
	end

	claimButton.Text = if claimable then Locale.t("ui.claim") else Locale.t("ui.dailyClaimed")
	claimButton.BackgroundColor3 = if claimable then Theme.colors.good else Theme.colors.disabled
end

function DailyUI.mount(screen: ScreenGui)
	page = Page.create(screen, "Daily", "🎁 " .. Locale.t("ui.dailyTitle"), render)
	streakLabel = UI.label({
		Size = UDim2.new(1, 0, 0, 28),
		MaxTextSize = 22,
		Parent = page.content,
	})
	cards = UI.scroll({
		Position = UDim2.fromOffset(0, 36),
		Size = UDim2.new(1, 0, 0, 132),
		ScrollingDirection = Enum.ScrollingDirection.X,
		AutomaticCanvasSize = Enum.AutomaticSize.X,
		Parent = page.content,
	})
	UI.list(cards, Enum.FillDirection.Horizontal, 8)
	claimButton = UI.button({
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -4),
		Size = UDim2.new(0.6, 0, 0, Theme.buttonHeight),
		Parent = page.content,
	}, function()
		if busy or not DailyUI.canClaim() then
			return
		end
		busy = true
		local result = Net.request("ClaimDaily")
		busy = false
		if result.ok then
			Toast.show(Locale.t("ui.dailyGot", { coins = Format.number(result.data.coins) }), "good")
		end
	end)

	State.changed:Connect(render)

	-- Abre sozinha uma vez, quando chegam os primeiros dados e há prêmio.
	local shown = false
	State.changed:Connect(function()
		if not shown and DailyUI.canClaim() then
			shown = true
			task.delay(2, function()
				if Router.current() == nil then
					Router.open("Daily")
				end
			end)
		end
	end)
end

return DailyUI
