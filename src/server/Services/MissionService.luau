--!strict
--[[
	MissionService.luau
	Missões diárias e recompensa diária com sequência (streak).

	Outros serviços avisam o progresso:
		MissionService.progress(player, "brew", 1)
	Os tipos são os "id" de Config/Missions.luau.
	O "dia" é o dia UTC (os.time() // 86400), igual para todos os servidores.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Shared.Types)
local Missions = require(ReplicatedStorage.Shared.Config.Missions)
local Daily = require(ReplicatedStorage.Shared.Config.Daily)
local Ingredients = require(ReplicatedStorage.Shared.Config.Ingredients)
local Net = require(script.Parent.Parent.Net)
local Validate = require(script.Parent.Parent.Util.Validate)
local DataService = require(script.Parent.DataService)
local SyncService = require(script.Parent.SyncService)
local IngredientService = require(script.Parent.IngredientService)

type PlayerData = Types.PlayerData

local MissionService = {}

local function today(): number
	return os.time() // 86400
end

-- Sorteia as missões do dia (se ainda não foram sorteadas hoje).
local function ensureMissions(player: Player, data: PlayerData)
	local day = today()
	if data.missions.day == day and #data.missions.list > 0 then
		return
	end
	-- Semente = jogador + dia: sair e voltar não troca as missões.
	local rng = Random.new((player.UserId % 1000000) * 1000 + day % 1000)
	local pool = table.clone(Missions.list)
	for i = #pool, 2, -1 do
		local j = rng:NextInteger(1, i)
		pool[i], pool[j] = pool[j], pool[i]
	end
	local list: { Types.MissionState } = {}
	for i = 1, math.min(Missions.perDay, #pool) do
		local def = pool[i]
		local step = def.step or 1
		local target = rng:NextInteger(def.min // step, def.max // step) * step
		table.insert(list, {
			id = def.id,
			target = target,
			progress = 0,
			reward = math.max(Missions.minReward, math.floor(target * def.rewardPerUnit)),
			claimed = false,
		})
	end
	data.missions = { day = day, list = list }
end

-- Soma progresso nas missões do tipo "kind".
function MissionService.progress(player: Player, kind: string, amount: number)
	local data = DataService.get(player)
	if not data or amount <= 0 then
		return
	end
	ensureMissions(player, data)
	for _, mission in data.missions.list do
		if mission.id == kind and not mission.claimed and mission.progress < mission.target then
			mission.progress = math.min(mission.target, mission.progress + amount)
		end
	end
	SyncService.push(player)
end

function MissionService.init()
	DataService.loaded:Connect(function(player: Player, data: PlayerData)
		ensureMissions(player, data)
		SyncService.push(player)
	end)

	Net.onInvoke("ClaimMission", function(player, index: any)
		local data = DataService.get(player)
		if not data then
			return Net.fail("error.notLoaded")
		end
		ensureMissions(player, data)
		if not Validate.integer(index, 1, #data.missions.list) then
			return Net.fail("error.invalid")
		end
		local mission = data.missions.list[index]
		if mission.claimed then
			return Net.fail("error.alreadyClaimed")
		end
		if mission.progress < mission.target then
			return Net.fail("error.missionNotDone")
		end
		mission.claimed = true
		data.coins += mission.reward
		data.stats.coinsEarned += mission.reward
		SyncService.push(player)
		return Net.ok({ reward = mission.reward })
	end)

	Net.onInvoke("ClaimDaily", function(player)
		local data = DataService.get(player)
		if not data then
			return Net.fail("error.notLoaded")
		end
		local day = today()
		local streak = data.streak
		if streak.lastClaimDay == day then
			return Net.fail("error.alreadyClaimed")
		end
		-- Ontem? Continua a sequência. Senão, recomeça do dia 1.
		streak.count = if streak.lastClaimDay == day - 1 then streak.count + 1 else 1
		streak.lastClaimDay = day

		local reward = Daily.rewards[((streak.count - 1) % #Daily.rewards) + 1]
		data.coins += reward.coins
		data.stats.coinsEarned += reward.coins
		if reward.ingredients then
			for id, amount in reward.ingredients do
				if Ingredients.byId[id] then
					IngredientService.add(data, id, amount)
				end
			end
		end
		SyncService.push(player)
		return Net.ok({ streak = streak.count, coins = reward.coins })
	end)
end

return MissionService
