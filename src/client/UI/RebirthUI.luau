--!strict
--[[
	RebirthUI.luau
	"Novo Mestre": mostra custo, multiplicador atual e o próximo.
	Pede confirmação com um segundo toque (evita apertar sem querer).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Rebirth = require(ReplicatedStorage.Shared.Config.Rebirth)
local Locale = require(ReplicatedStorage.Shared.Locale)
local Format = require(ReplicatedStorage.Shared.Util.Format)
local UI = require(script.Parent.Components)
local Theme = require(script.Parent.Theme)
local Toast = require(script.Parent.Toast)
local Page = require(script.Parent.Page)
local State = require(script.Parent.Parent.State)
local Net = require(script.Parent.Parent.Net)

local RebirthUI = {}

local page: Page.Page
local labels: { TextLabel } = {}
local button: TextButton
local armed = false -- primeiro toque "arma", segundo confirma
local busy = false

local function render()
	local snapshot = State.snapshot
	if not snapshot or not page.isOpen() then
		return
	end
	local data = snapshot.data
	local cost = Rebirth.cost(data.rebirths)
	labels[1].Text = Locale.t("ui.rebirthInfo", { bonus = math.floor(Rebirth.multiplierPerRebirth * 100) })
	labels[2].Text = Locale.t("ui.rebirthCurrent", { n = data.rebirths, mult = Rebirth.multiplier(data.rebirths) })
	labels[3].Text = Locale.t("ui.rebirthNext", { mult = Rebirth.multiplier(data.rebirths + 1) })
	labels[4].Text = Locale.t("ui.rebirthCost", { cost = Format.number(cost) })
	labels[5].Text = Locale.t("ui.rebirthKeeps")
	local canAfford = data.coins >= cost
	button.Text = if armed then Locale.t("ui.rebirthSure") else "🧙 " .. Locale.t("ui.rebirthDo")
	button.BackgroundColor3 = if not canAfford
		then Theme.colors.disabled
		elseif armed then Theme.colors.bad
		else Theme.colors.good
end

function RebirthUI.mount(screen: ScreenGui)
	page = Page.create(screen, "Rebirth", "🧙 " .. Locale.t("ui.rebirth"), function()
		armed = false
		render()
	end)
	for i = 1, 5 do
		labels[i] = UI.label({
			Position = UDim2.fromOffset(0, (i - 1) * 32),
			Size = UDim2.new(1, 0, 0, 30),
			TextColor3 = if i == 4 then Theme.colors.gold elseif i == 5 then Theme.colors.textDim else Theme.colors.text,
			MaxTextSize = 20,
			Parent = page.content,
		})
	end
	button = UI.button({
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -4),
		Size = UDim2.new(0.7, 0, 0, Theme.buttonHeight),
		Parent = page.content,
	}, function()
		if busy then
			return
		end
		if not armed then
			armed = true
			render()
			task.delay(4, function()
				armed = false
				render()
			end)
			return
		end
		armed = false
		busy = true
		local result = Net.request("Rebirth")
		busy = false
		if result.ok then
			Toast.show(Locale.t("ui.rebirthDone"), "good")
		end
		render()
	end)
	State.changed:Connect(render)
end

return RebirthUI
