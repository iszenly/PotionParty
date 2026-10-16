--!strict
--[[
	Format.luau
	Formatação de números e tempos para a interface.
]]

local Locale = require(script.Parent.Parent.Locale)

local Format = {}

-- 1234567 -> "1.234.567" (o separador vem do Locale)
function Format.number(value: number): string
	local text = tostring(math.floor(value))
	local separator = Locale.t("format.thousands")
	local sign = ""
	if string.sub(text, 1, 1) == "-" then
		sign = "-"
		text = string.sub(text, 2)
	end
	local result = string.reverse((string.gsub(string.reverse(text), "(%d%d%d)", "%1" .. separator)))
	if string.sub(result, 1, #separator) == separator then
		result = string.sub(result, #separator + 1)
	end
	return sign .. result
end

-- 65 -> "1:05", 3725 -> "1:02:05"
function Format.time(seconds: number): string
	local total = math.max(0, math.ceil(seconds))
	local hours = total // 3600
	local minutes = (total % 3600) // 60
	local secs = total % 60
	if hours > 0 then
		return string.format("%d:%02d:%02d", hours, minutes, secs)
	end
	return string.format("%d:%02d", minutes, secs)
end

return Format
