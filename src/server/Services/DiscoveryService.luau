--!strict
--[[
	DiscoveryService.luau
	Descoberta Mundial, ranking e receitas secretas da semana.

	DESCOBERTA MUNDIAL
	Quando alguém cria uma receita pela 1ª vez, tentamos gravar essa pessoa como
	"descobridora mundial" numa DataStore GLOBAL (compartilhada por todos os
	servidores), usando UpdateAsync:
		- se a chave ainda não tem dono -> grava { userId, nome, data, JobId };
		- se já tem dono -> não grava nada e devolvemos quem é o dono.
	UpdateAsync é atômico: mesmo se dois servidores tentarem ao mesmo tempo,
	só um vence. Não existe nenhuma forma de COMPRAR uma descoberta.

	Os pedidos vão para uma fila processada aos poucos, respeitando o limite de
	requisições do DataStore. O resultado fica salvo no Grimório do jogador
	(data.discovered[chave].by/byId/first), então não precisamos ler a DataStore
	global toda vez que alguém abre o Grimório.

	O anúncio vai para TODOS os servidores via MessagingService.

	RANKING: OrderedDataStore com o total de receitas no Grimório de cada jogador.
	SEGREDOS DA SEMANA: veja Config/SecretRecipes.luau.

	No Studio sem acesso às APIs, nada global funciona; o jogo segue normal e
	as receitas ficam como "Registrando…" até entrar num servidor com acesso.
]]

local DataStoreService = game:GetService("DataStoreService")
local MessagingService = game:GetService("MessagingService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Shared.Types)
local Economy = require(ReplicatedStorage.Shared.Config.Economy)
local Ingredients = require(ReplicatedStorage.Shared.Config.Ingredients)
local RecipeKey = require(ReplicatedStorage.Shared.Util.RecipeKey)
local Hash = require(ReplicatedStorage.Shared.Util.Hash)
local SecretRecipes = require(script.Parent.Parent.Config.SecretRecipes)
local Net = require(script.Parent.Parent.Net)
local Announce = require(script.Parent.Parent.Announce)
local DataService = require(script.Parent.DataService)
local SyncService = require(script.Parent.SyncService)
local RecipeService = require(script.Parent.RecipeService)

type PlayerData = Types.PlayerData

type WorldRecord = {
	userId: number,
	name: string,
	display: string,
	time: number,
	jobId: string,
	placeId: number,
}

local WORLD_STORE_NAME = "PotionParty_WorldDiscoveries_v1"
local RANKING_STORE_NAME = "PotionParty_DiscoveryRanking_v1"
local TOPIC = "PP_WorldDiscovery"

local WEEK_SECONDS = 604800
local WEEK_OFFSET = 345600 -- 4 dias: faz a semana começar na segunda 00:00 UTC
local RANKING_FLUSH_INTERVAL = 60
local RANKING_CACHE_SECONDS = 60
local RANKING_SIZE = 20
local RETRY_ON_JOIN = 5 -- receitas "pendentes" re-tentadas quando o jogador entra
local MAX_REMOTE_ANNOUNCES_PER_MINUTE = 8 -- anúncios vindos de outros servidores
local PUBLISH_INTERVAL = 3 -- segundos entre publicações deste servidor
local MAX_PUBLISH_QUEUE = 20

local DiscoveryService = {}

-- As DataStores podem falhar ao abrir (ex.: Studio sem publicar). Guardamos nil.
local worldStore: DataStore? = nil
local rankingStore: OrderedDataStore? = nil

local queue: { { player: Player, key: string, recipeName: string } } = {}
local publishQueue: { { player: string, recipe: string, jobId: string } } = {}
local remoteAnnounceTimes: { number } = {}
local rankingDirty: { [Player]: boolean } = {}
local rankingCache: { entries: { Types.RankingEntry }, fetchedAt: number } = { entries = {}, fetchedAt = -math.huge }
local rankingFetching = false
local nameCache: { [number]: string } = {}

-- Chaves de DataStore têm no máximo 50 caracteres.
local function storeKey(recipeKey: string): string
	if #recipeKey <= 50 then
		return recipeKey
	end
	return string.sub(recipeKey, 1, 40) .. "_" .. string.format("%08x", Hash.fnv1a(recipeKey))
end

local function isWorldRecord(value: any): boolean
	return type(value) == "table" and type(value.userId) == "number" and type(value.display) == "string"
end

--[[
	Tenta ser o dono da receita. Retorna (dono, souEuOPrimeiro, gravei):
	- dono: o registro mundial (nil se a DataStore falhou);
	- souEuOPrimeiro: o dono é este jogador;
	- gravei: ESTA chamada gravou o registro. Só nesse caso anunciamos. Se o
	  registro já era do próprio jogador (uma tentativa anterior gravou, mas o
	  Grimório não chegou a ser salvo), marcamos o Grimório sem anunciar de novo.
]]
local function claimAsync(player: Player, recipeKey: string): (WorldRecord?, boolean, boolean)
	local store = worldStore
	if not store then
		return nil, false, false
	end
	local mine: WorldRecord = {
		userId = player.UserId,
		name = player.Name,
		display = player.DisplayName,
		time = os.time(),
		jobId = game.JobId,
		placeId = game.PlaceId,
	}
	local existing: WorldRecord? = nil
	local success, err = pcall(function()
		store:UpdateAsync(storeKey(recipeKey), function(old: any)
			-- Esta função pode rodar mais de uma vez se houver conflito; por isso
			-- "existing" é recalculado a cada chamada.
			if isWorldRecord(old) then
				existing = old
				return nil -- nil = cancela a escrita (já tem dono)
			end
			existing = nil
			return mine
		end)
	end)
	if not success then
		warn(`[DiscoveryService] falha ao registrar {recipeKey}: {err}`)
		return nil, false, false
	end
	if existing then
		return existing, existing.userId == player.UserId, false
	end
	return mine, true, true
end

local function announceWorldFirst(display: string, recipeName: string)
	Announce.all("announce.worldFirst", { player = display, recipe = recipeName }, "world")
	table.insert(publishQueue, { player = display, recipe = recipeName, jobId = game.JobId })
	-- Se acumular demais (muitas descobertas seguidas), descarta as mais antigas.
	while #publishQueue > MAX_PUBLISH_QUEUE do
		table.remove(publishQueue, 1)
	end
end

local function processEntry(player: Player, recipeKey: string, recipeName: string)
	local data = DataService.get(player)
	local entry = data and data.discovered[recipeKey]
	if not data or not entry or entry.by ~= nil then
		return
	end
	local owner, isFirst, wroteNow = claimAsync(player, recipeKey)
	if not owner then
		return
	end
	-- O jogador pode ter saído durante a espera; "entry" é a mesma tabela dos dados.
	-- Como "entry.by" ainda era nil, esta é a primeira vez que este perfil conta
	-- esta descoberta: o contador não fica duplicado.
	entry.by = owner.display
	entry.byId = owner.userId
	entry.first = isFirst
	if isFirst then
		data.worldFirsts += 1
	end
	if wroteNow then
		announceWorldFirst(player.DisplayName, recipeName)
	end
	if player.Parent then
		SyncService.push(player)
	end
end

-- Coloca uma receita recém-descoberta na fila do registro mundial.
function DiscoveryService.register(player: Player, recipeKey: string, recipeName: string)
	table.insert(queue, { player = player, key = recipeKey, recipeName = recipeName })
end

-- Marca o jogador para atualizar o ranking no próximo ciclo.
function DiscoveryService.markRankingDirty(player: Player)
	rankingDirty[player] = true
end

local function countDiscovered(data: PlayerData): number
	local count = 0
	for _ in data.discovered do
		count += 1
	end
	return count
end

local function flushRanking(userId: number, count: number)
	local store = rankingStore
	if not store or count <= 0 then
		return
	end
	local success, err = pcall(function()
		store:SetAsync(tostring(userId), count)
	end)
	if not success then
		warn(`[DiscoveryService] falha ao salvar ranking: {err}`)
	end
end

local function fetchRanking()
	local store = rankingStore
	if not store or rankingFetching then
		return
	end
	rankingFetching = true
	local success, err = pcall(function()
		local pages = store:GetSortedAsync(false, RANKING_SIZE)
		local entries: { Types.RankingEntry } = {}
		for rank, item in pages:GetCurrentPage() do
			local userId = tonumber(item.key)
			local name = "?"
			if userId then
				name = nameCache[userId]
				if not name then
					local ok, result = pcall(Players.GetNameFromUserIdAsync, Players, userId)
					name = if ok then result else "?"
					nameCache[userId] = name
				end
			end
			table.insert(entries, { rank = rank, name = name, value = item.value })
		end
		rankingCache = { entries = entries, fetchedAt = os.clock() }
	end)
	if not success then
		warn(`[DiscoveryService] falha ao ler ranking: {err}`)
	end
	rankingFetching = false
end

-- ===== Receitas secretas da semana =====

type WeeklyEntry = { key: string, hint: string }
local weeklyCache: { week: number, list: { WeeklyEntry } } = { week = -1, list = {} }

local function currentWeek(): number
	return (os.time() - WEEK_OFFSET) // WEEK_SECONDS
end

local function weekSecrets(week: number): { WeeklyEntry }
	if weeklyCache.week == week then
		return weeklyCache.list
	end
	-- Só entram receitas válidas (ingredientes existentes).
	local valid: { WeeklyEntry } = {}
	for _, secret in SecretRecipes.pool do
		local ok = #secret.ingredients >= 1 and #secret.ingredients <= Economy.maxIngredientsPerBrew
		for _, id in secret.ingredients do
			if not Ingredients.byId[id] then
				ok = false
				warn(`[SecretRecipes] ingrediente desconhecido: {id}`)
			end
		end
		if ok then
			table.insert(valid, { key = RecipeKey.fromIds(secret.ingredients), hint = secret.hint })
		end
	end
	-- Embaralha com a semana como semente (igual em todos os servidores).
	local rng = Random.new(week * 7919 + 17)
	for i = #valid, 2, -1 do
		local j = rng:NextInteger(1, i)
		valid[i], valid[j] = valid[j], valid[i]
	end
	local picked: { WeeklyEntry } = {}
	for i = 1, math.min(SecretRecipes.perWeek, #valid) do
		picked[i] = valid[i]
	end
	weeklyCache = { week = week, list = picked }
	return picked
end

local function ensureWeek(data: PlayerData, week: number)
	if data.weekly.week ~= week then
		data.weekly = { week = week, claimed = {} }
	end
end

-- Chamado ao coletar uma poção. Retorna a recompensa (moedas) se for um segredo da semana.
function DiscoveryService.checkWeeklySecret(data: PlayerData, recipeKey: string): number?
	local week = currentWeek()
	ensureWeek(data, week)
	for _, secret in weekSecrets(week) do
		if secret.key == recipeKey and not data.weekly.claimed[recipeKey] then
			data.weekly.claimed[recipeKey] = true
			data.coins += SecretRecipes.rewardCoins
			return SecretRecipes.rewardCoins
		end
	end
	return nil
end

-- ===== Inicialização =====

local function openStores()
	local ok1, world = pcall(DataStoreService.GetDataStore, DataStoreService, WORLD_STORE_NAME)
	if ok1 then
		worldStore = world
	else
		warn(`[DiscoveryService] DataStore global indisponível: {world}`)
	end
	local ok2, ranking = pcall(DataStoreService.GetOrderedDataStore, DataStoreService, RANKING_STORE_NAME)
	if ok2 then
		rankingStore = ranking
	else
		warn(`[DiscoveryService] ranking indisponível: {ranking}`)
	end
end

local function subscribe()
	local ok, err = pcall(function()
		MessagingService:SubscribeAsync(TOPIC, function(message)
			local payload = message.Data
			if type(payload) ~= "table" or payload.jobId == game.JobId then
				return -- este servidor já anunciou localmente
			end
			if type(payload.player) ~= "string" or type(payload.recipe) ~= "string" then
				return
			end
			-- Limita para não lotar a tela quando muita gente descobre ao mesmo tempo.
			local now = os.clock()
			while remoteAnnounceTimes[1] and now - remoteAnnounceTimes[1] > 60 do
				table.remove(remoteAnnounceTimes, 1)
			end
			if #remoteAnnounceTimes >= MAX_REMOTE_ANNOUNCES_PER_MINUTE then
				return
			end
			table.insert(remoteAnnounceTimes, now)
			Announce.all("announce.worldFirst", { player = payload.player, recipe = payload.recipe }, "world")
		end)
	end)
	if not ok then
		warn(`[DiscoveryService] MessagingService indisponível: {err}`)
	end
end

local function startWorkers()
	-- Fila do registro mundial: um por vez, respeitando o limite do DataStore.
	task.spawn(function()
		while true do
			local item = table.remove(queue, 1)
			if item then
				local budget = DataStoreService:GetRequestBudgetForRequestType(Enum.DataStoreRequestType.UpdateAsync)
				if budget < 1 then
					table.insert(queue, 1, item)
					task.wait(2)
				else
					processEntry(item.player, item.key, item.recipeName)
				end
			else
				task.wait(0.5)
			end
		end
	end)

	-- Publica anúncios para os outros servidores (no máximo 1 a cada PUBLISH_INTERVAL).
	task.spawn(function()
		while true do
			task.wait(PUBLISH_INTERVAL)
			local message = table.remove(publishQueue, 1)
			if message then
				local ok, err = pcall(MessagingService.PublishAsync, MessagingService, TOPIC, message)
				if not ok then
					warn(`[DiscoveryService] falha ao publicar anúncio: {err}`)
				end
			end
		end
	end)

	-- Atualiza o ranking dos jogadores que descobriram algo.
	task.spawn(function()
		while true do
			task.wait(RANKING_FLUSH_INTERVAL)
			for player in rankingDirty do
				local data = DataService.get(player)
				if data then
					task.spawn(flushRanking, player.UserId, countDiscovered(data))
				end
			end
			table.clear(rankingDirty)
		end
	end)
end

function DiscoveryService.init()
	openStores()
	task.spawn(subscribe)
	startWorkers()

	-- Ao entrar: re-tenta registrar receitas que ficaram pendentes.
	DataService.loaded:Connect(function(player: Player, data: PlayerData)
		local retried = 0
		for recipeKey, entry in data.discovered do
			if entry.by == nil then
				local info = RecipeService.resolve(recipeKey)
				DiscoveryService.register(player, recipeKey, if info then info.name else recipeKey)
				retried += 1
				if retried >= RETRY_ON_JOIN then
					break
				end
			end
		end
		ensureWeek(data, currentWeek())
	end)

	DataService.releasing:Connect(function(player: Player, data: PlayerData)
		if rankingDirty[player] then
			rankingDirty[player] = nil
			task.spawn(flushRanking, player.UserId, countDiscovered(data))
		end
	end)

	Net.onInvoke("GetGrimoireInfo", function(player)
		local data = DataService.get(player)
		if not data then
			return Net.fail("error.notLoaded")
		end
		local week = currentWeek()
		ensureWeek(data, week)
		local secrets: { Types.WeeklySecret } = {}
		for _, secret in weekSecrets(week) do
			table.insert(secrets, {
				hint = secret.hint,
				reward = SecretRecipes.rewardCoins,
				found = data.weekly.claimed[secret.key] == true,
			})
		end
		local info: Types.GrimoireInfo = {
			secrets = secrets,
			weekEndsAt = (week + 1) * WEEK_SECONDS + WEEK_OFFSET,
			totalCombinations = RecipeKey.totalCombinations(#Ingredients.list, Economy.maxIngredientsPerBrew),
		}
		return Net.ok(info)
	end)

	Net.onInvoke("GetRanking", function(_player)
		if os.clock() - rankingCache.fetchedAt > RANKING_CACHE_SECONDS then
			fetchRanking()
		end
		return Net.ok(rankingCache.entries)
	end)
end

return DiscoveryService
