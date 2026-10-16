--!strict
--[[
	Router.luau
	Controla qual janela está aberta (só uma por vez, bom para celular).
		Router.register("Inventory", { open = fn, close = fn })
		Router.open("Inventory")
]]

export type Page = {
	open: () -> (),
	close: () -> (),
}

local pages: { [string]: Page } = {}
local current: string? = nil

local Router = {}

function Router.register(name: string, page: Page)
	pages[name] = page
end

function Router.close()
	if current then
		local page = pages[current]
		current = nil
		page.close()
	end
end

function Router.open(name: string)
	if current == name then
		return
	end
	Router.close()
	local page = pages[name]
	if page then
		current = name
		page.open()
	end
end

function Router.toggle(name: string)
	if current == name then
		Router.close()
	else
		Router.open(name)
	end
end

function Router.current(): string?
	return current
end

return Router
