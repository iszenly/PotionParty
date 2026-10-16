--!strict
--[[
	SplashService.luau
	Arremessar uma poção como RESPINGO: o frasco voa até o alvo e transforma
	quem estiver perto do impacto por poucos segundos (Config/Social.luau).

	Proteções (tudo conferido no servidor):
	- não dá para arremessar de dentro de uma zona segura (lobby e lojas);
	- quem está numa zona segura ou com o Modo Escudo ligado não é afetado;
	- alcance máximo e intervalo entre arremessos;
	- quem arremessa nunca é atingido pelo próprio respingo.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Shared.Types)
local Social = require(ReplicatedStorage.Shared.Config.Social)
local Mutations = require(ReplicatedStorage.Shared.Config.Mutations)
local RecipeKey = require(ReplicatedStorage.Shared.Util.RecipeKey)
local Net = require(script.Parent.Parent.Net)
local Announce = require(script.Parent.Parent.Announce)
local Validate = require(script.Parent.Parent.Util.Validate)
local DataService = require(script.Parent.DataService)
local SyncService = require(script.Parent.SyncService)
local RecipeService = require(script.Parent.RecipeService)
local EffectService = require(script.Parent.EffectService)
local MapService = require(script.Parent.MapService)
local MissionService = require(script.Parent.MissionService)

local splashEvent = Net.event("Splash")
local lastThrow: { [Player]: number } = {}

local SplashService = {}

local function rootOf(player: Player): BasePart?
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if humanoid and humanoid.Health > 0 and root and root:IsA("BasePart") then
		return root
	end
	return nil
end

local function resolveSplash(thrower: Player, impact: Vector3, info: Types.RecipeInfo, mutationId: string?)
	local mutation = if mutationId then Mutations.byId[mutationId] else nil
	local hits = 0
	for _, target in Players:GetPlayers() do
		local root = if target ~= thrower then rootOf(target) else nil
		if root and (root.Position - impact).Magnitude <= Social.splashRadius then
			local data = DataService.get(target)
			if MapService.inSafeZone(root.Position) or (data and data.settings.shield) then
				Announce.player(thrower, "announce.splashBlocked", { name = target.DisplayName }, "toast")
			else
				local effect = table.clone(info.effect)
				effect.duration = Social.splashDuration
				local overlay = if mutation then mutation.overlay else nil
				if EffectService.apply(target, effect, info.name, overlay, info.color) then
					hits += 1
					Announce.player(target, "announce.splashedBy", { name = thrower.DisplayName }, "toast")
				end
			end
		end
	end
	if hits > 0 then
		MissionService.progress(thrower, "splash", hits)
	end
end

function SplashService.init()
	Players.PlayerRemoving:Connect(function(player)
		lastThrow[player] = nil
	end)

	-- targetUserId é opcional: sem alvo, o frasco cai à frente do jogador.
	Net.onInvoke("ThrowPotion", function(player, stackKey: any, targetUserId: any)
		local data = DataService.get(player)
		if not data then
			return Net.fail("error.notLoaded")
		end
		if not Validate.text(stackKey, 160) then
			return Net.fail("error.invalid")
		end
		if targetUserId ~= nil and not Validate.integer(targetUserId, 1, 2 ^ 52) then
			return Net.fail("error.invalid")
		end
		if (data.potions[stackKey] or 0) < 1 then
			return Net.fail("error.noPotion")
		end
		local now = os.clock()
		if (lastThrow[player] or 0) + Social.splashCooldown > now then
			return Net.fail("error.splashCooldown")
		end
		local root = rootOf(player)
		if not root then
			return Net.fail("error.noCharacter")
		end
		if MapService.inSafeZone(root.Position) then
			return Net.fail("error.safeZone")
		end
		local recipeKey, mutationId = RecipeKey.splitStack(stackKey)
		local info = RecipeService.resolve(recipeKey)
		if not info then
			return Net.fail("error.invalid")
		end

		local impact: Vector3
		if targetUserId then
			local target = Players:GetPlayerByUserId(targetUserId)
			local targetRoot = if target and target ~= player then rootOf(target) else nil
			-- Um pouco de folga no alcance por causa do atraso da rede.
			if not targetRoot or (targetRoot.Position - root.Position).Magnitude > Social.splashRange + 6 then
				return Net.fail("error.splashTooFar")
			end
			impact = targetRoot.Position
		else
			impact = root.Position + root.CFrame.LookVector * (Social.splashRange * 0.5)
		end

		lastThrow[player] = now
		local left = data.potions[stackKey] - 1
		if left <= 0 then
			(data.potions :: any)[stackKey] = nil
		else
			data.potions[stackKey] = left
		end
		SyncService.push(player)

		splashEvent:FireAllClients(root.Position + Vector3.new(0, 2, 0), impact, info.color, Social.splashTravelTime)
		task.delay(Social.splashTravelTime, resolveSplash, player, impact, info, mutationId)
		return Net.ok()
	end)
end

return SplashService
