--!strict
--[[
	TradeUI.luau
	Tela de troca:
		[ Seus itens ]  [ Sua oferta ]  [ Oferta do outro ]
		toque num item seu para oferecer +1; toque na sua oferta para tirar 1.
	Embaixo: valores estimados, "Pronto!" e "Confirmar" (com contagem).
	Também mostra o convite de troca ("Fulano quer trocar com você").

	O cliente só PEDE; o servidor guarda a oferta de verdade e confere tudo.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Shared.Types)
local Social = require(ReplicatedStorage.Shared.Config.Social)
local Ingredients = require(ReplicatedStorage.Shared.Config.Ingredients)
local Mutations = require(ReplicatedStorage.Shared.Config.Mutations)
local Locale = require(ReplicatedStorage.Shared.Locale)
local Format = require(ReplicatedStorage.Shared.Util.Format)
local RecipeKey = require(ReplicatedStorage.Shared.Util.RecipeKey)
local UI = require(script.Parent.Components)
local Theme = require(script.Parent.Theme)
local Toast = require(script.Parent.Toast)
local Router = require(script.Parent.Router)
local Page = require(script.Parent.Page)
local State = require(script.Parent.Parent.State)
local Net = require(script.Parent.Parent.Net)

type Offer = Types.TradeOffer
type Kind = "potions" | "ingredients"

local TradeUI = {}

local page: Page.Page
local valueLabel: TextLabel
local columns: { ScrollingFrame } = {}
local headers: { TextLabel } = {}
local readyButton: TextButton
local confirmButton: TextButton

local popup: Frame
local popupLabel: TextLabel
local pendingFrom: number? = nil

local view: Types.TradeView? = nil
local localOffer: Offer = { potions = {}, ingredients = {} }
local sendScheduled = false

local function copyOffer(offer: Offer): Offer
	return { potions = table.clone(offer.potions), ingredients = table.clone(offer.ingredients) }
end

local function stackCount(offer: Offer): number
	local total = 0
	for _ in offer.potions do
		total += 1
	end
	for _ in offer.ingredients do
		total += 1
	end
	return total
end

local function potionName(stackKey: string, recipes: { [string]: Types.RecipeInfo }): (string, Color3)
	local recipeKey, mutationId = RecipeKey.splitStack(stackKey)
	local info = recipes[recipeKey]
	local mutation = if mutationId then Mutations.byId[mutationId] else nil
	local name = (if info then info.name else "?") .. (if mutation then ` ✨{mutation.name}` else "")
	return name, if info then info.color else Theme.colors.disabled
end

local function ingredientName(id: string): (string, Color3)
	local def = Ingredients.byId[id]
	return Locale.name("ingredient", id, if def then def.name else id), if def then def.color else Theme.colors.disabled
end

local render: () -> ()

-- Envia a oferta local (agrupando toques rápidos em um só envio).
local function scheduleSend()
	if sendScheduled then
		return
	end
	sendScheduled = true
	task.delay(0.25, function()
		sendScheduled = false
		Net.request("TradeSetOffer", localOffer)
	end)
end

local function itemButton(parent: Instance, order: number, text: string, color: Color3, onClick: (() -> ())?)
	local button = UI.button({
		Text = text,
		LayoutOrder = order,
		Size = UDim2.new(1, -8, 0, 40),
		BackgroundColor3 = Theme.colors.panelLight,
		TextXAlignment = Enum.TextXAlignment.Left,
		MaxTextSize = 15,
		AutoButtonColor = onClick ~= nil,
		Parent = parent,
	}, onClick or function() end)
	local swatch: Frame = UI.new("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -4, 0.5, 0),
		Size = UDim2.fromOffset(16, 16),
		BackgroundColor3 = color,
		Parent = button,
	})
	UI.corner(swatch, 8)
end

local function adjust(kind: Kind, key: string, delta: number)
	local current = view
	local snapshot = State.snapshot
	if not current or not snapshot or current.myReady then
		return
	end
	local bucket = localOffer[kind]
	local owned = if kind == "potions" then snapshot.data.potions[key] or 0 else snapshot.data.ingredients[key] or 0
	local nextCount = (bucket[key] or 0) + delta
	if
		delta > 0 and (nextCount > owned or (bucket[key] == nil and stackCount(localOffer) >= Social.tradeMaxStacks))
	then
		return
	end
	if nextCount <= 0 then
		(bucket :: any)[key] = nil
	else
		bucket[key] = nextCount
	end
	scheduleSend()
	render()
end

local function renderOffer(
	column: ScrollingFrame,
	offer: Offer,
	recipes: { [string]: Types.RecipeInfo },
	removable: boolean
)
	local order = 0
	for stackKey, count in offer.potions do
		order += 1
		local name, color = potionName(stackKey, recipes)
		itemButton(
			column,
			order,
			`{name} x{count}`,
			color,
			if removable
				then function()
					adjust("potions", stackKey, -1)
				end
				else nil
		)
	end
	for id, count in offer.ingredients do
		order += 1
		local name, color = ingredientName(id)
		itemButton(
			column,
			order,
			`{name} x{count}`,
			color,
			if removable
				then function()
					adjust("ingredients", id, -1)
				end
				else nil
		)
	end
end

render = function()
	local current = view
	local snapshot = State.snapshot
	if not current or not snapshot or not page.isOpen() then
		return
	end
	page.title.Text = "🤝 " .. Locale.t("ui.tradeTitle", { name = current.partnerName })
	headers[3].Text = Locale.t("ui.theirOffer", { name = current.partnerName })
	valueLabel.Text = Locale.t("ui.tradeValue", {
		mine = Format.number(current.myValue),
		theirs = Format.number(current.theirValue),
	})

	for _, column in columns do
		UI.clearChildren(column)
	end

	-- Coluna 1: meus itens (o que ainda não está na oferta)
	local order = 0
	for stackKey, count in snapshot.data.potions do
		local available = count - (localOffer.potions[stackKey] or 0)
		if available > 0 then
			order += 1
			local name, color = potionName(stackKey, snapshot.recipes)
			itemButton(columns[1], order, `{name} x{available}`, color, function()
				adjust("potions", stackKey, 1)
			end)
		end
	end
	for _, def in Ingredients.list do
		local available = (snapshot.data.ingredients[def.id] or 0) - (localOffer.ingredients[def.id] or 0)
		if available > 0 then
			order += 1
			local name, color = ingredientName(def.id)
			itemButton(columns[1], order, `{name} x{available}`, color, function()
				adjust("ingredients", def.id, 1)
			end)
		end
	end

	-- Coluna 2 e 3: as ofertas
	local myRecipes = table.clone(snapshot.recipes)
	for key, info in current.recipes do
		myRecipes[key] = info
	end
	renderOffer(columns[2], localOffer, myRecipes, not current.myReady)
	renderOffer(columns[3], current.theirs, current.recipes, false)

	-- Botões
	readyButton.Text = if current.myReady then Locale.t("ui.tradeUnready") else Locale.t("ui.tradeReady")
	readyButton.BackgroundColor3 = if current.myReady then Theme.colors.panelLight else Theme.colors.good
	headers[2].TextColor3 = if current.myReady then Theme.colors.good else Theme.colors.text
	headers[3].TextColor3 = if current.theirReady then Theme.colors.good else Theme.colors.text
	confirmButton.Visible = current.myReady and current.theirReady
end

-- Atualiza o texto do botão Confirmar (contagem regressiva).
local function updateConfirm()
	local current = view
	if not current or not page.isOpen() or not confirmButton.Visible then
		return
	end
	if current.myConfirmed then
		confirmButton.Text = Locale.t("ui.tradeWaiting", { name = current.partnerName })
		confirmButton.BackgroundColor3 = Theme.colors.disabled
		return
	end
	local left = if current.confirmAt then math.ceil(current.confirmAt - State.serverNow()) else 0
	if left > 0 then
		confirmButton.Text = Locale.t("ui.tradeConfirmIn", { n = left })
		confirmButton.BackgroundColor3 = Theme.colors.disabled
	else
		confirmButton.Text = Locale.t("ui.tradeConfirm")
		confirmButton.BackgroundColor3 = Theme.colors.gold
	end
end

local function showPopup(name: string, fromUserId: number)
	pendingFrom = fromUserId
	popupLabel.Text = Locale.t("ui.tradeRequest", { name = name })
	popup.Visible = true
	task.delay(Social.tradeRequestTimeout, function()
		if pendingFrom == fromUserId then
			pendingFrom = nil
			popup.Visible = false
		end
	end)
end

local function respond(accept: boolean)
	local from = pendingFrom
	pendingFrom = nil
	popup.Visible = false
	if from then
		Net.request("TradeRespond", from, accept)
	end
end

function TradeUI.mount(screen: ScreenGui, overlay: ScreenGui)
	page = Page.create(screen, "Trade", "🤝", function()
		render()
	end, function()
		if view then
			Net.request("TradeCancel")
		end
	end)

	valueLabel = UI.label({
		Size = UDim2.new(1, 0, 0, 22),
		TextColor3 = Theme.colors.gold,
		MaxTextSize = 18,
		Parent = page.content,
	})
	local titles = { Locale.t("ui.yourItems"), Locale.t("ui.yourOffer"), "" }
	for i = 1, 3 do
		headers[i] = UI.label({
			Text = titles[i],
			Position = UDim2.new((i - 1) / 3, 4, 0, 26),
			Size = UDim2.new(1 / 3, -8, 0, 22),
			MaxTextSize = 17,
			Parent = page.content,
		})
		local column = UI.scroll({
			Position = UDim2.new((i - 1) / 3, 4, 0, 50),
			Size = UDim2.new(1 / 3, -8, 1, -50 - 58),
			BackgroundTransparency = 0.6,
			BackgroundColor3 = Theme.colors.background,
			Parent = page.content,
		})
		UI.corner(column)
		UI.padding(column, 4)
		UI.list(column, Enum.FillDirection.Vertical, 4)
		columns[i] = column
	end

	readyButton = UI.button({
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(0.33, -6, 0, 52),
		Parent = page.content,
	}, function()
		local current = view
		if current then
			Net.request("TradeSetReady", not current.myReady)
		end
	end)
	confirmButton = UI.button({
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(0.5, 1),
		Size = UDim2.new(0.33, -6, 0, 52),
		Visible = false,
		Parent = page.content,
	}, function()
		Net.request("TradeConfirm")
	end)
	UI.button({
		Text = Locale.t("ui.cancel"),
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.fromScale(1, 1),
		Size = UDim2.new(0.33, -6, 0, 52),
		BackgroundColor3 = Theme.colors.bad,
		Parent = page.content,
	}, function()
		Net.request("TradeCancel")
	end)

	-- Convite de troca (canto de cima, por cima de tudo)
	popup = UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 120),
		Size = UDim2.fromOffset(380, 120),
		BackgroundColor3 = Theme.colors.panel,
		Visible = false,
		Parent = overlay,
	})
	UI.corner(popup, 16)
	UI.stroke(popup, Theme.colors.gold, 3)
	popupLabel = UI.label({
		Position = UDim2.fromOffset(10, 6),
		Size = UDim2.new(1, -20, 0, 44),
		MaxTextSize = 22,
		Parent = popup,
	})
	UI.button({
		Text = Locale.t("ui.accept"),
		Position = UDim2.new(0, 10, 1, -62),
		Size = UDim2.new(0.5, -15, 0, 52),
		BackgroundColor3 = Theme.colors.good,
		Parent = popup,
	}, function()
		respond(true)
	end)
	UI.button({
		Text = Locale.t("ui.decline"),
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -10, 1, -62),
		Size = UDim2.new(0.5, -15, 0, 52),
		BackgroundColor3 = Theme.colors.bad,
		Parent = popup,
	}, function()
		respond(false)
	end)

	Net.on("Trade", function(message: any)
		if type(message) ~= "table" then
			return
		end
		if message.kind == "state" then
			view = message.view
			-- Se não há envio pendente, a oferta oficial é a do servidor.
			if not sendScheduled and view then
				localOffer = copyOffer(view.mine)
			end
			if Router.current() ~= "Trade" then
				Router.open("Trade")
			end
			render()
			updateConfirm()
		elseif message.kind == "closed" or message.kind == "completed" then
			view = nil
			localOffer = { potions = {}, ingredients = {} }
			if message.kind == "completed" then
				Toast.show(Locale.t("ui.tradeDone"), "good")
			else
				Toast.show(Locale.t(message.reason or "error.tradeCancelled"), "bad")
			end
			if Router.current() == "Trade" then
				Router.close()
			end
		elseif message.kind == "request" then
			showPopup(message.fromName, message.fromUserId)
		elseif message.kind == "declined" then
			Toast.show(Locale.t("ui.tradeDeclined", { name = message.name }), "info")
		end
	end)

	State.changed:Connect(function()
		render()
	end)
	task.spawn(function()
		while true do
			task.wait(0.25)
			updateConfirm()
		end
	end)
end

return TradeUI
