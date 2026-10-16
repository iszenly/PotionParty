--!strict
--[[
	StationController.luau
	- Abre a tela certa quando o jogador ativa o ProximityPrompt de uma estação.
	- Traduz textos do mapa (prompts e placas) para o idioma do jogador.
	- Fecha a tela da estação se o jogador se afastar dela.
]]

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Economy = require(ReplicatedStorage.Shared.Config.Economy)
local Locale = require(ReplicatedStorage.Shared.Locale)
local Router = require(script.Parent.Parent.UI.Router)

-- Estação do mapa -> nome da tela no Router
local PAGE_BY_STATION: { [string]: string } = {
	Cauldron = "Cauldron",
	SellCounter = "Inventory",
	Market = "Market",
	Shop = "Shop", -- balcão da loja (só abre na sua própria loja)
}

-- Telas que só fazem sentido perto da estação (fecham ao se afastar).
local STATION_BY_PAGE: { [string]: string } = {
	Cauldron = "Cauldron",
	Market = "Market",
}

local StationController = {}

local function localizePrompt(instance: Instance)
	if not instance:IsA("ProximityPrompt") then
		return
	end
	local base = instance:GetAttribute("LocaleBase")
	if type(base) == "string" then
		instance.ActionText = Locale.t(base .. ".action")
		instance.ObjectText = Locale.t(base)
	end
end

local function localizeText(instance: Instance)
	if not instance:IsA("TextLabel") then
		return
	end
	local key = instance:GetAttribute("LocaleKey")
	if type(key) == "string" then
		instance.Text = Locale.t(key)
	end
end

local function isNear(station: string): boolean
	local character = Players.LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return false
	end
	for _, tagged in CollectionService:GetTagged("PP_Station_" .. station) do
		-- Um pouco mais de folga que o servidor, para não fechar "no limite".
		if tagged:IsA("BasePart") and (tagged.Position - root.Position).Magnitude <= Economy.stationRadius + 4 then
			return true
		end
	end
	return false
end

function StationController.start()
	ProximityPromptService.PromptTriggered:Connect(function(prompt)
		local station = prompt:GetAttribute("Station")
		local page = if type(station) == "string" then PAGE_BY_STATION[station] else nil
		-- Balcão de outra loja: não abre os pedidos (curta a placa!).
		if station == "Shop" and prompt:GetAttribute("Plot") ~= Players.LocalPlayer:GetAttribute("PP_Plot") then
			return
		end
		if page then
			Router.open(page)
		end
	end)

	for _, prompt in CollectionService:GetTagged("PP_StationPrompt") do
		localizePrompt(prompt)
	end
	CollectionService:GetInstanceAddedSignal("PP_StationPrompt"):Connect(localizePrompt)
	for _, label in CollectionService:GetTagged("PP_LocalizedText") do
		localizeText(label)
	end
	CollectionService:GetInstanceAddedSignal("PP_LocalizedText"):Connect(localizeText)

	task.spawn(function()
		while true do
			task.wait(0.5)
			local page = Router.current()
			local station = page and STATION_BY_PAGE[page]
			if station and not isNear(station) then
				Router.close()
			end
		end
	end)
end

return StationController
