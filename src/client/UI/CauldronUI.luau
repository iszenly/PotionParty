--!strict
--[[
	CauldronUI.luau
	Tela do caldeirão:
		- abas no topo: um botão por caldeirão (com status);
		- esquerda: ingredientes que o jogador tem (toque para adicionar);
		- direita: os 3 espaços da mistura, tempo de preparo e botões.

	O cliente só MOSTRA a estimativa de tempo; quem decide é o servidor.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Types = require(ReplicatedStorage.Shared.Types)
local Economy = require(ReplicatedStorage.Shared.Config.Economy)
local Ingredients = require(ReplicatedStorage.Shared.Config.Ingredients)
local Rarities = require(ReplicatedStorage.Shared.Config.Rarities)
local Locale = require(ReplicatedStorage.Shared.Locale)
local Format = require(ReplicatedStorage.Shared.Util.Format)
local PlayerStats = require(ReplicatedStorage.Shared.Util.PlayerStats)
local RecipeKey = require(ReplicatedStorage.Shared.Util.RecipeKey)
local UI = require(script.Parent.Components)
local Theme = require(script.Parent.Theme)
local Router = require(script.Parent.Router)
local Toast = require(script.Parent.Toast)
local RevealPopup = require(script.Parent.RevealPopup)
local State = require(script.Parent.Parent.State)
local Net = require(script.Parent.Parent.Net)

local CauldronUI = {}

local root: Frame
local tabs: ScrollingFrame
local grid: ScrollingFrame
local slotsRow: Frame
local infoLabel: TextLabel
local progressBack: Frame
local progressFill: Frame
local brewButton: TextButton
local clearButton: TextButton
local collectButton: TextButton
local tabButtons: { TextButton } = {}

local isOpen = false
local busy = false -- evita pedir duas vezes enquanto espera o servidor
local selectedCauldron = 1
local selected: { string } = {}

local function ingredientName(id: string): string
	local def = Ingredients.byId[id]
	return Locale.name("ingredient", id, if def then def.name else id)
end

local function getData(): Types.PlayerData?
	local snapshot = State.snapshot
	return if snapshot then snapshot.data else nil
end

local function selectedCount(id: string): number
	local count = 0
	for _, selectedId in selected do
		if selectedId == id then
			count += 1
		end
	end
	return count
end

local function tabStatus(data: Types.PlayerData, index: number): string
	local brew = data.cauldrons[tostring(index)]
	if brew == nil then
		return Locale.t("ui.free")
	end
	local left = brew.finishAt - State.serverNow()
	return if left <= 0 then Locale.t("ui.ready") else Format.time(left)
end

-- Atualiza só textos/barra (chamado várias vezes por segundo).
local function updateStatus()
	local data = getData()
	if not data then
		return
	end

	for index, button in tabButtons do
		button.Text = `{Locale.t("ui.cauldronN", { n = index })}\n{tabStatus(data, index)}`
	end

	local brew = data.cauldrons[tostring(selectedCauldron)]
	local now = State.serverNow()
	if brew == nil then
		progressBack.Visible = false
		collectButton.Visible = false
		brewButton.Visible = true
		clearButton.Visible = true
		brewButton.BackgroundColor3 = if #selected > 0 then Theme.colors.good else Theme.colors.disabled
		if #selected > 0 then
			infoLabel.Text = Locale.t("ui.brewTime", { time = Format.time(PlayerStats.brewSeconds(data, selected)) })
		else
			infoLabel.Text = Locale.t("ui.pickIngredients")
		end
	elseif now < brew.finishAt then
		progressBack.Visible = true
		collectButton.Visible = false
		brewButton.Visible = false
		clearButton.Visible = false
		local total = math.max(1, brew.finishAt - brew.startedAt)
		progressFill.Size = UDim2.fromScale(math.clamp((now - brew.startedAt) / total, 0, 1), 1)
		infoLabel.Text = Locale.t("ui.brewing", { time = Format.time(brew.finishAt - now) })
	else
		progressBack.Visible = false
		collectButton.Visible = true
		brewButton.Visible = false
		clearButton.Visible = false
		infoLabel.Text = Locale.t("ui.ready")
	end
end

local render: () -> ()

local function addIngredient(id: string)
	local data = getData()
	if not data or data.cauldrons[tostring(selectedCauldron)] then
		return
	end
	if #selected >= Economy.maxIngredientsPerBrew then
		return
	end
	if (data.ingredients[id] or 0) - selectedCount(id) <= 0 then
		return
	end
	table.insert(selected, id)
	render()
end

local function renderTabs(data: Types.PlayerData)
	UI.clearChildren(tabs)
	table.clear(tabButtons)
	for index = 1, PlayerStats.visibleCauldronCount(data) do
		local button = UI.button({
			LayoutOrder = index,
			Size = UDim2.new(0, 150, 1, -6),
			BackgroundColor3 = if index == selectedCauldron then Theme.colors.gold else Theme.colors.panelLight,
			MaxTextSize = 18,
			Parent = tabs,
		}, function()
			selectedCauldron = index
			table.clear(selected)
			render()
		end)
		tabButtons[index] = button
	end
end

local function renderGrid(data: Types.PlayerData)
	UI.clearChildren(grid)
	for order, def in Ingredients.list do
		if data.unlocked[def.id] or (data.ingredients[def.id] or 0) > 0 then
			local available = (data.ingredients[def.id] or 0) - selectedCount(def.id)
			local tile = UI.button({
				LayoutOrder = order,
				Text = "",
				BackgroundColor3 = if available > 0 then Theme.colors.panelLight else Theme.colors.disabled,
				Parent = grid,
			}, function()
				addIngredient(def.id)
			end)
			-- TODO(asset): ícone do ingrediente no lugar da bolinha colorida.
			local dot: Frame = UI.new("Frame", {
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.fromScale(0.5, 0.06),
				Size = UDim2.fromOffset(38, 38),
				BackgroundColor3 = def.color,
				Parent = tile,
			})
			UI.corner(dot, 19)
			UI.stroke(dot, Rarities[def.rarity].color, 3)
			UI.label({
				Text = ingredientName(def.id),
				Position = UDim2.fromScale(0, 0.5),
				Size = UDim2.fromScale(1, 0.26),
				MaxTextSize = 16,
				Parent = tile,
			})
			UI.label({
				Text = "x" .. available,
				Position = UDim2.fromScale(0, 0.76),
				Size = UDim2.fromScale(1, 0.22),
				TextColor3 = Theme.colors.gold,
				MaxTextSize = 16,
				Parent = tile,
			})
		end
	end
end

local function renderSlots(data: Types.PlayerData)
	UI.clearChildren(slotsRow)
	local brew = data.cauldrons[tostring(selectedCauldron)]
	local ids = if brew then RecipeKey.toIds(brew.key) else selected
	for index = 1, Economy.maxIngredientsPerBrew do
		local id = ids[index]
		local def = if id then Ingredients.byId[id] else nil
		UI.button({
			LayoutOrder = index,
			Text = if def then ingredientName(def.id) else "+",
			Size = UDim2.fromOffset(62, 62),
			BackgroundColor3 = if def then def.color else Theme.colors.panelLight,
			TextStrokeTransparency = 0.3,
			MaxTextSize = 16,
			Parent = slotsRow,
		}, function()
			-- Toque num espaço preenchido para tirar o ingrediente.
			if not brew and selected[index] then
				table.remove(selected, index)
				render()
			end
		end)
	end
end

render = function()
	local data = getData()
	if not data or not isOpen then
		return
	end
	if selectedCauldron > PlayerStats.visibleCauldronCount(data) then
		selectedCauldron = 1
	end
	-- Se os ingredientes mudaram (ex.: acabou de preparar), corrige a seleção.
	for index = #selected, 1, -1 do
		local id = selected[index]
		if selectedCount(id) > (data.ingredients[id] or 0) then
			table.remove(selected, index)
		end
	end
	renderTabs(data)
	renderGrid(data)
	renderSlots(data)
	updateStatus()
end

local function brew()
	if busy or #selected == 0 then
		return
	end
	busy = true
	local result = Net.request("StartBrew", selectedCauldron, table.clone(selected))
	busy = false
	if result.ok then
		table.clear(selected)
		Toast.show(Locale.t("ui.brewStarted", { time = Format.time(result.data.seconds) }), "good")
		render()
	end
end

local function collect()
	if busy then
		return
	end
	busy = true
	local result = Net.request("CollectBrew", selectedCauldron)
	busy = false
	if result.ok then
		RevealPopup.show(result.data.recipe, result.data.isNew, result.data.stackKey, result.data.mutation)
	end
end

function CauldronUI.mount(screen: ScreenGui)
	local content
	root, content = UI.panel(screen, "🧪 " .. Locale.t("ui.cauldron"), function()
		Router.close()
	end)

	tabs = UI.scroll({
		Size = UDim2.new(1, 0, 0, 46),
		ScrollingDirection = Enum.ScrollingDirection.X,
		AutomaticCanvasSize = Enum.AutomaticSize.X,
		ScrollBarThickness = 4,
		Parent = content,
	})
	UI.list(tabs, Enum.FillDirection.Horizontal, 8)

	local body: Frame = UI.new("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, 52),
		Size = UDim2.new(1, 0, 1, -52),
		Parent = content,
	})

	grid = UI.scroll({ Size = UDim2.new(0.55, -6, 1, 0), Parent = body })
	UI.new("UIGridLayout", {
		CellSize = UDim2.fromOffset(84, 92),
		CellPadding = UDim2.fromOffset(8, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = grid,
	})
	UI.padding(grid, 4)

	local side: Frame = UI.new("Frame", {
		Position = UDim2.new(0.55, 6, 0, 0),
		Size = UDim2.new(0.45, -6, 1, 0),
		BackgroundColor3 = Theme.colors.background,
		BackgroundTransparency = 0.3,
		Parent = body,
	})
	UI.corner(side)

	slotsRow = UI.new("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, 6),
		Size = UDim2.new(1, 0, 0, 62),
		Parent = side,
	})
	UI.list(slotsRow, Enum.FillDirection.Horizontal, 8, Enum.HorizontalAlignment.Center)

	infoLabel = UI.label({
		Position = UDim2.fromOffset(8, 72),
		Size = UDim2.new(1, -16, 0, 26),
		MaxTextSize = 20,
		Parent = side,
	})

	progressBack = UI.new("Frame", {
		Position = UDim2.fromOffset(12, 104),
		Size = UDim2.new(1, -24, 0, 16),
		BackgroundColor3 = Theme.colors.stroke,
		Visible = false,
		Parent = side,
	})
	UI.corner(progressBack, 8)
	progressFill = UI.new("Frame", {
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = Theme.colors.good,
		Parent = progressBack,
	})
	UI.corner(progressFill, 8)

	brewButton = UI.button({
		Text = Locale.t("ui.brew"),
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 8, 1, -8),
		Size = UDim2.new(0.62, -12, 0, 48),
		BackgroundColor3 = Theme.colors.good,
		Parent = side,
	}, brew)
	clearButton = UI.button({
		Text = Locale.t("ui.clear"),
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -8, 1, -8),
		Size = UDim2.new(0.38, -8, 0, 48),
		Parent = side,
	}, function()
		table.clear(selected)
		render()
	end)
	collectButton = UI.button({
		Text = Locale.t("ui.collect"),
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -8),
		Size = UDim2.new(1, -16, 0, 48),
		BackgroundColor3 = Theme.colors.gold,
		Visible = false,
		Parent = side,
	}, collect)

	Router.register("Cauldron", {
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

	State.changed:Connect(function()
		render()
	end)

	-- Atualiza os timers 5x por segundo enquanto a tela está aberta.
	local elapsed = 0
	RunService.Heartbeat:Connect(function(dt)
		if not isOpen then
			return
		end
		elapsed += dt
		if elapsed >= 0.2 then
			elapsed = 0
			-- Se um caldeirão acabou de ficar pronto, redesenha os slots/botões.
			updateStatus()
		end
	end)
end

return CauldronUI
