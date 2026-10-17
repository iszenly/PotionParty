--!strict
--[[
	CometService.luau
	Evento do Cometa (configuração em shared/Config/Comet.luau).

	Linha do tempo:
	1. "incoming": aviso para todos (Comet.warningSeconds)
	2. "falling":  o cliente anima o cometa caindo até PP_CometImpactAt
	3. "active":   ingredientes raros espalhados + núcleo de energia
	               - tocar num ingrediente = pegar (o primeiro que encostar leva)
	               - usar o prompt do núcleo = +1 de energia (com intervalo mínimo)
	               - energia cheia = todos que ajudaram ganham Poeira de Cometa
	4. fim: tudo some.

	Estado em atributos do Workspace (PP_CometState, PP_CometNextAt,
	PP_CometPos, PP_CometImpactAt, PP_CometEndsAt, PP_CometEnergy, PP_CometEnergyMax)
	para o cliente desenhar animações e o contador no HUD.
]]

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Comet = require(ReplicatedStorage.Shared.Config.Comet)
local Ingredients = require(ReplicatedStorage.Shared.Config.Ingredients)
local Debug = require(ReplicatedStorage.Shared.Config.Debug)
local Locale = require(ReplicatedStorage.Shared.Locale)
local Announce = require(script.Parent.Parent.Announce)
local DataService = require(script.Parent.DataService)
local SyncService = require(script.Parent.SyncService)
local IngredientService = require(script.Parent.IngredientService)
local MissionService = require(script.Parent.MissionService)

local MAX_TAP_DISTANCE = 20
-- Distância máxima (do centro do personagem até o item) para coletar.
-- Folga para personagens gigantes (efeito Gigante dobra o tamanho).
local PICKUP_RADIUS = 10

type Round = {
	folder: Folder,
	corePosition: Vector3,
	core: Part,
	prompt: ProximityPrompt,
	fill: Frame,
	label: TextLabel,
	energy: number,
	required: number,
	charged: boolean,
	taps: { [Player]: number },
	lastTap: { [Player]: number },
}

local rng = Random.new()
local running = false
local forced = false
local round: Round? = nil

local CometService = {}

local function setAttr(name: string, value: any)
	Workspace:SetAttribute("PP_Comet" .. name, value)
end

-- Sorteia um ingrediente: cada raridade tem um peso, dividido entre os ingredientes dela.
local function pickIngredientId(): string?
	local countByRarity: { [string]: number } = {}
	for _, def in Ingredients.list do
		if not def.cometOnly and Comet.pickupRarityWeights[def.rarity] then
			countByRarity[def.rarity] = (countByRarity[def.rarity] or 0) + 1
		end
	end
	local pool: { { id: string, weight: number } } = {}
	local total = 0
	for _, def in Ingredients.list do
		local rarityWeight = Comet.pickupRarityWeights[def.rarity]
		if not def.cometOnly and rarityWeight then
			local weight = rarityWeight / countByRarity[def.rarity]
			table.insert(pool, { id = def.id, weight = weight })
			total += weight
		end
	end
	if total <= 0 then
		return nil
	end
	local roll = rng:NextNumber(0, total)
	for _, entry in pool do
		roll -= entry.weight
		if roll <= 0 then
			return entry.id
		end
	end
	return pool[#pool].id
end

-- Altura do chão numa posição (ignora o próprio cometa e os personagens).
local function groundAt(position: Vector3, exclude: { Instance }): Vector3
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = exclude
	local result = Workspace:Raycast(position + Vector3.new(0, 100, 0), Vector3.new(0, -250, 0), params)
	return if result then result.Position else position
end

local function characters(): { Instance }
	local list: { Instance } = {}
	for _, player in Players:GetPlayers() do
		if player.Character then
			table.insert(list, player.Character)
		end
	end
	return list
end

-- TODO(asset): modelo final para os ingredientes caídos.
local function makePickup(folder: Folder, position: Vector3, ingredientId: string)
	local def = Ingredients.byId[ingredientId]
	local part = Instance.new("Part")
	part.Name = "CometPickup"
	part.Shape = Enum.PartType.Ball
	part.Size = Vector3.one * 1.8
	part.Color = def.color
	part.Material = Enum.Material.Neon
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.Position = position + Vector3.new(0, 1.4, 0)

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(140, 30)
	billboard.StudsOffset = Vector3.new(0, 2, 0)
	billboard.MaxDistance = 60
	billboard.Parent = part
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.2
	label.Text = def.name
	label.Parent = billboard

	local claimed = false
	part.Touched:Connect(function(hit)
		if claimed then
			return
		end
		local character = hit.Parent
		local player = character and Players:GetPlayerFromCharacter(character)
		if not player or not character then
			return
		end
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if not humanoid or humanoid.Health <= 0 then
			return
		end
		-- Correção P4: o toque pode ser falsificado por exploits; então conferimos
		-- no servidor se o personagem está mesmo perto do item.
		local root = character:FindFirstChild("HumanoidRootPart")
		if not root or not root:IsA("BasePart") or (root.Position - part.Position).Magnitude > PICKUP_RADIUS then
			return
		end
		local data = DataService.get(player)
		if not data then
			return
		end
		claimed = true
		IngredientService.add(data, ingredientId, 1)
		MissionService.progress(player, "comet", 1)
		SyncService.push(player)
		Announce.player(player, "ui.pickedUp", { name = def.name }, "toast")
		part:Destroy()
	end)

	part.Parent = folder
end

local function updateBar(r: Round)
	r.fill.Size = UDim2.fromScale(math.clamp(r.energy / r.required, 0, 1), 1)
	r.label.Text = `⚡ {r.energy}/{r.required}`
	setAttr("Energy", r.energy)
	setAttr("EnergyMax", r.required)
end

local function charge(r: Round)
	r.charged = true
	r.prompt.Enabled = false
	r.core.Color = Color3.fromRGB(255, 210, 60)
	local legendary = Ingredients.byId[Comet.legendaryIngredient]
	for player, taps in r.taps do
		local data = DataService.get(player)
		if data and legendary and taps >= Comet.minTapsForReward then
			IngredientService.add(data, legendary.id, Comet.legendaryAmount)
			SyncService.push(player)
			Announce.player(
				player,
				"announce.cometReward",
				{ amount = Comet.legendaryAmount, name = legendary.name },
				"comet"
			)
		end
	end
	Announce.all("announce.cometCharged", nil, "comet")
end

local function onTap(player: Player)
	local r = round
	if not r or r.charged then
		return
	end
	local now = os.clock()
	if (r.lastTap[player] or 0) + Comet.tapCooldown > now then
		return
	end
	-- O ProximityPrompt já limita a distância, mas conferimos de novo no servidor.
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") or (root.Position - r.corePosition).Magnitude > MAX_TAP_DISTANCE then
		return
	end
	r.lastTap[player] = now
	r.taps[player] = (r.taps[player] or 0) + 1
	r.energy += 1
	updateBar(r)
	if r.energy >= r.required then
		charge(r)
	end
end

-- TODO(asset): modelo final da cratera e do núcleo.
local function buildRound(): Round
	local folder = Instance.new("Folder")
	folder.Name = "Comet"
	folder.Parent = Workspace

	local exclude = characters()
	table.insert(exclude, folder)
	local ground = groundAt(Comet.center, exclude)

	local crater = Instance.new("Part")
	crater.Name = "Crater"
	crater.Shape = Enum.PartType.Cylinder
	crater.Size = Vector3.new(0.4, 22, 22)
	crater.CFrame = CFrame.new(ground + Vector3.new(0, 0.2, 0)) * CFrame.Angles(0, 0, math.rad(90))
	crater.Color = Color3.fromRGB(45, 35, 60)
	crater.Material = Enum.Material.Slate
	crater.Anchored = true
	crater.CanCollide = false
	crater.Parent = folder

	local corePosition = ground + Vector3.new(0, 3.5, 0)
	local core = Instance.new("Part")
	core.Name = "Core"
	core.Shape = Enum.PartType.Ball
	core.Size = Vector3.one * 6
	core.Position = corePosition
	core.Color = Color3.fromRGB(170, 120, 255)
	core.Material = Enum.Material.Neon
	core.Anchored = true
	core.CanCollide = false
	core.Parent = folder

	local light = Instance.new("PointLight")
	light.Color = core.Color
	light.Range = 24
	light.Brightness = 3
	light.Parent = core

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = Locale.t("station.comet.action")
	prompt.ObjectText = Locale.t("station.comet")
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt:SetAttribute("LocaleBase", "station.comet")
	CollectionService:AddTag(prompt, "PP_StationPrompt")
	prompt.Parent = core

	-- Barra de energia flutuando acima do núcleo
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(220, 46)
	billboard.StudsOffset = Vector3.new(0, 5, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 120
	billboard.Parent = core
	local back = Instance.new("Frame")
	back.Size = UDim2.new(1, 0, 0, 18)
	back.Position = UDim2.fromOffset(0, 26)
	back.BackgroundColor3 = Color3.fromRGB(25, 15, 40)
	back.Parent = billboard
	local fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale(0, 1)
	fill.BackgroundColor3 = Color3.fromRGB(255, 210, 60)
	fill.BorderSizePixel = 0
	fill.Parent = back
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, 24)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.2
	label.Parent = billboard

	-- Ingredientes espalhados em volta
	local playerCount = #Players:GetPlayers()
	local pickups = math.min(Comet.pickupsMax, Comet.pickupsBase + Comet.pickupsPerPlayer * playerCount)
	for _ = 1, pickups do
		local id = pickIngredientId()
		if id then
			local angle = rng:NextNumber(0, math.pi * 2)
			local radius = rng:NextNumber(Comet.scatterMinRadius, Comet.scatterMaxRadius)
			local spot = Comet.center + Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
			makePickup(folder, groundAt(spot, exclude), id)
		end
	end

	local r: Round = {
		folder = folder,
		corePosition = corePosition,
		core = core,
		prompt = prompt,
		fill = fill,
		label = label,
		energy = 0,
		required = Comet.energyBase + Comet.energyPerPlayer * math.max(1, playerCount),
		charged = false,
		taps = {},
		lastTap = {},
	}
	prompt.Triggered:Connect(onTap)
	updateBar(r)
	return r
end

local function runComet()
	if running then
		return
	end
	running = true

	setAttr("NextAt", nil)
	setAttr("Pos", Comet.center)
	setAttr("State", "incoming")
	Announce.all("announce.cometIncoming", nil, "comet")
	task.wait(Comet.warningSeconds)

	setAttr("ImpactAt", Workspace:GetServerTimeNow() + Comet.fallSeconds)
	setAttr("State", "falling")
	task.wait(Comet.fallSeconds)

	local r = buildRound()
	round = r
	setAttr("EndsAt", os.time() + Comet.activeSeconds)
	setAttr("State", "active")
	Announce.all("announce.cometLanded", nil, "comet")
	task.wait(Comet.activeSeconds)

	round = nil
	r.folder:Destroy()
	if not r.charged then
		Announce.all("announce.cometEnded", nil, "comet")
	end
	for _, name in { "State", "ImpactAt", "EndsAt", "Energy", "EnergyMax" } do
		setAttr(name, nil)
	end
	running = false
end

-- Debug (Studio): faz o cometa cair agora.
function CometService.trigger()
	if not running then
		forced = true
	end
end

function CometService.init()
	Players.PlayerRemoving:Connect(function(player)
		local r = round
		if r then
			r.taps[player] = nil
			r.lastTap[player] = nil
		end
	end)

	task.spawn(function()
		while true do
			local nextAt = os.time() + Debug.time(Comet.interval)
			setAttr("NextAt", nextAt)
			while os.time() < nextAt - Comet.warningSeconds and not forced do
				task.wait(1)
			end
			forced = false
			runComet()
		end
	end)
end

return CometService
