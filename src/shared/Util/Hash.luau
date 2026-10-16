--!strict
--[[
	Hash.luau
	Transforma um texto em um número inteiro de 32 bits (algoritmo FNV-1a).
	O mesmo texto sempre gera o mesmo número, em qualquer servidor. Usamos isso
	como "semente" do Random para que a mesma receita gere sempre a mesma poção.
]]

local Hash = {}

local OFFSET_BASIS = 2166136261
local TWO_POW_32 = 4294967296

function Hash.fnv1a(text: string): number
	local hash = OFFSET_BASIS
	for i = 1, #text do
		hash = bit32.bxor(hash, string.byte(text, i))
		-- hash * 16777619 estoura a precisão do número; então dividimos a conta:
		-- 16777619 = 2^24 + 403
		hash = (bit32.lshift(hash, 24) + hash * 403) % TWO_POW_32
	end
	return hash
end

return Hash
