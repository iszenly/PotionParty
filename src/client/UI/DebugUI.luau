--!strict
--[[
	DebugUI.luau
	Painel de testes que SÓ aparece no Studio (o servidor nem cria o Remote
	"Debug" em servidores reais). Botão "DEBUG" no canto inferior esquerdo.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local UI = require(script.Parent.Components)
local Theme = require(script.Parent.Theme)
local Toast = require(script.Parent.Toast)
local Net = require(script.Parent.Parent.Net)

local DebugUI = {}

-- Textos fixos em português: é uma ferramenta de desenvolvimento.
local COMMANDS: { { label: string, command: string, argument: string? } } = {
	{ label = "⛈️ Tempestade", command = "weather", argument = "Storm" },
	{ label = "🌕 Lua Cheia", command = "weather", argument = "FullMoon" },
	{ label = "☀️ Céu limpo", command = "weather", argument = "Clear" },
	{ label = "☄️ Cometa agora", command = "comet" },
	{ label = "🪙 +5000", command = "coins" },
	{ label = "🧺 +10 de cada", command = "ingredients" },
	{ label = "⏩ Terminar preparos", command = "finishBrews" },
	{ label = "✨ Próx.: Dourada", command = "mutation", argument = "Golden" },
	{ label = "🌈 Próx.: Arco-íris", command = "mutation", argument = "Rainbow" },
	{ label = "♾️ Próx.: Eterna", command = "mutation", argument = "Eternal" },
	{ label = "💰 +100.000", command = "coinsBig" },
	{ label = "🎁 Diária de novo", command = "resetDaily" },
	{ label = "🎯 Novas missões", command = "resetMissions" },
	{ label = "🏪 Simular 2h offline", command = "offline" },
	{ label = "🎫 Pass: Auto-venda", command = "pass", argument = "AutoSell" },
	{ label = "🎫 Pass: Sorte VIP", command = "pass", argument = "VipLuck" },
	{ label = "🎫 Pass: Loja Maior", command = "pass", argument = "BigShop" },
	{ label = "🎫 Pass: Caldeirão", command = "pass", argument = "ExtraCauldron" },
}

function DebugUI.mount(screen: ScreenGui)
	if not RunService:IsStudio() then
		return
	end
	task.spawn(function()
		local remotes = ReplicatedStorage:WaitForChild("Remotes")
		if not remotes:WaitForChild("Debug", 5) then
			return
		end

		local panel: Frame = UI.new("Frame", {
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.new(0, 12, 1, -70),
			Size = UDim2.fromOffset(200, 300),
			BackgroundColor3 = Theme.colors.background,
			BackgroundTransparency = 0.1,
			Visible = false,
			Parent = screen,
		})
		UI.corner(panel)
		local scroll = UI.scroll({ Size = UDim2.fromScale(1, 1), Parent = panel })
		UI.padding(scroll, 6)
		UI.list(scroll, Enum.FillDirection.Vertical, 6)

		for order, entry in COMMANDS do
			UI.button({
				Text = entry.label,
				LayoutOrder = order,
				Size = UDim2.new(1, -8, 0, 40),
				BackgroundColor3 = Theme.colors.panelLight,
				MaxTextSize = 18,
				Parent = scroll,
			}, function()
				local result = Net.request("Debug", entry.command, entry.argument)
				if result.ok then
					Toast.show("DEBUG: " .. entry.label, "info")
				end
			end)
		end

		UI.button({
			Text = "DEBUG",
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.new(0, 12, 1, -12),
			Size = UDim2.fromOffset(100, 48),
			BackgroundColor3 = Theme.colors.bad,
			MaxTextSize = 18,
			Parent = screen,
		}, function()
			panel.Visible = not panel.Visible
		end)
	end)
end

return DebugUI
