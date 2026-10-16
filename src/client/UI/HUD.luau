--!strict
--[[
	HUD.luau
	Elementos sempre visíveis: moedas, efeito ativo e botões principais.
	O Caldeirão e o Mercado abrem pelas estações do mapa (ProximityPrompt).
]]

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Weather = require(ReplicatedStorage.Shared.Config.Weather)
local Social = require(ReplicatedStorage.Shared.Config.Social)
local Locale = require(ReplicatedStorage.Shared.Locale)
local Format = require(ReplicatedStorage.Shared.Util.Format)
local UI = require(script.Parent.Components)
local Theme = require(script.Parent.Theme)
local Router = require(script.Parent.Router)
local State = require(script.Parent.Parent.State)
local DailyUI = require(script.Parent.DailyUI)
local MissionsUI = require(script.Parent.MissionsUI)
local ShopUI = require(script.Parent.ShopUI)

local HUD = {}

function HUD.mount(screen: ScreenGui)
	-- Moedas (canto superior esquerdo)
	local coinsFrame: Frame = UI.new("Frame", {
		Name = "Coins",
		Position = UDim2.fromOffset(12, 8),
		Size = UDim2.fromOffset(190, 50),
		BackgroundColor3 = Theme.colors.panel,
		Parent = screen,
	})
	UI.corner(coinsFrame, 25)
	UI.stroke(coinsFrame, Theme.colors.stroke, 3)
	-- TODO(asset): trocar o emoji por um ícone de moeda.
	local coinsLabel = UI.label({
		Text = "🪙 …",
		Size = UDim2.new(1, -20, 1, -8),
		Position = UDim2.fromOffset(10, 4),
		TextColor3 = Theme.colors.gold,
		MaxTextSize = 28,
		Parent = coinsFrame,
	})

	-- Efeito ativo (centro, no topo)
	local effectLabel = UI.label({
		Name = "Effect",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 8),
		Size = UDim2.fromOffset(340, 40),
		BackgroundColor3 = Theme.colors.button,
		BackgroundTransparency = 0.15,
		Visible = false,
		MaxTextSize = 22,
		Parent = screen,
	})
	UI.corner(effectLabel, 20)

	-- "Fichinhas" de status embaixo das moedas: clima e cometa.
	local function chip(order: number, color: Color3): TextLabel
		local label = UI.label({
			Position = UDim2.fromOffset(12, 62 + (order - 1) * 40),
			Size = UDim2.fromOffset(220, 34),
			BackgroundColor3 = color,
			BackgroundTransparency = 0.15,
			Visible = false,
			MaxTextSize = 18,
			Parent = screen,
		})
		UI.corner(label, 17)
		return label
	end
	local weatherChip = chip(1, Color3.fromRGB(60, 110, 190))
	local cometChip = chip(2, Color3.fromRGB(140, 80, 210))

	-- Botões grandes (lado direito)
	local BUTTON_HEIGHT = 56
	local buttons: Frame = UI.new("Frame", {
		Name = "Buttons",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.45, 0),
		Size = UDim2.fromOffset(130, 4 * BUTTON_HEIGHT + 3 * 8),
		BackgroundTransparency = 1,
		Parent = screen,
	})
	UI.list(buttons, Enum.FillDirection.Vertical, 8, Enum.HorizontalAlignment.Right)
	UI.button({
		Text = "🧪 " .. Locale.t("ui.potions"),
		LayoutOrder = 1,
		Size = UDim2.fromOffset(130, BUTTON_HEIGHT),
		Parent = buttons,
	}, function()
		Router.toggle("Inventory")
	end)
	UI.button({
		Text = "📖 " .. Locale.t("ui.grimoire"),
		LayoutOrder = 2,
		Size = UDim2.fromOffset(130, BUTTON_HEIGHT),
		BackgroundColor3 = Color3.fromRGB(70, 140, 200),
		Parent = buttons,
	}, function()
		Router.toggle("Grimoire")
	end)
	UI.button({
		Text = "⬆️ " .. Locale.t("ui.upgrades"),
		LayoutOrder = 3,
		Size = UDim2.fromOffset(130, BUTTON_HEIGHT),
		BackgroundColor3 = Theme.colors.gold,
		Parent = buttons,
	}, function()
		Router.toggle("Upgrades")
	end)
	local menuButton = UI.button({
		Text = "☰ " .. Locale.t("ui.menu"),
		LayoutOrder = 4,
		Size = UDim2.fromOffset(130, BUTTON_HEIGHT),
		BackgroundColor3 = Color3.fromRGB(200, 90, 160),
		Parent = buttons,
	}, function()
		Router.toggle("Menu")
	end)
	-- Bolinha "!" quando há missão ou diária para pegar.
	local badge = UI.label({
		Text = "!",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(2, 2),
		Size = UDim2.fromOffset(26, 26),
		BackgroundColor3 = Theme.colors.bad,
		BackgroundTransparency = 0,
		Visible = false,
		MaxTextSize = 20,
		Parent = menuButton,
	})
	UI.corner(badge, 13)

	-- Fichinha de clientes esperando na loja (toque para ver os pedidos).
	local ordersChip = UI.button({
		Position = UDim2.fromOffset(12, 62 + 2 * 40),
		Size = UDim2.fromOffset(220, 34),
		BackgroundColor3 = Color3.fromRGB(70, 160, 90),
		Visible = false,
		MaxTextSize = 18,
		Parent = screen,
	}, function()
		Router.toggle("Shop")
	end)
	local safetyChip = chip(4, Color3.fromRGB(60, 150, 110))
	local friendsChip = chip(5, Color3.fromRGB(150, 100, 220))

	local function inSafeZone(position: Vector3): boolean
		for _, zone in CollectionService:GetTagged("PP_SafeZone") do
			if zone:IsA("BasePart") then
				local localPos = zone.CFrame:PointToObjectSpace(position)
				local half = zone.Size / 2
				if
					math.abs(localPos.X) <= half.X
					and math.abs(localPos.Y) <= half.Y
					and math.abs(localPos.Z) <= half.Z
				then
					return true
				end
			end
		end
		return false
	end

	-- Atualiza as fichinhas lendo os atributos que o servidor põe no Workspace.
	task.spawn(function()
		while true do
			local now = Workspace:GetServerTimeNow()

			local snapshot = State.snapshot
			badge.Visible = DailyUI.canClaim() or MissionsUI.hasClaimable()
			local waiting = ShopUI.waitingCount()
			ordersChip.Visible = waiting > 0
			ordersChip.Text = Locale.t("ui.customersWaiting", { n = waiting })

			local character = Players.LocalPlayer.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local safe = root ~= nil and root:IsA("BasePart") and inSafeZone(root.Position)
			local shield = snapshot ~= nil and snapshot.data.settings.shield
			safetyChip.Visible = safe or shield
			safetyChip.Text = if safe then Locale.t("ui.safeZoneChip") else Locale.t("ui.shieldChip")

			local friends = if snapshot and snapshot.session.friends then snapshot.session.friends else 0
			friendsChip.Visible = friends > 0
			friendsChip.Text = Locale.t("ui.friendBonus", {
				percent = math.floor(
					math.min(Social.friendBonusMax, friends * Social.friendBonusPerFriend) * 100 + 0.5
				),
			})

			local weatherId = Workspace:GetAttribute("PP_Weather")
			local weatherEnds = Workspace:GetAttribute("PP_WeatherEndsAt")
			local weather = if type(weatherId) == "string" then Weather.byId[weatherId] else nil
			if weather and type(weatherEnds) == "number" then
				weatherChip.Visible = true
				weatherChip.Text = Locale.t("ui.weatherChip", {
					icon = weather.icon,
					name = Locale.name("weather", weather.id, weather.name),
					time = Format.time(weatherEnds - now),
				})
			else
				weatherChip.Visible = false
			end

			local cometState = Workspace:GetAttribute("PP_CometState")
			local cometNext = Workspace:GetAttribute("PP_CometNextAt")
			local cometEnds = Workspace:GetAttribute("PP_CometEndsAt")
			if cometState == "active" and type(cometEnds) == "number" then
				cometChip.Visible = true
				cometChip.Text = Locale.t("ui.cometNow", { time = Format.time(cometEnds - now) })
			elseif cometState ~= nil then
				cometChip.Visible = true
				cometChip.Text = Locale.t("ui.cometNow", { time = "" })
			elseif type(cometNext) == "number" then
				cometChip.Visible = true
				cometChip.Text = Locale.t("ui.cometIn", { time = Format.time(cometNext - now) })
			else
				cometChip.Visible = false
			end

			task.wait(0.5)
		end
	end)

	State.changed:Connect(function(snapshot)
		coinsLabel.Text = "🪙 " .. Format.number(snapshot.data.coins)
	end)

	-- Atualiza o contador do efeito ativo (lido dos atributos do personagem).
	task.spawn(function()
		local player = Players.LocalPlayer
		while true do
			local character = player.Character
			local name = character and character:GetAttribute("PP_EffectName")
			local endsAt = character and character:GetAttribute("PP_EffectEndsAt")
			if type(name) == "string" and type(endsAt) == "number" then
				local left = endsAt - Workspace:GetServerTimeNow()
				effectLabel.Visible = left > 0
				effectLabel.Text = `{name} • {Format.time(left)}`
			else
				effectLabel.Visible = false
			end
			task.wait(0.25)
		end
	end)
end

return HUD
