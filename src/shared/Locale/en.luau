--!strict
-- English texts. Missing keys fall back to Portuguese (ptBR.luau).
-- TODO(localização): completar a tradução antes de lançar em inglês.

local strings: { [string]: string } = {
	["format.thousands"] = ",",

	["ui.coins"] = "Coins",
	["ui.potions"] = "Potions",
	["ui.upgrades"] = "Upgrades",
	["ui.cauldron"] = "Cauldron",
	["ui.cauldronN"] = "Cauldron {n}",
	["ui.market"] = "Market",
	["ui.brew"] = "Brew!",
	["ui.collect"] = "Collect!",
	["ui.drink"] = "Drink",
	["ui.sell1"] = "Sell 1",
	["ui.sellAll"] = "Sell all",
	["ui.keep"] = "Keep",
	["ui.newRecipe"] = "NEW RECIPE!",

	["ingredient.Mushroom"] = "Mushroom",
	["ingredient.Feather"] = "Feather",
	["ingredient.Pepper"] = "Pepper",
	["ingredient.Ice"] = "Ice",
	["ingredient.Honey"] = "Honey",
	["ingredient.Stone"] = "Stone",
}

return strings
