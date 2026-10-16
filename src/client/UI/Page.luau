--!strict
--[[
	Page.luau
	Atalho para criar uma janela padrão já registrada no Router:
		local page = Page.create(screen, "Missions", "🎯 Missões", render)
		page.content   -- onde colocar os elementos
		page.isOpen()  -- a janela está aberta?
	E Page.row(...) cria uma "linha" de lista com o visual padrão.
]]

local UI = require(script.Parent.Components)
local Theme = require(script.Parent.Theme)
local Router = require(script.Parent.Router)

export type Page = {
	root: Frame,
	content: Frame,
	title: TextLabel,
	isOpen: () -> boolean,
}

local Page = {}

-- onOpen: chamado ao abrir. onCloseButton: chamado quando o jogador toca no X.
function Page.create(
	screen: ScreenGui,
	name: string,
	title: string,
	onOpen: (() -> ())?,
	onCloseButton: (() -> ())?
): Page
	local open = false
	local root, content, titleLabel = UI.panel(screen, title, function()
		if onCloseButton then
			onCloseButton()
		end
		Router.close()
	end)
	Router.register(name, {
		open = function()
			open = true
			root.Visible = true
			if onOpen then
				onOpen()
			end
		end,
		close = function()
			open = false
			root.Visible = false
		end,
	})
	return {
		root = root,
		content = content,
		title = titleLabel,
		isOpen = function()
			return open
		end,
	}
end

function Page.row(parent: Instance, order: number, height: number): Frame
	local row: Frame = UI.new("Frame", {
		LayoutOrder = order,
		Size = UDim2.new(1, -10, 0, height),
		BackgroundColor3 = Theme.colors.panelLight,
		Parent = parent,
	})
	UI.corner(row)
	return row
end

-- Lista com rolagem ocupando a área indicada.
function Page.list(parent: Instance, top: number): ScrollingFrame
	local list = UI.scroll({
		Position = UDim2.fromOffset(0, top),
		Size = UDim2.new(1, 0, 1, -top),
		Parent = parent,
	})
	UI.list(list, Enum.FillDirection.Vertical, 8)
	return list
end

return Page
