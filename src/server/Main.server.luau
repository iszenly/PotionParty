--!strict
--[[
	Main.server.luau
	Ponto de entrada do servidor: inicia os serviços em ordem.
	Cada serviço tem uma função init() que registra Remotes e eventos.
	A ordem importa: quem depende de outro vem depois.
]]

local Services = script.Parent.Services

local MapService = require(Services.MapService)
local DataService = require(Services.DataService)
local SyncService = require(Services.SyncService)
local IngredientService = require(Services.IngredientService)
local UpgradeService = require(Services.UpgradeService)
local CauldronService = require(Services.CauldronService)
local EffectService = require(Services.EffectService)
local PotionService = require(Services.PotionService)
local WeatherService = require(Services.WeatherService)
local DiscoveryService = require(Services.DiscoveryService)
local CometService = require(Services.CometService)
local DebugService = require(Services.DebugService)
local FriendService = require(Services.FriendService)
local MissionService = require(Services.MissionService)
local SettingsService = require(Services.SettingsService)
local SplashService = require(Services.SplashService)
local ShopService = require(Services.ShopService)
local TradeService = require(Services.TradeService)
local FriendshipService = require(Services.FriendshipService)
local RebirthService = require(Services.RebirthService)
local MonetizationService = require(Services.MonetizationService)

MapService.init()
SyncService.init() -- antes do DataService, para ouvir o evento "loaded"
EffectService.init()
IngredientService.init()
UpgradeService.init()
WeatherService.init()
DiscoveryService.init()
FriendService.init()
MissionService.init()
SettingsService.init()
CauldronService.init()
PotionService.init()
SplashService.init()
ShopService.init()
TradeService.init()
FriendshipService.init()
RebirthService.init()
MonetizationService.init() -- antes do DataService (Game Passes conferidos ao carregar)
CometService.init()
DebugService.init() -- só faz algo no Studio
DataService.init() -- por último: começa a carregar jogadores com tudo pronto

print("[PotionParty] servidor iniciado")
