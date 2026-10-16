--!strict
--[[
	RevealPopup.luau
	A revelação da poção ao coletar do caldeirão. É também o "cartão da poção"
	para print: mostra nome, efeito, valor, mutação, quem descobriu primeiro no
	mundo, quem criou e a data.

	O cartão tem tamanho fixo (440x400) e um UIScale que encolhe tudo para
	caber em telas pequenas de celular.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local Types = require(ReplicatedStorage.Shared.Types)
local Mutations = require(ReplicatedStorage.Shared.Config.Mutations)
local Locale = require(ReplicatedStorage.Shared.Locale)
local Format = require(ReplicatedStorage.Shared.Util.Format)
local Describe = require(ReplicatedStorage.Shared.Util.Describe)
local PlayerStats = require(ReplicatedStorage.Shared.Util.PlayerStats)
local UI = require(script.Parent.Components)
local Theme = require(script.Parent.Theme)
local Router = require(script.Parent.Router)
local Toast = require(script.Parent.Toast)
local State = require(script.Parent.Parent.State)
local Net = require(script.Parent.Parent.Net)

local CARD_SIZE = Vector2.new(440, 400)

local RevealPopup = {}

local overlay: Frame
local fitScale: UIScale
local popScale: UIScale
local cardStroke: UIStroke
local bottle: Frame
local mutationBadge: TextLabel
local newLabel: TextLabel
local nameLabel: TextLabel
local effectLabel: TextLabel
local valueLabel: TextLabel
local worldLabel: TextLabel
local footerLabel: TextLabel
local revealSound: Sound

local currentStackKey: string? = nil
local currentRecipeKey: string? = nil

local function hide()
	overlay.Visible = false
	currentStackKey = nil
	currentRecipeKey = nil
end

-- Atualiza a linha da Descoberta Mundial (muda quando o servidor confirma).
local function updateWorldLine()
	local snapshot = State.snapshot
	local key = currentRecipeKey
	local entry = if snapshot and key then snapshot.data.discovered[key] else nil
	if not entry then
		worldLabel.Text = ""
	elseif entry.first then
		worldLabel.Text = Locale.t("ui.worldFirstYou")
		worldLabel.TextColor3 = Theme.colors.gold
	elseif entry.by then
		worldLabel.Text = Locale.t("ui.worldFirstOther", { name = entry.by })
		worldLabel.TextColor3 = Theme.colors.text
	else
		worldLabel.Text = Locale.t("ui.worldPending")
		worldLabel.TextColor3 = Theme.colors.textDim
	end
end

local function fit()
	local size = overlay.AbsoluteSize
	if size.X > 0 and size.Y > 0 then
		fitScale.Scale = math.min(1, size.Y * 0.94 / CARD_SIZE.Y, size.X * 0.92 / CARD_SIZE.X)
	end
end

function RevealPopup.mount(screen: ScreenGui)
	overlay = UI.new("Frame", {
		Name = "Reveal",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.45,
		Visible = false,
		Active = true, -- bloqueia cliques no que está atrás
		Parent = screen,
	})

	-- holder = tamanho fixo + escala para caber; card = animação de "pulo".
	local holder: Frame = UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(CARD_SIZE.X, CARD_SIZE.Y),
		BackgroundTransparency = 1,
		Parent = overlay,
	})
	fitScale = UI.new("UIScale", { Parent = holder })
	overlay:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
	fit()

	local card: Frame = UI.new("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Theme.colors.panel,
		Parent = holder,
	})
	UI.corner(card, 22)
	cardStroke = UI.new("UIStroke", { Color = Theme.colors.gold, Thickness = 4, Parent = card })
	popScale = UI.new("UIScale", { Parent = card })

	newLabel = UI.label({
		Text = Locale.t("ui.newRecipe"),
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 8),
		Size = UDim2.new(0.8, 0, 0, 34),
		TextColor3 = Theme.colors.gold,
		MaxTextSize = 32,
		Parent = card,
	})

	-- TODO(asset): trocar o círculo por um ícone/modelo 3D de frasco.
	bottle = UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 46),
		Size = UDim2.fromOffset(96, 96),
		Parent = card,
	})
	UI.corner(bottle, 48)
	UI.stroke(bottle, Color3.new(1, 1, 1), 4)

	mutationBadge = UI.label({
		Position = UDim2.new(0.5, 56, 0, 60),
		Size = UDim2.fromOffset(140, 32),
		TextColor3 = Theme.colors.stroke,
		BackgroundTransparency = 0,
		Rotation = 8,
		MaxTextSize = 20,
		Visible = false,
		Parent = card,
	})
	UI.corner(mutationBadge, 12)
	UI.stroke(mutationBadge, Theme.colors.stroke, 2)

	nameLabel = UI.label({
		Position = UDim2.fromOffset(12, 148),
		Size = UDim2.new(1, -24, 0, 38),
		MaxTextSize = 30,
		Parent = card,
	})
	effectLabel = UI.label({
		Position = UDim2.fromOffset(12, 188),
		Size = UDim2.new(1, -24, 0, 26),
		TextColor3 = Theme.colors.textDim,
		Font = Theme.fontBody,
		MaxTextSize = 20,
		Parent = card,
	})
	valueLabel = UI.label({
		Position = UDim2.fromOffset(12, 216),
		Size = UDim2.new(1, -24, 0, 24),
		TextColor3 = Theme.colors.gold,
		MaxTextSize = 20,
		Parent = card,
	})
	worldLabel = UI.label({
		Position = UDim2.fromOffset(12, 244),
		Size = UDim2.new(1, -24, 0, 24),
		MaxTextSize = 19,
		Parent = card,
	})
	footerLabel = UI.label({
		Position = UDim2.fromOffset(12, 272),
		Size = UDim2.new(1, -24, 0, 20),
		TextColor3 = Theme.colors.textDim,
		Font = Theme.fontBody,
		MaxTextSize = 15,
		Parent = card,
	})

	UI.button({
		Text = Locale.t("ui.drink"),
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 12, 1, -12),
		Size = UDim2.new(0.5, -18, 0, Theme.buttonHeight),
		BackgroundColor3 = Theme.colors.good,
		Parent = card,
	}, function()
		local stackKey = currentStackKey
		if not stackKey then
			return
		end
		hide()
		local result = Net.request("DrinkPotion", stackKey)
		if result.ok then
			Toast.show(Locale.t("ui.drank", { name = result.data.name }), "good")
			Router.close()
		end
	end)
	UI.button({
		Text = Locale.t("ui.keep"),
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -12, 1, -12),
		Size = UDim2.new(0.5, -18, 0, Theme.buttonHeight),
		Parent = card,
	}, hide)

	-- TODO(asset): som final de revelação (este é um som interno do Roblox).
	revealSound = UI.new("Sound", {
		SoundId = "rbxasset://sounds/electronicpingshort.wav",
		Volume = 0.8,
		Parent = overlay,
	})

	State.changed:Connect(function()
		if overlay.Visible then
			updateWorldLine()
		end
	end)
end

function RevealPopup.show(recipe: Types.RecipeInfo, isNew: boolean, stackKey: string, mutationId: string?)
	currentStackKey = stackKey
	currentRecipeKey = recipe.key
	local mutation = if mutationId then Mutations.byId[mutationId] else nil

	bottle.BackgroundColor3 = recipe.color
	nameLabel.Text = recipe.name
	effectLabel.Text = Describe.effect(recipe.effect)

	local snapshot = State.snapshot
	local base = recipe.value * Mutations.priceMultiplier(mutationId)
	local price = if snapshot then PlayerStats.sellPrice(snapshot.data, base) else base
	valueLabel.Text = Locale.t("ui.value", { value = "🪙 " .. Format.number(price) })

	if mutation then
		mutationBadge.Visible = true
		mutationBadge.Text = "✨ " .. Locale.name("mutation", mutation.id, mutation.name)
		mutationBadge.BackgroundColor3 = mutation.color
		cardStroke.Color = mutation.color
	else
		mutationBadge.Visible = false
		cardStroke.Color = Theme.colors.gold
	end

	footerLabel.Text = Locale.t("ui.createdBy", {
		name = Players.LocalPlayer.DisplayName,
		date = os.date("%d/%m/%Y"),
	})
	newLabel.Visible = isNew
	updateWorldLine()
	overlay.Visible = true

	-- Animação: o cartão "pula" e o frasco gira.
	popScale.Scale = 0.2
	TweenService:Create(popScale, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 })
		:Play()
	bottle.Rotation = -25
	TweenService
		:Create(bottle, TweenInfo.new(0.6, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), { Rotation = 0 })
		:Play()
	if isNew then
		newLabel.TextTransparency = 1
		TweenService:Create(newLabel, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 3, true), {
			TextTransparency = 0,
		}):Play()
	end

	-- Som mais agudo para receita nova; mais ainda para mutação.
	revealSound.PlaybackSpeed = if mutation then 1.5 elseif isNew then 1.25 else 1
	SoundService:PlayLocalSound(revealSound)
end

return RevealPopup
