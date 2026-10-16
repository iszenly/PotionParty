--!strict
--[[
	MapService.luau
	Monta um mapa placeholder (peças simples) com as estações:
		- Caldeirão         (preparar poções)
		- Balcão de Vendas  (vender poções)
		- Mercado           (comprar/liberar ingredientes)
	e oferece MapService.isNear(player, "Cauldron") para validar distância.

	Cada estação tem:
		- a tag "PP_Station_<Nome>" (CollectionService) na peça principal;
		- um ProximityPrompt com o atributo "Station" (o cliente abre a tela certa).

	TODO(asset): trocar as peças por modelos finais. Basta manter a tag e o
	ProximityPrompt com o atributo "Station" na peça principal do modelo novo.
]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Economy = require(ReplicatedStorage.Shared.Config.Economy)
local Locale = require(ReplicatedStorage.Shared.Locale)

local MAP_NAME = "PotionPartyMap"

local MapService = {}

local function makePart(props: { [string]: any }): Part
	local part = Instance.new("Part")
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	for key, value in props do
		(part :: any)[key] = value
	end
	return part
end

-- Texto flutuante. A tag "PP_LocalizedText" deixa o cliente traduzir o texto.
local function addLabel(adornee: BasePart, localeKey: string, height: number)
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(240, 60)
	billboard.StudsOffset = Vector3.new(0, height, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 80
	billboard.Parent = adornee

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.2
	label.Text = Locale.t(localeKey)
	label:SetAttribute("LocaleKey", localeKey)
	CollectionService:AddTag(label, "PP_LocalizedText")
	label.Parent = billboard
end

local function addPrompt(part: BasePart, station: string, localeBase: string)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = Locale.t(localeBase .. ".action")
	prompt.ObjectText = Locale.t(localeBase)
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt:SetAttribute("Station", station)
	prompt:SetAttribute("LocaleBase", localeBase)
	CollectionService:AddTag(prompt, "PP_StationPrompt")
	prompt.Parent = part
	CollectionService:AddTag(part, "PP_Station_" .. station)
end

local function buildCauldron(parent: Instance, base: Vector3)
	local model = Instance.new("Model")
	model.Name = "Cauldron"

	-- Cilindros no Roblox "deitam" no eixo X, então giramos 90° para ficar em pé.
	local upright = CFrame.Angles(0, 0, math.rad(90))
	local body = makePart({
		Name = "Body",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(4, 7, 7),
		CFrame = CFrame.new(base + Vector3.new(0, 2.5, 0)) * upright,
		Color = Color3.fromRGB(35, 35, 40),
		Material = Enum.Material.Metal,
	})
	body.Parent = model

	local liquid = makePart({
		Name = "Liquid",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.4, 6.2, 6.2),
		CFrame = CFrame.new(base + Vector3.new(0, 4.4, 0)) * upright,
		Color = Color3.fromRGB(120, 255, 120),
		Material = Enum.Material.Neon,
		CanCollide = false,
	})
	liquid.Parent = model

	for i = 0, 2 do
		local angle = math.rad(i * 120)
		local leg = makePart({
			Name = "Leg",
			Size = Vector3.new(0.8, 1, 0.8),
			Position = base + Vector3.new(math.cos(angle) * 2.6, 0.5, math.sin(angle) * 2.6),
			Color = Color3.fromRGB(35, 35, 40),
		})
		leg.Parent = model
	end

	addPrompt(body, "Cauldron", "station.cauldron")
	addLabel(body, "station.cauldron", 5)
	model.Parent = parent
end

local function buildSellCounter(parent: Instance, base: Vector3)
	local model = Instance.new("Model")
	model.Name = "SellCounter"
	local counter = makePart({
		Name = "Counter",
		Size = Vector3.new(10, 3.5, 3),
		Position = base + Vector3.new(0, 1.75, 0),
		Color = Color3.fromRGB(140, 90, 50),
		Material = Enum.Material.WoodPlanks,
	})
	counter.Parent = model
	local top = makePart({
		Name = "Top",
		Size = Vector3.new(10.6, 0.4, 3.6),
		Position = base + Vector3.new(0, 3.7, 0),
		Color = Color3.fromRGB(250, 210, 90),
	})
	top.Parent = model
	addPrompt(counter, "SellCounter", "station.sell")
	addLabel(counter, "station.sell", 5)
	model.Parent = parent
end

local function buildMarket(parent: Instance, base: Vector3)
	local model = Instance.new("Model")
	model.Name = "Market"
	local stall = makePart({
		Name = "Stall",
		Size = Vector3.new(10, 3.5, 4),
		Position = base + Vector3.new(0, 1.75, 0),
		Color = Color3.fromRGB(90, 160, 90),
		Material = Enum.Material.WoodPlanks,
	})
	stall.Parent = model
	local roof = makePart({
		Name = "Roof",
		Size = Vector3.new(11, 0.5, 5),
		Position = base + Vector3.new(0, 7, 0),
		Color = Color3.fromRGB(230, 80, 80),
	})
	roof.Parent = model
	for _, x in { -4.8, 4.8 } do
		local pole = makePart({
			Name = "Pole",
			Size = Vector3.new(0.5, 3.3, 0.5),
			Position = base + Vector3.new(x, 5.15, 0),
			Color = Color3.fromRGB(240, 240, 240),
		})
		pole.Parent = model
	end
	addPrompt(stall, "Market", "station.market")
	addLabel(stall, "station.market", 7)
	model.Parent = parent
end

-- Se o lugar não tiver chão (Baseplate), cria um.
local function ensureFloor(map: Instance)
	if Workspace:FindFirstChild("Baseplate") then
		return
	end
	local floor = makePart({
		Name = "Floor",
		Size = Vector3.new(256, 2, 256),
		Position = Vector3.new(0, -1, 0),
		Color = Color3.fromRGB(110, 190, 110),
		Material = Enum.Material.Grass,
	})
	floor.Parent = map
	if not Workspace:FindFirstChildWhichIsA("SpawnLocation", true) then
		local spawn = Instance.new("SpawnLocation")
		spawn.Anchored = true
		spawn.Size = Vector3.new(8, 1, 8)
		spawn.Position = Vector3.new(0, 0.5, 12)
		spawn.Parent = map
	end
end

--[[
	Zona segura: uma peça invisível com a tag "PP_SafeZone". Dentro dela,
	respingos não funcionam (lobby e lojas). Um piso verde translúcido mostra
	onde ela fica.
]]
function MapService.addSafeZone(parent: Instance, cframe: CFrame, size: Vector3, showLabel: boolean?)
	local zone = makePart({
		Name = "SafeZone",
		CFrame = cframe,
		Size = size,
		Transparency = 1,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
	})
	CollectionService:AddTag(zone, "PP_SafeZone")
	zone.Parent = parent

	local floorMark = makePart({
		Name = "SafeZoneFloor",
		CFrame = cframe * CFrame.new(0, -size.Y / 2 + 0.05, 0),
		Size = Vector3.new(size.X, 0.1, size.Z),
		Color = Color3.fromRGB(110, 230, 140),
		Material = Enum.Material.Neon,
		Transparency = 0.85,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
	})
	floorMark.Parent = parent
	if showLabel then
		addLabel(floorMark, "station.safeZone", 2)
	end
end

-- A posição está dentro de alguma zona segura?
function MapService.inSafeZone(position: Vector3): boolean
	for _, zone in CollectionService:GetTagged("PP_SafeZone") do
		if zone:IsA("BasePart") then
			local localPos = zone.CFrame:PointToObjectSpace(position)
			local half = zone.Size / 2
			if math.abs(localPos.X) <= half.X and math.abs(localPos.Y) <= half.Y and math.abs(localPos.Z) <= half.Z then
				return true
			end
		end
	end
	return false
end

-- Centro do Caldeirão da Amizade (usado pelo FriendshipService).
MapService.friendshipCenter = Vector3.new(0, 0, -44)

-- TODO(asset): modelo final do Caldeirão da Amizade.
local function buildFriendshipCauldron(parent: Instance, base: Vector3)
	local model = Instance.new("Model")
	model.Name = "FriendshipCauldron"
	local upright = CFrame.Angles(0, 0, math.rad(90))
	local body = makePart({
		Name = "Body",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(4.5, 8, 8),
		CFrame = CFrame.new(base + Vector3.new(0, 2.5, 0)) * upright,
		Color = Color3.fromRGB(220, 90, 160),
		Material = Enum.Material.Metal,
	})
	body.Parent = model
	local liquid = makePart({
		Name = "Liquid",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.4, 7, 7),
		CFrame = CFrame.new(base + Vector3.new(0, 4.7, 0)) * upright,
		Color = Color3.fromRGB(255, 170, 220),
		Material = Enum.Material.Neon,
		CanCollide = false,
	})
	liquid.Parent = model
	addLabel(body, "station.friendship", 6)

	-- Dois "lados": cada jogador fica em um.
	for _, side in { "A", "B" } do
		local offset = if side == "A" then -7 else 7
		local pad = makePart({
			Name = "Pad" .. side,
			Size = Vector3.new(4, 0.4, 4),
			Position = base + Vector3.new(offset, 0.2, 0),
			Color = if side == "A" then Color3.fromRGB(255, 150, 200) else Color3.fromRGB(150, 200, 255),
			Material = Enum.Material.Neon,
		})
		pad.Parent = model
		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = Locale.t("station.friendship.action")
		prompt.ObjectText = Locale.t("station.friendship")
		prompt.HoldDuration = 0
		prompt.MaxActivationDistance = 8
		prompt.RequiresLineOfSight = false
		prompt:SetAttribute("Side", side)
		prompt:SetAttribute("LocaleBase", "station.friendship")
		CollectionService:AddTag(prompt, "PP_StationPrompt")
		CollectionService:AddTag(prompt, "PP_FriendshipPad")
		prompt.Parent = pad
	end
	model.Parent = parent
end

function MapService.init()
	local old = Workspace:FindFirstChild(MAP_NAME)
	if old then
		old:Destroy()
	end
	local map = Instance.new("Folder")
	map.Name = MAP_NAME
	map.Parent = Workspace

	ensureFloor(map)
	buildCauldron(map, Vector3.new(0, 0, -20))
	buildSellCounter(map, Vector3.new(24, 0, -12))
	buildMarket(map, Vector3.new(-24, 0, -12))
	buildFriendshipCauldron(map, MapService.friendshipCenter)
	-- Lobby inteiro (spawn + estações) é zona segura. O Cometa cai fora dela.
	-- (O HUD mostra "Zona segura" quando o jogador está dentro de uma.)
	MapService.addSafeZone(map, CFrame.new(0, 10, -18), Vector3.new(90, 20, 64))
end

-- O jogador está perto (Economy.stationRadius) de alguma estação deste tipo?
function MapService.isNear(player: Player, station: string): boolean
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return false
	end
	for _, tagged in CollectionService:GetTagged("PP_Station_" .. station) do
		if tagged:IsA("BasePart") and (tagged.Position - root.Position).Magnitude <= Economy.stationRadius then
			return true
		end
	end
	return false
end

return MapService
