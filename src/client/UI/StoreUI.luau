--!strict
--[[
	StoreUI.luau
	Loja VIP (Robux). O cliente só ABRE a janela de compra do Roblox;
	quem entrega o item é o servidor (MonetizationService).
	Itens com id = 0 em Monetization.luau aparecem como "Em breve".
]]

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Monetization = require(ReplicatedStorage.Shared.Config.Monetization)
local Locale = require(ReplicatedStorage.Shared.Locale)
local UI = require(script.Parent.Components)
local Theme = require(script.Parent.Theme)
local Toast = require(script.Parent.Toast)
local Page = require(script.Parent.Page)
local State = require(script.Parent.Parent.State)

local StoreUI = {}

local page: Page.Page
local list: ScrollingFrame

local function section(order: number, text: string)
	UI.label({
		Text = text,
		LayoutOrder = order,
		Size = UDim2.new(1, -10, 0, 30),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Theme.colors.gold,
		MaxTextSize = 22,
		Parent = list,
	})
end

local function itemRow(order: number, icon: string, name: string, description: string): Frame
	local row = Page.row(list, order, 70)
	UI.label({
		Text = `{icon} {name}`,
		Position = UDim2.fromOffset(12, 4),
		Size = UDim2.new(1, -180, 0, 32),
		TextXAlignment = Enum.TextXAlignment.Left,
		MaxTextSize = 22,
		Parent = row,
	})
	UI.label({
		Text = description,
		Position = UDim2.fromOffset(12, 36),
		Size = UDim2.new(1, -180, 0, 28),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Theme.colors.textDim,
		Font = Theme.fontBody,
		MaxTextSize = 15,
		Parent = row,
	})
	return row
end

local function buyButton(row: Frame, text: string, color: Color3, onClick: () -> ())
	UI.button({
		Text = text,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		Size = UDim2.fromOffset(150, 54),
		BackgroundColor3 = color,
		MaxTextSize = 20,
		Parent = row,
	}, onClick)
end

local function render()
	local snapshot = State.snapshot
	if not snapshot or not page.isOpen() then
		return
	end
	local data = snapshot.data
	UI.clearChildren(list)
	local order = 0
	local function nextOrder(): number
		order += 1
		return order
	end

	section(nextOrder(), Locale.t("ui.storePasses"))
	for _, pass in Monetization.passes do
		local row = itemRow(nextOrder(), pass.icon, pass.name, pass.description)
		if data.passes[pass.key] then
			buyButton(row, Locale.t("ui.storeOwned"), Theme.colors.disabled, function() end)
		elseif pass.id == 0 then
			buyButton(row, Locale.t("ui.storeSoon"), Theme.colors.disabled, function()
				Toast.show(Locale.t("ui.storeNotConfigured"), "info")
			end)
		else
			buyButton(row, Locale.t("ui.storeBuy"), Theme.colors.good, function()
				MarketplaceService:PromptGamePassPurchase(Players.LocalPlayer, pass.id)
			end)
		end
	end

	section(nextOrder(), Locale.t("ui.storeProducts"))
	for _, product in Monetization.products do
		local row = itemRow(nextOrder(), product.icon, product.name, product.description)
		local cosmetic = product.grant.cosmetic
		if cosmetic and data.cosmetics.owned[cosmetic] then
			buyButton(row, Locale.t("ui.storeOwned"), Theme.colors.disabled, function() end)
		elseif product.id == 0 then
			buyButton(row, Locale.t("ui.storeSoon"), Theme.colors.disabled, function()
				Toast.show(Locale.t("ui.storeNotConfigured"), "info")
			end)
		else
			buyButton(row, Locale.t("ui.storeBuy"), Theme.colors.good, function()
				-- Não deixa comprar "Acelerar" sem nada no caldeirão.
				if product.grant.finishBrews and next(data.cauldrons) == nil then
					Toast.show(Locale.t("ui.storeNoBrews"), "info")
					return
				end
				MarketplaceService:PromptProductPurchase(Players.LocalPlayer, product.id)
			end)
		end
	end
end

function StoreUI.mount(screen: ScreenGui)
	page = Page.create(screen, "Store", "💎 " .. Locale.t("ui.store"), render)
	list = Page.list(page.content, 0)
	State.changed:Connect(render)
end

return StoreUI
