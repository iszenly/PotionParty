--!strict
--[[
	Validate.luau
	Checagens dos argumentos que chegam do cliente. NUNCA confie no cliente:
	um exploiter pode mandar qualquer coisa (texto gigante, NaN, tabelas
	estranhas, números negativos...). Tudo passa por aqui antes de ser usado.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Ingredients = require(ReplicatedStorage.Shared.Config.Ingredients)

local Validate = {}

-- Número inteiro dentro do intervalo [min, max]. Rejeita NaN e infinito.
function Validate.integer(value: any, min: number, max: number): boolean
	return type(value) == "number" and value == value and value % 1 == 0 and value >= min and value <= max
end

-- Texto com tamanho limitado.
function Validate.text(value: any, maxLength: number): boolean
	return type(value) == "string" and #value > 0 and #value <= maxLength
end

function Validate.ingredientId(value: any): boolean
	return Validate.text(value, 32) and Ingredients.byId[value] ~= nil
end

-- Lista de 1..maxCount ids de ingredientes válidos. Retorna uma CÓPIA limpa ou nil.
function Validate.ingredientList(value: any, maxCount: number): { string }?
	if type(value) ~= "table" then
		return nil
	end
	-- Conta TODAS as chaves (não só as numéricas) para rejeitar tabelas estranhas.
	local count = 0
	for _ in value do
		count += 1
		if count > maxCount then
			return nil
		end
	end
	if count < 1 then
		return nil
	end
	local result: { string } = {}
	for i = 1, count do
		local id = value[i]
		if not Validate.ingredientId(id) then
			return nil
		end
		result[i] = id
	end
	return result
end

return Validate
