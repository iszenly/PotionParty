--!strict
--[[
	EffectService.luau
	Aplica as transformações das poções no personagem, SEMPRE no servidor
	(tudo o que o servidor muda no personagem é replicado para todos).

	Regras para não quebrar o personagem:
	- só 1 efeito por jogador; beber outra poção remove o efeito anterior;
	- cada mudança registra uma função de "desfazer" (cleanup); ao terminar,
	  desfazemos na ordem inversa, cada uma protegida por pcall;
	- ao morrer/trocar de personagem, o efeito é descartado (o personagem novo
	  nasce normal).

	Atributos no personagem (o cliente lê para HUD e controles):
		PP_EffectName    nome da poção ativa
		PP_EffectEndsAt  os.time() de quando acaba
		PP_Fly           true quando o jogador pode subir segurando pulo
]]

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Types = require(ReplicatedStorage.Shared.Types)
local Traits = require(ReplicatedStorage.Shared.Config.Traits)
local Net = require(script.Parent.Parent.Net)

-- Avisa todos os clientes para tocar a animação de transformação (puff + flash).
local transformedEvent = Net.event("Transformed")

type TraitDef = Types.TraitDef
type Cleanups = { () -> () }

type ActiveEffect = {
	token: number,
	cleanups: Cleanups,
	character: Model,
}

local active: { [Player]: ActiveEffect } = {}
local tokenCounter = 0

local EffectService = {}

-- Peça decorativa que acompanha o personagem (sem colisão e sem massa).
local function attachProp(
	character: Model,
	anchor: BasePart,
	size: Vector3,
	offset: CFrame,
	color: Color3,
	shape: Enum.PartType
): Part
	local part = Instance.new("Part")
	part.Name = "PP_Prop"
	part.Shape = shape
	part.Size = size
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Massless = true
	part.CFrame = anchor.CFrame * offset
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = anchor
	weld.Part1 = part
	weld.Parent = part
	part.Parent = character
	return part
end

-- TODO(asset): substituir estes props por acessórios/modelos finais.
local function addProps(character: Model, propName: string, cleanups: Cleanups)
	local created: { Instance } = {}
	if propName == "FrogEyes" then
		local head = character:FindFirstChild("Head")
		if head and head:IsA("BasePart") then
			local s = head.Size
			local eye = s.X * 0.38
			for _, side in { -1, 1 } do
				local offset = CFrame.new(side * s.X * 0.28, s.Y * 0.5, -s.Z * 0.15)
				table.insert(
					created,
					attachProp(character, head, Vector3.one * eye, offset, Color3.new(1, 1, 1), Enum.PartType.Ball)
				)
				local pupilOffset = offset * CFrame.new(0, 0, -eye * 0.4)
				table.insert(
					created,
					attachProp(
						character,
						head,
						Vector3.one * eye * 0.45,
						pupilOffset,
						Color3.new(0, 0, 0),
						Enum.PartType.Ball
					)
				)
			end
		end
	elseif propName == "CloudPuffs" then
		local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
		if torso and torso:IsA("BasePart") then
			local s = torso.Size
			local puff = s.X * 0.7
			for i = 0, 5 do
				local angle = math.rad(i * 60)
				local offset = CFrame.new(math.cos(angle) * s.X * 0.8, -s.Y * 0.4, math.sin(angle) * s.Z * 1.2)
				table.insert(
					created,
					attachProp(character, torso, Vector3.one * puff, offset, Color3.new(1, 1, 1), Enum.PartType.Ball)
				)
			end
		end
	end
	table.insert(cleanups, function()
		for _, inst in created do
			inst:Destroy()
		end
	end)
end

local function applySize(character: Model, trait: TraitDef, cleanups: Cleanups)
	local scale = trait.scale
	if not scale then
		return
	end
	local original = character:GetScale()
	character:ScaleTo(original * scale)
	table.insert(cleanups, function()
		if character.Parent then
			character:ScaleTo(original)
		end
	end)
end

local function applyForm(character: Model, trait: TraitDef, cleanups: Cleanups)
	-- Guarda a aparência original de cada parte para restaurar depois.
	local saved: { { part: BasePart, color: Color3, material: Enum.Material, transparency: number } } = {}
	local removedClothes: { Instance } = {}

	for _, descendant in character:GetDescendants() do
		if descendant:IsA("BasePart") and descendant.Name ~= "HumanoidRootPart" then
			table.insert(saved, {
				part = descendant,
				color = descendant.Color,
				material = descendant.Material,
				transparency = descendant.Transparency,
			})
			if trait.color then
				descendant.Color = trait.color
			end
			if trait.material then
				descendant.Material = trait.material
			end
			if trait.transparency and descendant.Transparency < 1 then
				descendant.Transparency = math.max(descendant.Transparency, trait.transparency)
			end
		elseif trait.color and (descendant:IsA("Clothing") or descendant:IsA("ShirtGraphic")) then
			-- Roupas cobrem a cor do corpo; tiramos temporariamente.
			table.insert(removedClothes, descendant)
		end
	end
	for _, clothing in removedClothes do
		clothing.Parent = nil
	end

	table.insert(cleanups, function()
		for _, entry in saved do
			entry.part.Color = entry.color
			entry.part.Material = entry.material
			entry.part.Transparency = entry.transparency
		end
		if character.Parent then
			for _, clothing in removedClothes do
				clothing.Parent = character
			end
		end
	end)

	if trait.prop then
		addProps(character, trait.prop, cleanups)
	end
end

local function applyMovement(character: Model, humanoid: Humanoid, root: BasePart, trait: TraitDef, cleanups: Cleanups)
	if trait.speedMult then
		local original = humanoid.WalkSpeed
		humanoid.WalkSpeed = original * trait.speedMult
		table.insert(cleanups, function()
			humanoid.WalkSpeed = original
		end)
	end

	if trait.jumpMult then
		local mult = trait.jumpMult
		if humanoid.UseJumpPower then
			local original = humanoid.JumpPower
			humanoid.JumpPower = original * mult
			table.insert(cleanups, function()
				humanoid.JumpPower = original
			end)
		else
			local original = humanoid.JumpHeight
			humanoid.JumpHeight = original * mult * mult -- altura cresce ~ ao quadrado da força
			table.insert(cleanups, function()
				humanoid.JumpHeight = original
			end)
		end
	end

	if trait.antiGravity then
		-- Uma força para cima que cancela parte da gravidade = "flutuar".
		local attachment = Instance.new("Attachment")
		attachment.Name = "PP_ForceAttachment"
		attachment.Parent = root
		local force = Instance.new("VectorForce")
		force.Name = "PP_AntiGravity"
		force.Attachment0 = attachment
		force.RelativeTo = Enum.ActuatorRelativeTo.World
		force.ApplyAtCenterOfMass = true
		force.Force = Vector3.new(0, root.AssemblyMass * Workspace.Gravity * trait.antiGravity, 0)
		force.Parent = root
		table.insert(cleanups, function()
			force:Destroy()
			attachment:Destroy()
		end)
	end

	if trait.canFly then
		character:SetAttribute("PP_Fly", true)
		table.insert(cleanups, function()
			character:SetAttribute("PP_Fly", nil)
		end)
	end
end

local function applyVisual(character: Model, root: BasePart, trait: TraitDef, cleanups: Cleanups)
	local color = trait.visualColor or Color3.new(1, 1, 1)
	local kind = trait.visualKind
	local created: Instance? = nil

	if kind == "Light" then
		local light = Instance.new("PointLight")
		light.Color = color
		light.Brightness = 3
		light.Range = 16
		light.Parent = root
		created = light
	elseif kind == "Fire" then
		local fire = Instance.new("Fire")
		fire.Color = color
		fire.SecondaryColor = Color3.fromRGB(255, 220, 80)
		fire.Size = 5
		fire.Heat = 8
		fire.Parent = root
		created = fire
	elseif kind == "Sparkles" then
		local sparkles = Instance.new("Sparkles")
		sparkles.SparkleColor = color
		sparkles.Parent = root
		created = sparkles
	elseif kind == "Particles" then
		-- TODO(asset): textura própria por efeito (neve, raio, bolha).
		local emitter = Instance.new("ParticleEmitter")
		emitter.Color = ColorSequence.new(color)
		emitter.LightEmission = 0.6
		emitter.Rate = 25
		emitter.Lifetime = NumberRange.new(1, 1.6)
		emitter.Speed = NumberRange.new(2, 4)
		emitter.SpreadAngle = Vector2.new(180, 180)
		emitter.Size = NumberSequence.new(0.5, 0)
		emitter.Parent = root
		created = emitter
	elseif kind == "Rainbow" then
		-- O cliente anima a cor de todo Highlight com a tag "PP_Rainbow".
		local highlight = Instance.new("Highlight")
		highlight.Name = "PP_Rainbow"
		highlight.FillTransparency = 0.45
		highlight.OutlineTransparency = 0
		highlight.Adornee = character
		CollectionService:AddTag(highlight, "PP_Rainbow")
		highlight.Parent = character
		created = highlight
	elseif kind == "Highlight" then
		-- Contorno brilhante de cor fixa (ex.: aura dourada da mutação Dourada).
		local highlight = Instance.new("Highlight")
		highlight.Name = "PP_Aura"
		highlight.FillColor = color
		highlight.OutlineColor = color
		highlight.FillTransparency = 0.6
		highlight.OutlineTransparency = 0
		highlight.Adornee = character
		highlight.Parent = character
		created = highlight
	end

	if created then
		local instance = created
		table.insert(cleanups, function()
			instance:Destroy()
		end)
	end
end

-- Remove o efeito atual do jogador (se houver), desfazendo tudo.
-- silent = true: não toca a animação de "volta ao normal" (ex.: trocando de poção).
function EffectService.clear(player: Player, silent: boolean?)
	local state = active[player]
	if not state then
		return
	end
	active[player] = nil
	for i = #state.cleanups, 1, -1 do
		local ok, err = pcall(state.cleanups[i] :: any)
		if not ok then
			warn(`[EffectService] falha ao limpar efeito de {player.Name}: {err}`)
		end
	end
	-- "Puff" de volta ao normal (só se o personagem ainda está no mapa).
	if not silent and state.character.Parent then
		transformedEvent:FireAllClients(state.character, Color3.new(1, 1, 1))
	end
end

local function applyTrait(character: Model, humanoid: Humanoid, root: BasePart, trait: TraitDef, cleanups: Cleanups)
	if trait.category == "size" then
		applySize(character, trait, cleanups)
	elseif trait.category == "form" then
		applyForm(character, trait, cleanups)
	elseif trait.category == "movement" then
		applyMovement(character, humanoid, root, trait, cleanups)
	elseif trait.category == "visual" then
		applyVisual(character, root, trait, cleanups)
	end
end

--[[
	Aplica o efeito. Retorna false se o personagem não estiver pronto.
	overlay: traço extra da mutação (ex.: "GoldAura"), aplicado por último.
	color:   cor da poção, usada na animação de transformação.
]]
function EffectService.apply(
	player: Player,
	effect: Types.PotionEffect,
	displayName: string,
	overlay: string?,
	color: Color3?
): boolean
	local character = player.Character
	if not character then
		return false
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or humanoid.Health <= 0 or not root or not root:IsA("BasePart") then
		return false
	end

	EffectService.clear(player, true)

	tokenCounter += 1
	local token = tokenCounter
	local state: ActiveEffect = { token = token, cleanups = {}, character = character }
	active[player] = state

	local success, err = pcall(function()
		-- Ordem importa: tamanho primeiro (props e força antigravidade dependem do
		-- tamanho). Usamos um laço numérico porque a lista pode ter "buracos" (nil).
		local ids = { effect.size, effect.form, effect.movement, effect.visual, overlay }
		for i = 1, 5 do
			local id = ids[i]
			local trait = if id then Traits.byId[id] else nil
			if trait then
				applyTrait(character, humanoid, root, trait, state.cleanups)
			end
		end
	end)
	if not success then
		warn(`[EffectService] falha ao aplicar efeito em {player.Name}: {err}`)
		EffectService.clear(player)
		return false
	end

	character:SetAttribute("PP_EffectName", displayName)
	character:SetAttribute("PP_EffectEndsAt", os.time() + effect.duration)
	table.insert(state.cleanups, 1, function()
		character:SetAttribute("PP_EffectName", nil)
		character:SetAttribute("PP_EffectEndsAt", nil)
	end)

	transformedEvent:FireAllClients(character, color or Color3.new(1, 1, 1))

	task.delay(effect.duration, function()
		local current = active[player]
		if current and current.token == token then
			EffectService.clear(player)
		end
	end)
	return true
end

function EffectService.init()
	local function watch(player: Player)
		player.CharacterRemoving:Connect(function()
			EffectService.clear(player)
		end)
	end
	for _, player in Players:GetPlayers() do
		watch(player)
	end
	Players.PlayerAdded:Connect(watch)
	Players.PlayerRemoving:Connect(function(player)
		EffectService.clear(player)
	end)
end

return EffectService
