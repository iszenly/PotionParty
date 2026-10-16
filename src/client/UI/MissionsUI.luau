--!strict
--[[
	MissionsUI.luau
	As 3 missões do dia, com barra de progresso e botão de pegar o prêmio.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Missions = require(ReplicatedStorage.Shared.Config.Missions)
local Locale = require(ReplicatedStorage.Shared.Locale)
local Format = require(ReplicatedStorage.Shared.Util.Format)
local UI = require(script.Parent.Components)
local Theme = require(script.Parent.Theme)
local Toast = require(script.Parent.Toast)
local Page = require(script.Parent.Page)
local State = require(script.Parent.Parent.State)
local Net = require(script.Parent.Parent.Net)

local MissionsUI = {}

local page: Page.Page
local list: ScrollingFrame
local busy = false

-- Texto da missão com a quantidade: "Prepare 8 poções".
function MissionsUI.text(missionId: string, target: number): string
	local def = Missions.byId[missionId]
	local template = Locale.name("mission", missionId, if def then def.text else missionId)
	return (string.gsub(template, "{n}", Format.number(target)))
end

local function render()
	local snapshot = State.snapshot
	if not snapshot or not page.isOpen() then
		return
	end
	UI.clearChildren(list)
	for index, mission in snapshot.data.missions.list do
		local row = Page.row(list, index, 84)
		local done = mission.progress >= mission.target
		UI.label({
			Text = MissionsUI.text(mission.id, mission.target),
			Position = UDim2.fromOffset(12, 6),
			Size = UDim2.new(1, -170, 0, 32),
			TextXAlignment = Enum.TextXAlignment.Left,
			MaxTextSize = 22,
			Parent = row,
		})
		local back: Frame = UI.new("Frame", {
			Position = UDim2.fromOffset(12, 46),
			Size = UDim2.new(1, -180, 0, 18),
			BackgroundColor3 = Theme.colors.stroke,
			Parent = row,
		})
		UI.corner(back, 9)
		local fill: Frame = UI.new("Frame", {
			Size = UDim2.fromScale(math.clamp(mission.progress / mission.target, 0, 1), 1),
			BackgroundColor3 = if done then Theme.colors.good else Theme.colors.gold,
			Parent = back,
		})
		UI.corner(fill, 9)
		UI.label({
			Text = `{Format.number(mission.progress)}/{Format.number(mission.target)}  •  🪙 {Format.number(
				mission.reward
			)}`,
			Position = UDim2.fromOffset(12, 64),
			Size = UDim2.new(1, -180, 0, 18),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = Theme.colors.textDim,
			Font = Theme.fontBody,
			MaxTextSize = 14,
			Parent = row,
		})
		UI.button({
			Text = if mission.claimed then Locale.t("ui.claimed") else Locale.t("ui.claim"),
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -8, 0.5, 0),
			Size = UDim2.fromOffset(150, 56),
			BackgroundColor3 = if done and not mission.claimed then Theme.colors.good else Theme.colors.disabled,
			Parent = row,
		}, function()
			if busy or mission.claimed or not done then
				return
			end
			busy = true
			local result = Net.request("ClaimMission", index)
			busy = false
			if result.ok then
				Toast.show(`🪙 +{Format.number(result.data.reward)}`, "good")
			end
		end)
	end
end

-- Alguma missão pronta para pegar? (usado no "!" do botão Menu)
function MissionsUI.hasClaimable(): boolean
	local snapshot = State.snapshot
	if not snapshot then
		return false
	end
	for _, mission in snapshot.data.missions.list do
		if not mission.claimed and mission.progress >= mission.target then
			return true
		end
	end
	return false
end

function MissionsUI.mount(screen: ScreenGui)
	page = Page.create(screen, "Missions", "🎯 " .. Locale.t("ui.missions"), render)
	UI.label({
		Text = Locale.t("ui.missionsHint"),
		Size = UDim2.new(1, 0, 0, 24),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Theme.colors.textDim,
		MaxTextSize = 18,
		Parent = page.content,
	})
	list = Page.list(page.content, 30)
	State.changed:Connect(render)
end

return MissionsUI
