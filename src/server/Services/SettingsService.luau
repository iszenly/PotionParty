--!strict
--[[
	SettingsService.luau
	Configurações do jogador:
	- Modo Escudo: quando ligado, respingos de outros jogadores não pegam.
	- Trilha cosmética equipada (comprada na Loja VIP).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Shared.Types)
local Monetization = require(ReplicatedStorage.Shared.Config.Monetization)
local Net = require(script.Parent.Parent.Net)
local Validate = require(script.Parent.Parent.Util.Validate)
local DataService = require(script.Parent.DataService)
local SyncService = require(script.Parent.SyncService)

local SettingsService = {}

-- Coloca (ou tira) a trilha cosmética no personagem atual.
function SettingsService.applyTrail(player: Player)
	local data = DataService.get(player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not data or not character or not root or not root:IsA("BasePart") then
		return
	end
	for _, name in { "PP_Trail", "PP_TrailTop", "PP_TrailBottom" } do
		local old = root:FindFirstChild(name)
		if old then
			old:Destroy()
		end
	end
	character:SetAttribute("PP_Shield", data.settings.shield)

	local trailId = data.cosmetics.trail
	local def = if trailId and data.cosmetics.owned[trailId] then Monetization.cosmetics[trailId] else nil
	if not def then
		return
	end
	local top = Instance.new("Attachment")
	top.Name = "PP_TrailTop"
	top.Position = Vector3.new(0, 1, 0)
	top.Parent = root
	local bottom = Instance.new("Attachment")
	bottom.Name = "PP_TrailBottom"
	bottom.Position = Vector3.new(0, -1, 0)
	bottom.Parent = root

	local keypoints: { ColorSequenceKeypoint } = {}
	local count = #def.colors
	for i, color in def.colors do
		local time = if count == 1 then 0 else (i - 1) / (count - 1)
		table.insert(keypoints, ColorSequenceKeypoint.new(time, color))
	end
	if count == 1 then
		table.insert(keypoints, ColorSequenceKeypoint.new(1, def.colors[1]))
	end

	local trail = Instance.new("Trail")
	trail.Name = "PP_Trail"
	trail.Attachment0 = top
	trail.Attachment1 = bottom
	trail.Color = ColorSequence.new(keypoints)
	trail.Lifetime = 0.6
	trail.LightEmission = 0.6
	trail.Transparency = NumberSequence.new(0.2, 1)
	trail.Parent = root
end

local function onCharacter(player: Player, character: Model)
	character:WaitForChild("HumanoidRootPart", 10)
	SettingsService.applyTrail(player)
end

function SettingsService.init()
	local function watch(player: Player)
		player.CharacterAdded:Connect(function(character)
			onCharacter(player, character)
		end)
	end
	for _, player in Players:GetPlayers() do
		watch(player)
	end
	Players.PlayerAdded:Connect(watch)
	DataService.loaded:Connect(function(player: Player, _data: Types.PlayerData)
		SettingsService.applyTrail(player)
	end)

	Net.onInvoke("SetShield", function(player, enabled: any)
		local data = DataService.get(player)
		if not data then
			return Net.fail("error.notLoaded")
		end
		if type(enabled) ~= "boolean" then
			return Net.fail("error.invalid")
		end
		data.settings.shield = enabled
		if player.Character then
			player.Character:SetAttribute("PP_Shield", enabled)
		end
		SyncService.push(player)
		return Net.ok()
	end)

	Net.onInvoke("EquipTrail", function(player, trailId: any)
		local data = DataService.get(player)
		if not data then
			return Net.fail("error.notLoaded")
		end
		if trailId == nil or trailId == "" then
			data.cosmetics.trail = nil
		elseif Validate.text(trailId, 32) and data.cosmetics.owned[trailId] then
			data.cosmetics.trail = trailId
		else
			return Net.fail("error.invalid")
		end
		SettingsService.applyTrail(player)
		SyncService.push(player)
		return Net.ok()
	end)
end

return SettingsService
