--!strict
--[[
	PlayerStats.luau
	Valores calculados a partir dos dados do jogador + configurações.
	Fica em "shared" para servidor e cliente usarem exatamente a mesma conta
	(o cliente só usa para MOSTRAR; quem decide é sempre o servidor).
]]

local Shared = script.Parent.Parent
local Types = require(Shared.Types)
local Economy = require(Shared.Config.Economy)
local Ingredients = require(Shared.Config.Ingredients)
local Rarities = require(Shared.Config.Rarities)
local Upgrades = require(Shared.Config.Upgrades)
local Shop = require(Shared.Config.Shop)
local Rebirth = require(Shared.Config.Rebirth)

type PlayerData = Types.PlayerData

local PlayerStats = {}

function PlayerStats.level(data: PlayerData, upgradeId: string): number
	return data.upgrades[upgradeId] or 0
end

local function perLevel(upgradeId: string): number
	local def = Upgrades.byId[upgradeId]
	return if def then def.valuePerLevel else 0
end

-- O jogador tem este Game Pass? (data.passes é atualizado ao entrar no jogo)
function PlayerStats.hasPass(data: PlayerData, passKey: string): boolean
	return data.passes[passKey] == true
end

function PlayerStats.cauldronCount(data: PlayerData): number
	local count = 1 + PlayerStats.level(data, "ExtraCauldron") * perLevel("ExtraCauldron")
	if PlayerStats.hasPass(data, "ExtraCauldron") then
		count += 1
	end
	return count
end

-- Clientes NPC ao mesmo tempo na loja.
function PlayerStats.maxCustomers(data: PlayerData): number
	local count = Shop.baseCustomers + PlayerStats.level(data, "ShopShelves") * perLevel("ShopShelves")
	if PlayerStats.hasPass(data, "BigShop") then
		count += Shop.bigShopExtraCustomers
	end
	return count
end

-- Chance de um pedido ser especial (dois efeitos).
function PlayerStats.specialOrderChance(data: PlayerData): number
	return Shop.baseSpecialChance + PlayerStats.level(data, "ShopShowcase") * perLevel("ShopShowcase")
end

function PlayerStats.potionCapacity(data: PlayerData): number
	return Economy.basePotionCapacity + PlayerStats.level(data, "Storage") * perLevel("Storage")
end

function PlayerStats.potionCount(data: PlayerData): number
	local total = 0
	for _, count in data.potions do
		total += count
	end
	return total
end

-- Multiplicador do tempo de preparo (0.9 ^ nível com valuePerLevel = 0.1).
function PlayerStats.brewTimeMultiplier(data: PlayerData): number
	return (1 - perLevel("BrewSpeed")) ^ PlayerStats.level(data, "BrewSpeed")
end

-- Multiplicador de venda: melhoria Vitrine Brilhante x Novo Mestre (rebirth).
-- O bônus de amigos é aplicado no servidor (RewardService), pois depende de quem está online.
function PlayerStats.sellMultiplier(data: PlayerData): number
	local upgrade = 1 + perLevel("SellPrice") * PlayerStats.level(data, "SellPrice")
	return upgrade * Rebirth.multiplier(data.rebirths)
end

-- Tempo de preparo em segundos inteiros para uma lista de ingredientes.
function PlayerStats.brewSeconds(data: PlayerData, ids: { string }): number
	local seconds = Economy.brewBaseSeconds
	for _, id in ids do
		local def = Ingredients.byId[id]
		if def then
			seconds += Rarities[def.rarity].brewSeconds
		end
	end
	return math.max(1, math.ceil(seconds * PlayerStats.brewTimeMultiplier(data)))
end

-- Sorte nas mutações (1 = normal). Multiplica a chance de cada mutação.
function PlayerStats.luck(data: PlayerData): number
	return if PlayerStats.hasPass(data, "VipLuck") then 2 else 1
end

-- Quanto o jogador recebe ao vender UMA poção com valor base "baseValue".
-- (Para poções com mutação, passe value * Mutations.priceMultiplier(id).)
function PlayerStats.sellPrice(data: PlayerData, baseValue: number): number
	return math.max(1, math.floor(baseValue * PlayerStats.sellMultiplier(data) + 0.5))
end

return PlayerStats
