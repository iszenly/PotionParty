--!strict
--[[
	GrimoireUI.luau
	O Grimório tem 3 abas:
		Receitas  - tudo que o jogador já criou + quem descobriu primeiro no mundo
		Ranking   - jogadores com mais receitas no Grimório (todos os servidores)
		Segredos  - dicas das receitas secretas da semana
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Shared.Types)
local Ingredients = require(ReplicatedStorage.Shared.Config.Ingredients)
local Locale = require(ReplicatedStorage.Shared.Locale)
local Format = require(ReplicatedStorage.Shared.Util.Format)
local Describe = require(ReplicatedStorage.Shared.Util.Describe)
local UI = require(script.Parent.Components)
local Theme = require(script.Parent.Theme)
local Router = require(script.Parent.Router)
local State = require(script.Parent.Parent.State)
local Net = require(script.Parent.Parent.Net)

type Tab = "recipes" | "ranking" | "secrets"

local GrimoireUI = {}

local root: Frame
local header: TextLabel
local list: ScrollingFrame
local tabButtons: { [Tab]: TextButton } = {}
local isOpen = false
local currentTab: Tab = "recipes"
local info: Types.GrimoireInfo? = nil
local ranking: { Types.RankingEntry }? = nil

local function worldLine(entry: Types.DiscoveryEntry): string
	if entry.first then
		return Locale.t("ui.worldFirstYou")
	elseif entry.by then
		return Locale.t("ui.worldFirstOther", { name = entry.by })
	end
	return Locale.t("ui.worldPending")
end

local function ingredientNames(ids: { string }): string
	local names: { string } = {}
	for _, id in ids do
		local def = Ingredients.byId[id]
		table.insert(names, Locale.name("ingredient", id, if def then def.name else id))
	end
	return table.concat(names, " + ")
end

local function makeRow(index: number, height: number): Frame
	local row: Frame = UI.new("Frame", {
		LayoutOrder = index,
		Size = UDim2.new(1, -10, 0, height),
		BackgroundColor3 = Theme.colors.panelLight,
		Parent = list,
	})
	UI.corner(row)
	return row
end

local function renderRecipes(snapshot: Types.Snapshot)
	local data = snapshot.data
	local entries: { { key: string, entry: Types.DiscoveryEntry } } = {}
	for key, entry in data.discovered do
		table.insert(entries, { key = key, entry = entry })
	end
	-- Mais recentes primeiro.
	table.sort(entries, function(a, b)
		return a.entry.t > b.entry.t
	end)

	header.Text = Locale.t("ui.discoveredCount", {
		count = #entries,
		total = if info then Format.number(info.totalCombinations) else "?",
		first = data.worldFirsts,
	})

	if #entries == 0 then
		local row = makeRow(1, 60)
		UI.label({
			Text = Locale.t("ui.noDiscoveries"),
			Size = UDim2.fromScale(1, 1),
			TextColor3 = Theme.colors.textDim,
			Parent = row,
		})
		return
	end

	for index, item in entries do
		local recipe = snapshot.recipes[item.key]
		if recipe then
			local row = makeRow(index, 92)
			local swatch: Frame = UI.new("Frame", {
				Position = UDim2.fromOffset(10, 16),
				Size = UDim2.fromOffset(60, 60),
				BackgroundColor3 = recipe.color,
				Parent = row,
			})
			UI.corner(swatch, 30)
			UI.stroke(swatch, if item.entry.first then Theme.colors.gold else Color3.new(1, 1, 1), 3)

			UI.label({
				Text = (if recipe.isSpecial then "⭐ " else "") .. recipe.name,
				Position = UDim2.fromOffset(80, 4),
				Size = UDim2.new(1, -90, 0, 30),
				TextXAlignment = Enum.TextXAlignment.Left,
				MaxTextSize = 22,
				Parent = row,
			})
			UI.label({
				Text = `{Describe.effect(recipe.effect)}  •  {ingredientNames(recipe.ingredients)}`,
				Position = UDim2.fromOffset(80, 34),
				Size = UDim2.new(1, -90, 0, 26),
				TextXAlignment = Enum.TextXAlignment.Left,
				TextColor3 = Theme.colors.textDim,
				Font = Theme.fontBody,
				MaxTextSize = 15,
				Parent = row,
			})
			UI.label({
				Text = worldLine(item.entry),
				Position = UDim2.fromOffset(80, 60),
				Size = UDim2.new(1, -90, 0, 26),
				TextXAlignment = Enum.TextXAlignment.Left,
				TextColor3 = if item.entry.first then Theme.colors.gold else Theme.colors.text,
				MaxTextSize = 17,
				Parent = row,
			})
		end
	end
end

local function renderRanking()
	header.Text = Locale.t("ui.rankingTitle")
	local entries = ranking
	if entries == nil then
		local row = makeRow(1, 50)
		UI.label({ Text = Locale.t("ui.loadingShort"), Size = UDim2.fromScale(1, 1), Parent = row })
		return
	end
	if #entries == 0 then
		local row = makeRow(1, 50)
		UI.label({
			Text = Locale.t("ui.rankingEmpty"),
			Size = UDim2.fromScale(1, 1),
			TextColor3 = Theme.colors.textDim,
			Parent = row,
		})
		return
	end
	for index, entry in entries do
		local row = makeRow(index, 50)
		local medal = if entry.rank == 1
			then "🥇"
			elseif entry.rank == 2 then "🥈"
			elseif entry.rank == 3 then "🥉"
			else `{entry.rank}.`
		UI.label({
			Text = `{medal}  {entry.name}`,
			Position = UDim2.fromOffset(12, 0),
			Size = UDim2.new(0.7, -12, 1, 0),
			TextXAlignment = Enum.TextXAlignment.Left,
			MaxTextSize = 22,
			Parent = row,
		})
		UI.label({
			Text = `📖 {Format.number(entry.value)}`,
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -12, 0, 0),
			Size = UDim2.fromScale(0.3, 1),
			TextXAlignment = Enum.TextXAlignment.Right,
			TextColor3 = Theme.colors.gold,
			MaxTextSize = 22,
			Parent = row,
		})
	end
end

local function renderSecrets()
	local current = info
	if current == nil then
		header.Text = Locale.t("ui.loadingShort")
		return
	end
	header.Text = Locale.t("ui.weekEnds", { time = Format.time(current.weekEndsAt - State.serverNow()) })
	for index, secret in current.secrets do
		local row = makeRow(index, 76)
		UI.label({
			Text = (if secret.found then "✅ " else "🔮 ") .. secret.hint,
			Position = UDim2.fromOffset(12, 4),
			Size = UDim2.new(1, -24, 0, 40),
			TextXAlignment = Enum.TextXAlignment.Left,
			MaxTextSize = 22,
			Parent = row,
		})
		UI.label({
			Text = if secret.found
				then Locale.t("ui.secretFound")
				else Locale.t("ui.secretReward", { reward = "🪙 " .. Format.number(secret.reward) }),
			Position = UDim2.fromOffset(12, 44),
			Size = UDim2.new(1, -24, 0, 26),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = if secret.found then Theme.colors.good else Theme.colors.gold,
			Font = Theme.fontBody,
			MaxTextSize = 16,
			Parent = row,
		})
	end
end

local function render()
	local snapshot = State.snapshot
	if not snapshot or not isOpen then
		return
	end
	for tab, button in tabButtons do
		button.BackgroundColor3 = if tab == currentTab then Theme.colors.gold else Theme.colors.panelLight
	end
	UI.clearChildren(list)
	list.CanvasPosition = Vector2.zero
	if currentTab == "recipes" then
		renderRecipes(snapshot)
	elseif currentTab == "ranking" then
		renderRanking()
	else
		renderSecrets()
	end
end

-- Busca os dados extras do servidor (sem mostrar erro se falhar).
local function refreshInfo()
	task.spawn(function()
		local result = Net.invoke("GetGrimoireInfo")
		if result.ok then
			info = result.data
			render()
		end
	end)
end

local function refreshRanking()
	task.spawn(function()
		local result = Net.invoke("GetRanking")
		ranking = if result.ok then result.data else {}
		render()
	end)
end

local function selectTab(tab: Tab)
	currentTab = tab
	if tab == "ranking" then
		refreshRanking()
	elseif tab == "secrets" then
		refreshInfo()
	end
	render()
end

function GrimoireUI.mount(screen: ScreenGui)
	local content
	root, content = UI.panel(screen, "📖 " .. Locale.t("ui.grimoire"), function()
		Router.close()
	end)

	local tabsRow: Frame = UI.new("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 46),
		Parent = content,
	})
	UI.list(tabsRow, Enum.FillDirection.Horizontal, 8)
	local tabs: { { id: Tab, key: string } } = {
		{ id = "recipes", key = "ui.tabRecipes" },
		{ id = "ranking", key = "ui.tabRanking" },
		{ id = "secrets", key = "ui.tabSecrets" },
	}
	for order, tab in tabs do
		tabButtons[tab.id] = UI.button({
			Text = Locale.t(tab.key),
			LayoutOrder = order,
			Size = UDim2.new(1 / 3, -6, 1, 0),
			MaxTextSize = 20,
			Parent = tabsRow,
		}, function()
			selectTab(tab.id)
		end)
	end

	header = UI.label({
		Position = UDim2.fromOffset(0, 52),
		Size = UDim2.new(1, 0, 0, 26),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Theme.colors.textDim,
		MaxTextSize = 18,
		Parent = content,
	})

	list = UI.scroll({
		Position = UDim2.fromOffset(0, 82),
		Size = UDim2.new(1, 0, 1, -82),
		Parent = content,
	})
	UI.list(list, Enum.FillDirection.Vertical, 8)

	Router.register("Grimoire", {
		open = function()
			isOpen = true
			root.Visible = true
			refreshInfo()
			render()
		end,
		close = function()
			isOpen = false
			root.Visible = false
		end,
	})
	State.changed:Connect(function()
		if currentTab == "recipes" then
			render()
		end
	end)
end

return GrimoireUI
