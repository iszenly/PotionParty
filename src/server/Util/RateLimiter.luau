--!strict
--[[
	RateLimiter.luau
	Limita quantas vezes cada jogador pode chamar cada Remote ("token bucket"):
	cada jogador tem um "balde" de fichas por Remote. Cada chamada gasta 1 ficha
	e as fichas voltam aos poucos (rate por segundo), até o máximo (burst).
]]

local Players = game:GetService("Players")

type Bucket = { tokens: number, last: number }

local buckets: { [Player]: { [string]: Bucket } } = {}

local RateLimiter = {}

function RateLimiter.allow(player: Player, name: string, rate: number, burst: number): boolean
	local perPlayer = buckets[player]
	if not perPlayer then
		perPlayer = {}
		buckets[player] = perPlayer
	end

	local now = os.clock()
	local bucket = perPlayer[name]
	if not bucket then
		bucket = { tokens = burst, last = now }
		perPlayer[name] = bucket
	end

	-- Recupera fichas pelo tempo que passou desde a última chamada.
	bucket.tokens = math.min(burst, bucket.tokens + (now - bucket.last) * rate)
	bucket.last = now

	if bucket.tokens < 1 then
		return false
	end
	bucket.tokens -= 1
	return true
end

Players.PlayerRemoving:Connect(function(player)
	buckets[player] = nil
end)

return RateLimiter
