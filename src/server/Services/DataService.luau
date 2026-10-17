--!strict
--[[
	DataService.luau
	Carrega e salva os dados de cada jogador usando ProfileStore.

	POR QUE PROFILESTORE?
	Salvar dados no Roblox parece simples (DataStore:SetAsync), mas tem armadilhas:
	- "session locking": se o jogador troca de servidor rápido, dois servidores
	  podem salvar ao mesmo tempo e um apagar o progresso do outro (ou permitir
	  duplicar itens). O ProfileStore trava o perfil para um servidor por vez.
	- autosave periódico, salvamento ao sair e ao fechar o servidor (BindToClose);
	- limites de requisição do DataStore e tentativas em caso de falha.
	Ele é mantido pelo autor do ProfileService (loleris) e usado em muitos jogos
	grandes. Fica em Packages/ProfileStore.luau.

	No Studio SEM "Enable Studio Access to API Services", o ProfileStore usa um
	DataStore falso (mock): tudo funciona, mas nada é salvo entre testes.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ProfileStore = require(ServerScriptService.Packages.ProfileStore)
local Types = require(ReplicatedStorage.Shared.Types)
local Economy = require(ReplicatedStorage.Shared.Config.Economy)
local Ingredients = require(ReplicatedStorage.Shared.Config.Ingredients)
local Signal = require(ReplicatedStorage.Shared.Util.Signal)
local Locale = require(ReplicatedStorage.Shared.Locale)

type PlayerData = Types.PlayerData

-- Mude o nome do store só se quiser "zerar" todos os dados (ex.: antes de lançar).
local STORE_NAME = "PotionParty_PlayerData_v1"
local DATA_VERSION = 2

-- Dados iniciais de um jogador novo. Reconcile() também usa este molde para
-- preencher campos novos em jogadores antigos quando adicionarmos coisas.
local function buildTemplate(): PlayerData
	local ingredients: { [string]: number } = {}
	local unlocked: { [string]: boolean } = {}
	for _, def in Ingredients.list do
		if def.unlockPrice == 0 and not def.cometOnly then
			ingredients[def.id] = Economy.startingIngredientAmount
			unlocked[def.id] = true
		end
	end

	return {
		version = DATA_VERSION,
		coins = Economy.startingCoins,
		ingredients = ingredients,
		unlocked = unlocked,
		potions = {},
		upgrades = {},
		cauldrons = {},
		discovered = {},
		worldFirsts = 0,
		weekly = { week = 0, claimed = {} },
		streak = { count = 0, lastClaimDay = 0 },
		missions = { day = 0, list = {} },
		rebirths = 0,
		lastLogout = 0,
		settings = { shield = false },
		stats = { brewed = 0, sold = 0, drunk = 0, coinsEarned = 0 },
		shop = { likes = 0, visits = 0, served = 0 },
		likesGiven = { day = 0, users = {} },
		passes = {},
		receipts = {},
		cosmetics = { owned = {} },
	}
end

local store = ProfileStore.New(STORE_NAME, buildTemplate())
local profiles: { [Player]: any } = {}

local DataService = {}

-- Dispara (player, data, lastSeen) quando os dados de um jogador terminam de carregar.
-- lastSeen = os.time() da última vez que o jogador foi "visto" (último salvamento da
-- sessão anterior). Use ESTE valor para calcular tempo offline, não data.lastLogout
-- (que já foi atualizado para "agora" antes do sinal disparar).
DataService.loaded = Signal.new()
-- Dispara (player, data) logo antes de liberar os dados (jogador saindo).
DataService.releasing = Signal.new()

-- Retorna os dados do jogador, ou nil se ainda não carregaram.
-- IMPORTANTE: só altere estes dados no servidor e depois chame SyncService.push.
function DataService.get(player: Player): PlayerData?
	local profile = profiles[player]
	if profile then
		return profile.Data :: PlayerData
	end
	return nil
end

-- O perfil do ProfileStore (para Save e LastSavedData). Use só quando precisar.
function DataService.getProfile(player: Player): any
	return profiles[player]
end

-- Pede um salvamento imediato (ex.: depois de uma troca). Não espera terminar.
function DataService.save(player: Player)
	local profile = profiles[player]
	if profile and profile:IsActive() then
		profile:Save()
	end
end

-- Atualiza dados antigos para o formato atual (quando DATA_VERSION mudar).
local function migrate(data: PlayerData)
	if data.version < 2 then
		-- v1 guardava só o horário da descoberta (número). v2 guarda uma tabela.
		local discovered = data.discovered :: { [string]: any }
		for key, value in discovered do
			if type(value) == "number" then
				discovered[key] = { t = value }
			end
		end
	end
	-- Exemplo para o futuro:
	-- if data.version < 3 then ... end
	data.version = DATA_VERSION
end

local function onPlayerAdded(player: Player)
	local profile = store:StartSessionAsync(`Player_{player.UserId}`, {
		-- Para de tentar se o jogador sair enquanto carrega.
		Cancel = function()
			return player.Parent ~= Players
		end,
	})

	if profile == nil then
		-- Não conseguiu travar a sessão (outro servidor segurando, DataStore fora do ar...).
		player:Kick(Locale.t("kick.loadFailed"))
		return
	end

	profile:AddUserId(player.UserId) -- exigência de GDPR/LGPD
	profile:Reconcile() -- preenche campos que faltam com o molde

	profile.OnSessionEnd:Connect(function()
		profiles[player] = nil
		player:Kick(Locale.t("kick.sessionEnded"))
	end)

	if player.Parent ~= Players then
		-- O jogador saiu enquanto carregava. Salva sem mexer em "lastLogout",
		-- para o tempo offline continuar contando até a próxima entrada.
		profile:EndSession()
		return
	end

	migrate(profile.Data)

	--[[
		Tempo offline (correção P3):
		"lastLogout" significa "até quando o tempo offline já foi contabilizado".
		1. Guardamos o valor antigo (lastSeen) para a venda offline usar.
		2. Marcamos "agora" ANTES de qualquer pagamento offline. Tudo isso roda sem
		   pausas (sem task.wait), então nenhum salvamento acontece no meio: qualquer
		   gravação que tiver as moedas da venda offline também terá o horário novo.
		   Assim um servidor que cai depois não faz a venda offline pagar duas vezes.
		3. A cada salvamento (autosave, compra, troca) atualizamos o horário de novo:
		   se o servidor cair, o próximo login só conta o tempo depois do último
		   salvamento, e não o tempo em que o jogador estava online.
	]]
	local lastSeen = profile.Data.lastLogout
	profile.Data.lastLogout = os.time()
	profile.OnSave:Connect(function()
		profile.Data.lastLogout = os.time()
	end)
	-- Último salvamento (saída, fechamento do servidor ou outro servidor pegando a sessão).
	profile.OnLastSave:Connect(function()
		profile.Data.lastLogout = os.time()
	end)

	profiles[player] = profile
	DataService.loaded:Fire(player, profile.Data, lastSeen)
end

function DataService.init()
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end
	Players.PlayerAdded:Connect(onPlayerAdded)

	Players.PlayerRemoving:Connect(function(player)
		local profile = profiles[player]
		if profile then
			DataService.releasing:Fire(player, profile.Data)
			profile.Data.lastLogout = os.time()
			profile:EndSession() -- salva e libera a trava da sessão
			profiles[player] = nil
		end
	end)
	-- O ProfileStore já registra game:BindToClose para salvar todos ao desligar o servidor.
end

return DataService
