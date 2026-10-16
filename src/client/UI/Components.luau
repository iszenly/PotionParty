--!strict
--[[
	Components.luau
	Funções para montar a interface por código, sem precisar desenhar no Studio.

		local button = UI.button({ Text = "Oi", Size = ..., Parent = frame }, function()
			print("clicou")
		end)

	"props" é uma tabela com as propriedades da instância (as mesmas do Studio).
	"Parent" é aplicado por último (é mais rápido criar tudo antes de parentear).
]]

local TweenService = game:GetService("TweenService")

local Theme = require(script.Parent.Theme)

local UI = {}

-- Cria qualquer instância com propriedades e filhos.
function UI.new(className: string, props: { [string]: any }?, children: { Instance }?): any
	local instance = (Instance.new :: any)(className)
	local parent: Instance? = nil
	if props then
		for key, value in props do
			if key == "Parent" then
				parent = value
			else
				instance[key] = value
			end
		end
	end
	if children then
		for _, child in children do
			child.Parent = instance
		end
	end
	if parent then
		instance.Parent = parent
	end
	return instance
end

function UI.corner(parent: Instance, radius: number?)
	UI.new("UICorner", { CornerRadius = UDim.new(0, radius or Theme.corner), Parent = parent })
end

function UI.stroke(parent: Instance, color: Color3?, thickness: number?)
	UI.new("UIStroke", {
		Color = color or Theme.colors.stroke,
		Thickness = thickness or 2,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = parent,
	})
end

function UI.padding(parent: Instance, pixels: number)
	local p = UDim.new(0, pixels)
	UI.new("UIPadding", { PaddingTop = p, PaddingBottom = p, PaddingLeft = p, PaddingRight = p, Parent = parent })
end

function UI.list(parent: Instance, direction: Enum.FillDirection, spacing: number, align: Enum.HorizontalAlignment?)
	return UI.new("UIListLayout", {
		FillDirection = direction,
		Padding = UDim.new(0, spacing),
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = align or Enum.HorizontalAlignment.Left,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Parent = parent,
	})
end

-- Texto. Aceita a chave extra "MaxTextSize" (tamanho máximo da fonte).
function UI.label(props: { [string]: any }): TextLabel
	local maxSize = props.MaxTextSize or 24
	local merged: { [string]: any } = {
		BackgroundTransparency = 1,
		Font = Theme.font,
		TextColor3 = Theme.colors.text,
		TextScaled = true,
		TextWrapped = true,
	}
	for key, value in props do
		if key ~= "MaxTextSize" then
			merged[key] = value
		end
	end
	local label = UI.new("TextLabel", merged)
	UI.new("UITextSizeConstraint", { MaxTextSize = maxSize, MinTextSize = 8, Parent = label })
	return label
end

-- Botão grande com efeito de "apertar". Aceita "MaxTextSize" também.
function UI.button(props: { [string]: any }, onClick: () -> ()): TextButton
	local maxSize = props.MaxTextSize or 24
	local merged: { [string]: any } = {
		BackgroundColor3 = Theme.colors.button,
		AutoButtonColor = true,
		Font = Theme.font,
		TextColor3 = Theme.colors.text,
		TextScaled = true,
		TextWrapped = true,
	}
	for key, value in props do
		if key ~= "MaxTextSize" then
			merged[key] = value
		end
	end
	local button: TextButton = UI.new("TextButton", merged)
	UI.new("UITextSizeConstraint", { MaxTextSize = maxSize, MinTextSize = 8, Parent = button })
	UI.new("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6), Parent = button })
	UI.corner(button)
	UI.stroke(button)

	local scale: UIScale = UI.new("UIScale", { Parent = button })
	local tweenInfo = TweenInfo.new(0.08)
	button.MouseButton1Down:Connect(function()
		TweenService:Create(scale, tweenInfo, { Scale = 0.92 }):Play()
	end)
	local function release()
		TweenService:Create(scale, tweenInfo, { Scale = 1 }):Play()
	end
	button.MouseButton1Up:Connect(release)
	button.MouseLeave:Connect(release)
	-- "Activated" funciona com mouse, toque e controle.
	button.Activated:Connect(onClick)
	return button
end

-- Lista com rolagem (o tamanho do conteúdo é calculado automaticamente).
function UI.scroll(props: { [string]: any }): ScrollingFrame
	local merged: { [string]: any } = {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 8,
		ScrollingDirection = Enum.ScrollingDirection.Y,
	}
	for key, value in props do
		merged[key] = value
	end
	return UI.new("ScrollingFrame", merged)
end

-- Remove os filhos de um frame, menos layouts/paddings (UI*).
function UI.clearChildren(parent: Instance)
	for _, child in parent:GetChildren() do
		if not child:IsA("UIBase") then
			child:Destroy()
		end
	end
end

-- Janela padrão com título e botão de fechar. Retorna (janela, área de conteúdo, título).
function UI.panel(screen: ScreenGui, title: string, onClose: () -> ()): (Frame, Frame, TextLabel)
	local root: Frame = UI.new("Frame", {
		Name = "Panel",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.52),
		Size = UDim2.fromScale(0.94, 0.84),
		BackgroundColor3 = Theme.colors.panel,
		Visible = false,
		Parent = screen,
	})
	UI.corner(root, 18)
	UI.stroke(root, Theme.colors.stroke, 3)
	UI.new("UISizeConstraint", { MaxSize = Vector2.new(820, 540), Parent = root })

	local titleLabel = UI.label({
		Text = title,
		Size = UDim2.new(1, -90, 0, 40),
		Position = UDim2.fromOffset(16, 8),
		TextXAlignment = Enum.TextXAlignment.Left,
		MaxTextSize = 30,
		Parent = root,
	})

	UI.button({
		Name = "Close",
		Text = "X",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -8, 0, 6),
		Size = UDim2.fromOffset(50, 46),
		BackgroundColor3 = Theme.colors.bad,
		MaxTextSize = 28,
		Parent = root,
	}, onClose)

	local content: Frame = UI.new("Frame", {
		Name = "Content",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(12, 58),
		Size = UDim2.new(1, -24, 1, -68),
		Parent = root,
	})
	return root, content, titleLabel
end

return UI
