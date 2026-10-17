--!strict
--[[
	ShopService.luau
	A loja de cada jogador (tycoon).

	- Cada jogador recebe um terreno ("plot") ao entrar. São Shop.plotCount
	  terrenos em volta do lobby. Cada terreno é uma zona segura.
	- Clientes NPC chegam enquanto o dono está online, fazem um pedido e
	  esperam um tempo. O jogador entrega no balcão da própria loja (tela Loja).
	- Venda OFFLINE: ao voltar, a loja "vendeu" algumas poções enquanto o
	  jogador estava fora (com teto de quantidade e de moedas).
	- Visitas (teleporte para a loja de outro jogador) e curtidas (1 por loja
	  por dia, na placa da loja).

	Os NPCs são peças simples ancoradas que deslizam com TweenService.
	TODO(asset): trocar por modelos/animações finais.
]]

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Types = require(ReplicatedStorage.Shared.Types)
local Shop = require(ReplicatedStorage.Shared.Config.Shop)
local Mutations = require(ReplicatedStorage.Shared.Config.Mutations)
local Locale = require(ReplicatedStorage.Shared.Locale)
local RecipeKey = require(ReplicatedStorage.Shared.Util.RecipeKey)
local PlayerStats = require(ReplicatedStorage.Shared.Util.PlayerStats)
local OrderMatch = require(ReplicatedStorage.Shared.Util.OrderMatch)
local Format = require(ReplicatedStorage.Shared.Util.Format)
local Net = require(script.Parent.Parent.Net)
local Announce = require(script.Parent.Parent.Announce)
local Validate = require(script.Parent.Parent.Util.Validate)
local DataService = require(script.Parent.DataService)
local SyncService = require(script.Parent.SyncService)
local RecipeService = require(script.Parent.RecipeService)
local RewardService = require(script.Parent.RewardService)
local MissionService = require(script.Parent.MissionService)
local MapService = require(script.Parent.MapService)

type PlayerData = Types.PlayerData
type Order = Types.Order

type Customer = {
	order: Order,
	model: Model,
	root: BasePart,
	bubble: TextLabel,
	slot: number,
}

type Plot = {
	index: number,
	cframe: CFrame,
	folder: Folder,
	counter: BasePart,
	signLabel: TextLabel,
	entrance: CFrame,
	owner: Player?,
	customers: { [string]: Customer },
	nextId: number,
	lastSpawn: number,
}

local PLOT_POSITIONS = {
	Vector3.new(-95, 0, -60),
	Vector3.new(-95, 0, 0),
	Vector3.new(-95, 0, 60),
	Vector3.new(95, 0, -60),
	Vector3.new(95, 0, 0),
	Vector3.new(95, 0, 60),
}
local FLOOR_TOP = 0.4 -- altura do piso da loja
local WALK_TIME = 3

local rng = Random.new()
local plots: { Plot } = {}
local plotOf: { [Player]: Plot } = {}
local visitedThisSession: { [Player]: { [number]: boolean } } = {}

local ShopService = {}

-- ===== Construção dos terrenos =====

local function makePart(parent: Instance, name: string, size: Vector3, cframe: CFrame, color: Color3): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

-- TODO(asset): modelo final da loja (paredes, prateleiras com frascos, vitrine).
local function buildPlot(index: number, position: Vector3, parent: Instance): Plot
	-- O terreno "olha" para o lobby: o -Z local (frente) aponta para o centro.
	local cf = CFrame.lookAt(position, Vector3.new(0, 0, position.Z))
	local folder = Instance.new("Folder")
	folder.Name = `Plot{index}`
	folder.Parent = parent

	makePart(
		folder,
		"Floor",
		Vector3.new(44, FLOOR_TOP, 44),
		cf * CFrame.new(0, FLOOR_TOP / 2, 0),
		Color3.fromRGB(200, 170, 120)
	).Material =
		Enum.Material.WoodPlanks

	local counter = makePart(
		folder,
		"Counter",
		Vector3.new(12, 3.5, 2.5),
		cf * CFrame.new(0, FLOOR_TOP + 1.75, 8),
		Color3.fromRGB(150, 95, 55)
	)
	counter.Material = Enum.Material.WoodPlanks
	CollectionService:AddTag(counter, "PP_Station_Shop")
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = Locale.t("station.shop.action")
	prompt.ObjectText = Locale.t("station.shop")
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt:SetAttribute("Station", "Shop")
	prompt:SetAttribute("Plot", index)
	prompt:SetAttribute("LocaleBase", "station.shop")
	CollectionService:AddTag(prompt, "PP_StationPrompt")
	prompt.Parent = counter

	-- Prateleiras com frascos coloridos (decoração)
	for _, side in { -1, 1 } do
		makePart(
			folder,
			"Shelf",
			Vector3.new(2, 6, 12),
			cf * CFrame.new(side * 17, FLOOR_TOP + 3, 10),
			Color3.fromRGB(120, 80, 50)
		)
		for i = 0, 3 do
			local bottle = makePart(
				folder,
				"Bottle",
				Vector3.new(0.8, 1.2, 0.8),
				cf * CFrame.new(side * 15.6, FLOOR_TOP + 4, 6 + i * 2.6),
				Color3.fromHSV(rng:NextNumber(), 0.6, 1)
			)
			bottle.Material = Enum.Material.Neon
		end
	end

	-- Placa com o nome do dono + botão de curtir
	for _, side in { -1, 1 } do
		makePart(
			folder,
			"Post",
			Vector3.new(0.6, 8, 0.6),
			cf * CFrame.new(side * 7.5, FLOOR_TOP + 4, -21),
			Color3.fromRGB(240, 240, 240)
		)
	end
	local sign = makePart(
		folder,
		"Sign",
		Vector3.new(15, 3.6, 0.5),
		cf * CFrame.new(0, FLOOR_TOP + 8, -21),
		Color3.fromRGB(80, 50, 130)
	)
	local surface = Instance.new("SurfaceGui")
	surface.Face = Enum.NormalId.Front
	surface.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surface.PixelsPerStud = 40
	surface.Parent = sign
	local signLabel = Instance.new("TextLabel")
	signLabel.Size = UDim2.fromScale(1, 1)
	signLabel.BackgroundTransparency = 1
	signLabel.Font = Enum.Font.FredokaOne
	signLabel.TextScaled = true
	signLabel.TextColor3 = Color3.new(1, 1, 1)
	signLabel.Parent = surface

	local likePrompt = Instance.new("ProximityPrompt")
	likePrompt.ActionText = Locale.t("station.like.action")
	likePrompt.ObjectText = Locale.t("station.like")
	likePrompt.HoldDuration = 0.3
	likePrompt.MaxActivationDistance = 14
	likePrompt.RequiresLineOfSight = false
	likePrompt:SetAttribute("LocaleBase", "station.like")
	CollectionService:AddTag(likePrompt, "PP_StationPrompt")
	likePrompt.Parent = sign

	MapService.addSafeZone(folder, cf * CFrame.new(0, 8, 0), Vector3.new(44, 16, 44))

	local plot: Plot = {
		index = index,
		cframe = cf,
		folder = folder,
		counter = counter,
		signLabel = signLabel,
		entrance = cf * CFrame.new(0, FLOOR_TOP + 3, -14) * CFrame.Angles(0, math.pi, 0),
		owner = nil,
		customers = {},
		nextId = 1,
		lastSpawn = 0,
	}
	likePrompt.Triggered:Connect(function(player)
		ShopService.like(player, plot)
	end)
	return plot
end

local function updateSign(plot: Plot)
	local owner = plot.owner
	local data = if owner then DataService.get(owner) else nil
	if owner and data then
		plot.signLabel.Text = Locale.t("shop.sign", {
			name = owner.DisplayName,
			likes = Format.number(data.shop.likes),
			visits = Format.number(data.shop.visits),
		})
	else
		plot.signLabel.Text = Locale.t("shop.signFree")
	end
end

-- ===== Clientes NPC =====

-- Posição da fila: até 5 por fila, em frente ao balcão.
local function slotCFrame(plot: Plot, slot: number): CFrame
	local row = (slot - 1) // 5
	local column = (slot - 1) % 5
	local position = (plot.cframe * CFrame.new(-6 + column * 3, FLOOR_TOP + 1.2, 4 - row * 3)).Position
	return CFrame.lookAt(position, Vector3.new(plot.counter.Position.X, position.Y, plot.counter.Position.Z))
end

local function spawnCFrame(plot: Plot): CFrame
	return plot.cframe * CFrame.new(0, FLOOR_TOP + 1.2, -26)
end

local function makeCustomerModel(plot: Plot): (Model, BasePart, TextLabel)
	local model = Instance.new("Model")
	model.Name = "Customer"
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = Vector3.new(1.8, 2.4, 1.2)
	body.Color = Color3.fromHSV(rng:NextNumber(), 0.55, 0.9)
	body.Anchored = true
	body.CanCollide = false
	body.CFrame = spawnCFrame(plot)
	body.Parent = model

	local function weldTo(part: BasePart, offset: CFrame)
		part.Anchored = false
		part.CanCollide = false
		part.Massless = true
		part.CFrame = body.CFrame * offset
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = body
		weld.Part1 = part
		weld.Parent = part
		part.Parent = model
	end
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Shape = Enum.PartType.Ball
	head.Size = Vector3.one * 1.6
	head.Color = Color3.fromRGB(255, 215, 170)
	weldTo(head, CFrame.new(0, 2, 0))
	for _, side in { -1, 1 } do
		local eye = Instance.new("Part")
		eye.Shape = Enum.PartType.Ball
		eye.Size = Vector3.one * 0.3
		eye.Color = Color3.new(0, 0, 0)
		weldTo(eye, CFrame.new(side * 0.3, 2.15, -0.7))
	end

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(60, 40)
	billboard.StudsOffset = Vector3.new(0, 2, 0)
	billboard.MaxDistance = 80
	billboard.Parent = head
	local bubble = Instance.new("TextLabel")
	bubble.Size = UDim2.fromScale(1, 1)
	bubble.BackgroundTransparency = 1
	bubble.TextScaled = true
	bubble.Text = "💬"
	bubble.Parent = billboard

	model.PrimaryPart = body
	model.Parent = plot.folder
	return model, body, bubble
end

local function walk(root: BasePart, target: CFrame): Tween
	local tween = TweenService:Create(root, TweenInfo.new(WALK_TIME, Enum.EasingStyle.Linear), { CFrame = target })
	tween:Play()
	return tween
end

-- O cliente vai embora (feliz se foi atendido) e some.
local function customerLeave(plot: Plot, id: string, happy: boolean)
	local customer = plot.customers[id]
	if not customer then
		return
	end
	plot.customers[id] = nil
	customer.bubble.Text = if happy then "😊" else "😢"
	local tween = walk(customer.root, spawnCFrame(plot))
	tween.Completed:Connect(function()
		customer.model:Destroy()
	end)
	if plot.owner then
		SyncService.push(plot.owner)
	end
end

local function effectTraits(effect: Types.PotionEffect): { string }
	local list: { string } = {}
	for _, traitId in { effect.size, effect.form, effect.movement, effect.visual } :: { string? } do
		if traitId then
			table.insert(list, traitId)
		end
	end
	return list
end

-- Monta um pedido que o jogador CONSEGUE atender (baseado no que já descobriu).
local function generateOrder(plot: Plot, data: PlayerData): Order
	local id = tostring(plot.nextId)
	plot.nextId += 1
	local base = {
		id = id,
		customerName = Shop.customerNames[rng:NextInteger(1, #Shop.customerNames)],
		expiresAt = os.time() + Shop.customerPatience,
	}

	local known: { Types.RecipeInfo } = {}
	for recipeKey in data.discovered do
		local info = RecipeService.resolve(recipeKey)
		if info then
			table.insert(known, info)
		end
	end

	-- Pedido por tipo (receita exata)
	if #known > 0 and rng:NextNumber() < Shop.recipeOrderChance then
		local info = known[rng:NextInteger(1, #known)]
		return {
			id = base.id,
			customerName = base.customerName,
			expiresAt = base.expiresAt,
			kind = "recipe",
			recipeKey = info.key,
			recipeName = info.name,
			multiplier = Shop.recipeOrderMultiplier,
			special = false,
		}
	end

	-- Pedido especial: dois efeitos de uma mesma receita já descoberta
	if rng:NextNumber() < PlayerStats.specialOrderChance(data) then
		local candidates: { { string } } = {}
		for _, info in known do
			local traits = effectTraits(info.effect)
			if #traits >= 2 then
				table.insert(candidates, traits)
			end
		end
		if #candidates > 0 then
			local traits = table.clone(candidates[rng:NextInteger(1, #candidates)])
			local first = table.remove(traits, rng:NextInteger(1, #traits)) :: string
			local second = traits[rng:NextInteger(1, #traits)]
			return {
				id = base.id,
				customerName = base.customerName,
				expiresAt = base.expiresAt,
				kind = "effect",
				traits = { first, second },
				multiplier = Shop.specialOrderMultiplier,
				special = true,
			}
		end
	end

	-- Pedido por um efeito
	local pool: { string } = {}
	local seen: { [string]: boolean } = {}
	for _, info in known do
		for _, traitId in effectTraits(info.effect) do
			if not seen[traitId] then
				seen[traitId] = true
				table.insert(pool, traitId)
			end
		end
	end
	if #pool == 0 then
		pool = Shop.starterTraits
	end
	return {
		id = base.id,
		customerName = base.customerName,
		expiresAt = base.expiresAt,
		kind = "effect",
		traits = { pool[rng:NextInteger(1, #pool)] },
		multiplier = Shop.effectOrderMultiplier,
		special = false,
	}
end

local function spawnCustomer(plot: Plot, owner: Player, data: PlayerData)
	local used: { [number]: boolean } = {}
	for _, customer in plot.customers do
		used[customer.slot] = true
	end
	local slot = 1
	while used[slot] do
		slot += 1
	end
	local order = generateOrder(plot, data)
	local model, root, bubble = makeCustomerModel(plot)
	plot.customers[order.id] = { order = order, model = model, root = root, bubble = bubble, slot = slot }
	walk(root, slotCFrame(plot, slot))
	SyncService.push(owner)
end

local function countCustomers(plot: Plot): number
	local total = 0
	for _ in plot.customers do
		total += 1
	end
	return total
end

-- Entrega a poção "stackKey" ao cliente. Retorna (moedas, erro).
local function deliver(player: Player, plot: Plot, customerId: string, stackKey: string): (number?, string?)
	local data = DataService.get(player)
	local customer = plot.customers[customerId]
	if not data or not customer then
		return nil, "error.orderGone"
	end
	if (data.potions[stackKey] or 0) < 1 then
		return nil, "error.noPotion"
	end
	local recipeKey, mutationId = RecipeKey.splitStack(stackKey)
	local info = RecipeService.resolve(recipeKey)
	if not info or not OrderMatch.matches(customer.order, recipeKey, info) then
		return nil, "error.orderMismatch"
	end

	local unit = PlayerStats.sellPrice(data, info.value * Mutations.priceMultiplier(mutationId))
	local price = math.floor(unit * customer.order.multiplier + 0.5)
	local left = data.potions[stackKey] - 1
	if left <= 0 then
		(data.potions :: any)[stackKey] = nil
	else
		data.potions[stackKey] = left
	end
	local earned = RewardService.coins(player, data, price)
	data.shop.served += 1
	data.stats.sold += 1
	MissionService.progress(player, "serve", 1)
	customerLeave(plot, customerId, true)
	SyncService.push(player)
	return earned, nil
end

-- Game Pass Auto-venda: entrega sozinho a poção MAIS BARATA que atende cada pedido.
local function autoServe(plot: Plot, owner: Player, data: PlayerData)
	for customerId, customer in plot.customers do
		local bestKey: string? = nil
		local bestValue = math.huge
		for stackKey, count in data.potions do
			if count > 0 then
				local recipeKey, mutationId = RecipeKey.splitStack(stackKey)
				local info = RecipeService.resolve(recipeKey)
				if info and OrderMatch.matches(customer.order, recipeKey, info) then
					local value = info.value * Mutations.priceMultiplier(mutationId)
					if value < bestValue then
						bestKey, bestValue = stackKey, value
					end
				end
			end
		end
		if bestKey then
			deliver(owner, plot, customerId, bestKey)
		end
	end
end

-- ===== Dono do terreno =====

local function assignPlot(player: Player)
	if plotOf[player] then
		return
	end
	for _, plot in plots do
		if plot.owner == nil then
			plot.owner = player
			plot.lastSpawn = os.clock()
			plotOf[player] = plot
			player:SetAttribute("PP_Plot", plot.index)
			updateSign(plot)
			SyncService.push(player)
			return
		end
	end
	warn(`[ShopService] sem terreno livre para {player.Name}; aumente Shop.plotCount ou reduza o tamanho do servidor`)
end

local function releasePlot(player: Player)
	local plot = plotOf[player]
	if not plot then
		return
	end
	plotOf[player] = nil
	plot.owner = nil
	for _, customer in plot.customers do
		customer.model:Destroy()
	end
	table.clear(plot.customers)
	updateSign(plot)
end

--[[
	Vendas enquanto o jogador estava offline (mais baratas primeiro, sem mutadas).
	lastSeen: quando o jogador foi visto pela última vez (vem do DataService.loaded).
	O DataService já marcou data.lastLogout = agora ANTES desta função rodar, então o
	pagamento e o horário novo sempre vão juntos no mesmo salvamento (veja DataService).
]]
function ShopService.offlineSales(player: Player, data: PlayerData, lastSeen: number)
	if lastSeen <= 0 then
		return -- jogador novo: nunca esteve offline
	end
	local elapsed = math.clamp(os.time() - lastSeen, 0, Shop.offlineMaxSeconds)
	local passMultiplier = if PlayerStats.hasPass(data, "AutoSell") then Shop.autoSellOfflineMultiplier else 1
	local maxSales = math.min(elapsed // Shop.offlineSaleInterval, Shop.offlineMaxSales * passMultiplier)
	if maxSales <= 0 then
		return
	end
	local coinCap = Shop.offlineCoinCap * passMultiplier

	local stacks: { { key: string, value: number } } = {}
	for stackKey, count in data.potions do
		local recipeKey, mutationId = RecipeKey.splitStack(stackKey)
		local info = if mutationId == nil and count > 0 then RecipeService.resolve(recipeKey) else nil
		if info then
			table.insert(stacks, { key = stackKey, value = info.value })
		end
	end
	table.sort(stacks, function(a, b)
		return a.value < b.value
	end)

	local sold, coins = 0, 0
	for _, stack in stacks do
		local price = math.floor(PlayerStats.sellPrice(data, stack.value) * Shop.offlinePriceMultiplier)
		while sold < maxSales and coins + price <= coinCap and (data.potions[stack.key] or 0) > 0 do
			data.potions[stack.key] -= 1
			sold += 1
			coins += price
		end
		if data.potions[stack.key] == 0 then
			(data.potions :: any)[stack.key] = nil
		end
		if sold >= maxSales or coins + price > coinCap then
			break
		end
	end
	if sold > 0 then
		data.coins += coins
		data.stats.coinsEarned += coins
		data.stats.sold += sold
		task.delay(6, function()
			if player.Parent then
				Announce.player(
					player,
					"announce.offlineSales",
					{ count = sold, coins = Format.number(coins) },
					"world"
				)
			end
		end)
	end
end

-- ===== Curtidas e visitas =====

function ShopService.like(player: Player, plot: Plot)
	local owner = plot.owner
	if not owner then
		return
	end
	if owner == player then
		Announce.player(player, "announce.cantLikeOwn", nil, "toastInfo")
		return
	end
	local data = DataService.get(player)
	local ownerData = DataService.get(owner)
	if not data or not ownerData then
		return
	end
	local day = os.time() // 86400
	if data.likesGiven.day ~= day then
		data.likesGiven = { day = day, users = {} }
	end
	local ownerKey = tostring(owner.UserId)
	if data.likesGiven.users[ownerKey] then
		Announce.player(player, "announce.alreadyLiked", nil, "toastInfo")
		return
	end
	data.likesGiven.users[ownerKey] = true
	ownerData.shop.likes += 1
	updateSign(plot)
	SyncService.push(player)
	SyncService.push(owner)
	Announce.player(player, "announce.likeSent", { name = owner.DisplayName }, "toast")
	Announce.player(owner, "announce.liked", { name = player.DisplayName }, "toast")
end

function ShopService.init()
	local folder = Instance.new("Folder")
	folder.Name = "PotionPartyPlots"
	folder.Parent = Workspace
	for index = 1, math.min(Shop.plotCount, #PLOT_POSITIONS) do
		local plot = buildPlot(index, PLOT_POSITIONS[index], folder)
		plots[index] = plot
		updateSign(plot)
	end

	SyncService.addSessionProvider("plot", function(player)
		local plot = plotOf[player]
		return if plot then plot.index else nil
	end)
	SyncService.addSessionProvider("orders", function(player)
		local plot = plotOf[player]
		local list: { Order } = {}
		if plot then
			for _, customer in plot.customers do
				table.insert(list, customer.order)
			end
			table.sort(list, function(a, b)
				return a.expiresAt < b.expiresAt
			end)
		end
		return list
	end)

	DataService.loaded:Connect(function(player: Player, data: PlayerData, lastSeen: number)
		ShopService.offlineSales(player, data, lastSeen)
		assignPlot(player)
		SyncService.push(player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		releasePlot(player)
		visitedThisSession[player] = nil
	end)

	Net.onInvoke("ShopDeliver", function(player, customerId: any, stackKey: any)
		local plot = plotOf[player]
		if not plot then
			return Net.fail("error.noShop")
		end
		if not Validate.text(customerId, 16) or not Validate.text(stackKey, 160) then
			return Net.fail("error.invalid")
		end
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if
			not root
			or not root:IsA("BasePart")
			or (root.Position - plot.counter.Position).Magnitude > Shop.counterRadius
		then
			return Net.fail("error.notNearShop")
		end
		local earned, err = deliver(player, plot, customerId, stackKey)
		if not earned then
			return Net.fail(err or "error.generic")
		end
		return Net.ok({ coins = earned })
	end)

	-- Teleporta para a loja de alguém (ou para a própria).
	Net.onInvoke("VisitShop", function(player, targetUserId: any)
		if not Validate.userId(targetUserId) then
			return Net.fail("error.invalid")
		end
		local target = Players:GetPlayerByUserId(targetUserId)
		local plot = if target then plotOf[target] else nil
		local character = player.Character
		if not target or not plot then
			return Net.fail("error.noShop")
		end
		if not character then
			return Net.fail("error.noCharacter")
		end
		character:PivotTo(plot.entrance)

		if target ~= player then
			local visited = visitedThisSession[player] or {}
			visitedThisSession[player] = visited
			local targetData = DataService.get(target)
			if not visited[target.UserId] and targetData then
				visited[target.UserId] = true
				targetData.shop.visits += 1
				updateSign(plot)
				SyncService.push(target)
				Announce.player(target, "announce.visitor", { name = player.DisplayName }, "toast")
			end
		end
		return Net.ok()
	end)

	-- Ciclo da loja: clientes chegam, perdem a paciência e (com Auto-venda) são atendidos.
	task.spawn(function()
		while true do
			task.wait(1)
			for _, plot in plots do
				local owner = plot.owner
				local data = if owner then DataService.get(owner) else nil
				if owner and data then
					local now = os.time()
					for id, customer in plot.customers do
						if now >= customer.order.expiresAt then
							customerLeave(plot, id, false)
						end
					end
					if
						countCustomers(plot) < PlayerStats.maxCustomers(data)
						and os.clock() - plot.lastSpawn >= Shop.customerInterval
					then
						plot.lastSpawn = os.clock()
						spawnCustomer(plot, owner, data)
					end
					if PlayerStats.hasPass(data, "AutoSell") then
						autoServe(plot, owner, data)
					end
				end
			end
		end
	end)
end

return ShopService
