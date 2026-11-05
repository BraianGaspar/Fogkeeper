-- Bestiário: uma ficha por criatura e chefe de cada mapa, com o modelo 3D do
-- jogo num ViewportFrame e a lenda real. Fichas fechadas mostram só a
-- silhueta, até o jogador queimar aquela criatura.

local Theme = require(script.Parent:WaitForChild("Theme"))
local Data = require(script.Parent:WaitForChild("Data"))
local Text = Data.Text

local function viewport(parent: Instance, art: string, open: boolean, renderer: any)
	local vp = Theme.make("ViewportFrame", parent, {
		Size = UDim2.fromOffset(96, 96), Position = UDim2.fromOffset(8, 8), BackgroundColor3 = Theme.INK, BackgroundTransparency = 0.2,
		Ambient = Color3.new(0.7, 0.7, 0.75), LightColor = Color3.new(1, 0.95, 0.85), LightDirection = Vector3.new(-0.4, -1, -0.3),
		ImageColor3 = if open then Color3.new(1, 1, 1) else Color3.new(0.02, 0.02, 0.05),
	})
	Theme.corner(vp, 8)
	if not renderer or not renderer.buildModel then
		return vp
	end
	local ok, model = pcall(renderer.buildModel, art)
	if not ok or not model then
		return vp
	end
	model.Parent = vp
	local cf, size = model:GetBoundingBox()
	local radius = math.max(size.X, size.Y, size.Z) * 0.75 + 0.5
	local cam = Instance.new("Camera")
	cam.FieldOfView = 40
	cam.CFrame = CFrame.lookAt(cf.Position + Vector3.new(radius * 1.2, radius * 1.6, radius * 1.2), cf.Position)
	cam.Parent = vp
	vp.CurrentCamera = cam
	return vp
end

return function(app, params)
	local frame, box = Theme.screen(1100, 660, Text.t("Bestiário"))
	local seen = Data.progress().seen
	local entries = Data.Bestiary.ENTRIES or {}
	local lore = Data.Bestiary.LORE or {}
	local total, open = 0, 0
	for _, list in entries do
		for _, art in list do
			total += 1
			if seen[art] then
				open += 1
			end
		end
	end
	Theme.label(box, Text.format("%d de %d fichas abertas", { open, total }), 16, Theme.GOLD, Theme.BOLD, { LayoutOrder = 10 })
	local mapId = (params and params.map) or Data.mapOrder()[1]
	local tabs = Theme.make("Frame", box, { Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1, LayoutOrder = 11 })
	Theme.list(tabs, 6, true)
	local first: GuiObject? = nil
	for i, id in Data.mapOrder() do
		local b = Theme.smallButton(tabs, Text.t(Data.map(id).name), UDim2.fromOffset(146, 38), function()
			if id ~= mapId then
				app.back()
				app.open("BestiaryScreen", { map = id })
			end
		end, { LayoutOrder = i })
		Theme.setSelected(b, id == mapId)
		if id == mapId then
			first = b
		end
	end
	local scroll = Theme.scroll(box, UDim2.new(1, 0, 0, 440), { LayoutOrder = 20, Selectable = true }) -- controle: selecionar e rolar com o analógico
	Theme.grid(scroll, Vector2.new(520, 112), 8)
	for i, art in entries[mapId] or {} do
		local isOpen = seen[art] == true
		local isBoss = Data.bosses()[art] ~= nil
		local cell = Theme.make("Frame", scroll, {
			BackgroundColor3 = if isBoss then Color3.new(0.12, 0.05, 0.06) else Theme.PANEL_LIGHT, BackgroundTransparency = 0.25,
			BorderSizePixel = 0, LayoutOrder = i,
		})
		Theme.corner(cell, 8)
		Theme.stroke(cell, if isBoss then Theme.DANGER else Theme.GOLD_DARK, 1, 0.4)
		viewport(cell, art, isOpen, app.ctx and app.ctx.renderer)
		Theme.label(cell, if isOpen then Data.creatureName(art) else "???", 18, if isBoss then Theme.DANGER else Theme.GOLD, Theme.HEAD, {
			Position = UDim2.fromOffset(114, 6), Size = UDim2.new(1, -122, 0, 22), TextXAlignment = Enum.TextXAlignment.Left,
		})
		local title = if isBoss and isOpen then Data.bossTitle(art) else ""
		Theme.label(cell, title, 12, Theme.TEXT_DIM, Theme.BODY, {
			Position = UDim2.fromOffset(114, 28), Size = UDim2.new(1, -122, 0, 16), TextXAlignment = Enum.TextXAlignment.Left,
		})
		Theme.label(cell, if isOpen then Text.t(lore[art] or "") else Text.t("Queime esta criatura para abrir a ficha."), 13,
			if isOpen then Theme.TEXT else Theme.TEXT_DIM, Theme.BODY, {
				Position = UDim2.fromOffset(114, 44), Size = UDim2.new(1, -122, 0, 62), TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Top,
			})
	end
	Theme.backButton(box, app, 30)
	return { frame = frame, focus = first }
end
