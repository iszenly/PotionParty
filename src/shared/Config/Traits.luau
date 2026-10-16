--!strict
--[[
	Traits.luau
	Os "traços" são as peças que montam o efeito de uma poção.
	Cada traço pertence a uma categoria:
		size     -> tamanho (gigante, mini)
		form     -> aparência (sapo, fantasma, pedra...)
		movement -> movimento (voar, quicar, correr...)
		visual   -> efeito visual (brilho, fogo, purpurina...)

	Uma poção tem no máximo 1 traço por categoria. A ordem desta lista é
	usada como critério de desempate, então mantenha-a estável.

	Para criar um traço novo: adicione aqui e use o id dele no "traits" de
	algum ingrediente. Se for um tipo de efeito novo, ensine o EffectService.
]]

local Types = require(script.Parent.Parent.Types)

-- TODO(asset): formas usam só cor/material + peças simples. Trocar por modelos finais.
local list: { Types.TraitDef } = {
	-- Tamanho
	{ id = "Giant", category = "size", name = "Gigante", scale = 2 },
	{ id = "Mini", category = "size", name = "Mini", scale = 0.5 },

	-- Forma
	{
		id = "Frog",
		category = "form",
		name = "Sapo",
		color = Color3.fromRGB(76, 175, 80),
		material = Enum.Material.SmoothPlastic,
		prop = "FrogEyes",
	},
	{
		id = "Ghost",
		category = "form",
		name = "Fantasma",
		color = Color3.fromRGB(225, 235, 255),
		material = Enum.Material.SmoothPlastic,
		transparency = 0.55,
	},
	{
		id = "Rock",
		category = "form",
		name = "Pedra",
		color = Color3.fromRGB(120, 120, 125),
		material = Enum.Material.Slate,
	},
	{
		id = "Cloud",
		category = "form",
		name = "Nuvem",
		color = Color3.fromRGB(250, 250, 255),
		material = Enum.Material.SmoothPlastic,
		prop = "CloudPuffs",
	},
	{
		id = "Metal",
		category = "form",
		name = "Robô",
		color = Color3.fromRGB(165, 175, 185),
		material = Enum.Material.DiamondPlate,
	},
	{
		id = "Pizza",
		category = "form",
		name = "Pizza",
		color = Color3.fromRGB(240, 175, 60),
		material = Enum.Material.Sand,
	},

	-- Movimento
	{ id = "Fly", category = "movement", name = "Voar", antiGravity = 0.92, jumpMult = 1.2, canFly = true },
	{ id = "Floaty", category = "movement", name = "Flutuar", antiGravity = 0.6, jumpMult = 1.3 },
	{ id = "Bouncy", category = "movement", name = "Quicar", jumpMult = 2.2 },
	{ id = "Speedy", category = "movement", name = "Correr Rápido", speedMult = 1.9 },
	{ id = "Slow", category = "movement", name = "Câmera Lenta", speedMult = 0.55, jumpMult = 0.8 },

	-- Visual
	{
		id = "Glow",
		category = "visual",
		name = "Brilhar",
		visualKind = "Light",
		visualColor = Color3.fromRGB(255, 230, 120),
	},
	{
		id = "Fire",
		category = "visual",
		name = "Fogo Mágico",
		visualKind = "Fire",
		visualColor = Color3.fromRGB(255, 120, 30),
	},
	{
		id = "Sparkle",
		category = "visual",
		name = "Purpurina",
		visualKind = "Sparkles",
		visualColor = Color3.fromRGB(255, 150, 255),
	},
	{
		id = "Snow",
		category = "visual",
		name = "Nevar",
		visualKind = "Particles",
		visualColor = Color3.fromRGB(225, 240, 255),
	},
	{
		id = "Electric",
		category = "visual",
		name = "Choquinho",
		visualKind = "Particles",
		visualColor = Color3.fromRGB(255, 240, 80),
	},
	{
		id = "Bubbles",
		category = "visual",
		name = "Bolhas",
		visualKind = "Particles",
		visualColor = Color3.fromRGB(140, 210, 255),
	},
	{ id = "Rainbow", category = "visual", name = "Arco-íris", visualKind = "Rainbow" },
	{
		id = "Cosmic",
		category = "visual",
		name = "Cósmico",
		visualKind = "Particles",
		visualColor = Color3.fromRGB(180, 120, 255),
	},
	-- Usado só pela mutação Dourada (nenhum ingrediente tem este traço).
	{
		id = "GoldAura",
		category = "visual",
		name = "Aura Dourada",
		visualKind = "Highlight",
		visualColor = Color3.fromRGB(255, 200, 40),
	},
}

local byId: { [string]: Types.TraitDef } = {}
for _, def in list do
	byId[def.id] = def
end

return {
	list = list,
	byId = byId,
	categories = { "size", "form", "movement", "visual" } :: { Types.TraitCategory },
}
