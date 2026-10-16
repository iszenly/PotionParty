--!strict
--[[
	Theme.luau
	Cores, fontes e tamanhos da interface. Mude aqui para mudar o visual todo.
	Tamanhos pensados para celular: botões com no mínimo ~48px de altura.
]]

return {
	font = Enum.Font.FredokaOne,
	fontBody = Enum.Font.GothamBold,

	corner = 14,
	buttonHeight = 52,

	colors = {
		background = Color3.fromRGB(30, 22, 48),
		panel = Color3.fromRGB(58, 42, 92),
		panelLight = Color3.fromRGB(80, 60, 125),
		stroke = Color3.fromRGB(25, 15, 40),
		text = Color3.fromRGB(255, 255, 255),
		textDim = Color3.fromRGB(200, 190, 225),
		button = Color3.fromRGB(130, 90, 220),
		good = Color3.fromRGB(70, 190, 100),
		bad = Color3.fromRGB(220, 70, 80),
		gold = Color3.fromRGB(255, 200, 60),
		disabled = Color3.fromRGB(100, 95, 115),
	},
}
