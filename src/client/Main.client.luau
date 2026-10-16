--!strict
--[[
	Main.client.luau
	Ponto de entrada do cliente: espera o jogo carregar, monta a interface e
	liga os controladores.
]]

-- Espera a replicação inicial (ReplicatedStorage completo) antes de usar módulos.
if not game:IsLoaded() then
	game.Loaded:Wait()
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Locale = require(ReplicatedStorage.Shared.Locale)

-- Idioma: por enquanto o jogo é todo em português. Para detectar o idioma do
-- jogador, troque AUTO_DETECT_LANGUAGE para true (o inglês ainda está incompleto).
local AUTO_DETECT_LANGUAGE = false
if AUTO_DETECT_LANGUAGE then
	Locale.setLanguage(Locale.fromRobloxLocale(Players.LocalPlayer.LocaleId))
end

local Client = script.Parent
local UIFolder = Client.UI
local Toast = require(UIFolder.Toast)
local HUD = require(UIFolder.HUD)
local CauldronUI = require(UIFolder.CauldronUI)
local InventoryUI = require(UIFolder.InventoryUI)
local MarketUI = require(UIFolder.MarketUI)
local UpgradeUI = require(UIFolder.UpgradeUI)
local RevealPopup = require(UIFolder.RevealPopup)
local GrimoireUI = require(UIFolder.GrimoireUI)
local Banner = require(UIFolder.Banner)
local DebugUI = require(UIFolder.DebugUI)
local State = require(Client.State)
local StationController = require(Client.Controllers.StationController)
local EffectController = require(Client.Controllers.EffectController)
local WeatherController = require(Client.Controllers.WeatherController)
local CometController = require(Client.Controllers.CometController)
local SplashController = require(Client.Controllers.SplashController)
local MenuUI = require(UIFolder.MenuUI)
local MissionsUI = require(UIFolder.MissionsUI)
local DailyUI = require(UIFolder.DailyUI)
local SocialUI = require(UIFolder.SocialUI)
local ShopUI = require(UIFolder.ShopUI)
local TradeUI = require(UIFolder.TradeUI)
local FriendshipUI = require(UIFolder.FriendshipUI)
local RebirthUI = require(UIFolder.RebirthUI)
local StoreUI = require(UIFolder.StoreUI)
local SettingsUI = require(UIFolder.SettingsUI)

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

-- Tela principal (HUD + janelas)
local mainScreen = Instance.new("ScreenGui")
mainScreen.Name = "PotionParty"
mainScreen.ResetOnSpawn = false
mainScreen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
mainScreen.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets -- não fica embaixo dos botões do Roblox
mainScreen.DisplayOrder = 1
mainScreen.Parent = playerGui

-- Camada de cima (revelação e avisos), sempre na frente das janelas
local overlayScreen = Instance.new("ScreenGui")
overlayScreen.Name = "PotionPartyOverlay"
overlayScreen.ResetOnSpawn = false
overlayScreen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
overlayScreen.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
overlayScreen.DisplayOrder = 10
overlayScreen.Parent = playerGui

HUD.mount(mainScreen)
CauldronUI.mount(mainScreen)
InventoryUI.mount(mainScreen)
MarketUI.mount(mainScreen)
UpgradeUI.mount(mainScreen)
GrimoireUI.mount(mainScreen)
MenuUI.mount(mainScreen)
MissionsUI.mount(mainScreen)
DailyUI.mount(mainScreen)
SocialUI.mount(mainScreen)
ShopUI.mount(mainScreen)
TradeUI.mount(mainScreen, overlayScreen)
FriendshipUI.mount(mainScreen)
RebirthUI.mount(mainScreen)
StoreUI.mount(mainScreen)
SettingsUI.mount(mainScreen)
DebugUI.mount(mainScreen) -- só aparece no Studio
RevealPopup.mount(overlayScreen)
Toast.mount(overlayScreen)
Banner.mount(overlayScreen)

StationController.start()
EffectController.start()
WeatherController.start()
CometController.start()
SplashController.start()
State.start()
