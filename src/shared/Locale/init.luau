--!strict
--[[
	Locale
	Textos da interface. Todo texto visível passa por aqui:
		Locale.t("ui.brew")                      -> "Preparar!"
		Locale.t("ui.sold", { coins = 50 })       -> "Vendido por 50 moedas!"

	Idiomas ficam em arquivos separados (ptBR.luau, en.luau). Se uma chave não
	existir no idioma atual, usamos o português; se não existir em nenhum,
	mostramos a própria chave (fácil de achar o que falta traduzir).

	Nomes de ingredientes, traços e melhorias ficam em português nos arquivos de
	Config. Para traduzir, adicione no en.luau: ["ingredient.Mushroom"] = "Mushroom".
]]

local ptBR = require(script.ptBR)
local en = require(script.en)

local DEFAULT_LANGUAGE = "pt-br"

local languages: { [string]: { [string]: string } } = {
	["pt-br"] = ptBR,
	en = en,
}

local current = DEFAULT_LANGUAGE

local Locale = {}

function Locale.setLanguage(code: string)
	if languages[code] then
		current = code
	end
end

function Locale.getLanguage(): string
	return current
end

-- Converte o LocaleId do Roblox ("pt-br", "en-us"...) para um idioma suportado.
function Locale.fromRobloxLocale(localeId: string): string
	local lower = string.lower(localeId)
	if string.sub(lower, 1, 2) == "pt" then
		return "pt-br"
	elseif string.sub(lower, 1, 2) == "en" then
		return "en"
	end
	return DEFAULT_LANGUAGE
end

function Locale.t(key: string, params: { [string]: any }?): string
	local text = languages[current][key] or languages[DEFAULT_LANGUAGE][key] or key
	if params then
		text = string.gsub(text, "{(%w+)}", function(name: string): string
			local value = params[name]
			return if value ~= nil then tostring(value) else "{" .. name .. "}"
		end)
	end
	return text
end

-- Nome traduzido de algo que vem da Config (ingrediente, traço, melhoria...).
function Locale.name(kind: string, id: string, fallback: string): string
	return languages[current][kind .. "." .. id] or fallback
end

return Locale
