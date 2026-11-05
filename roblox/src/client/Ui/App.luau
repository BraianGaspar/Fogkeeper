-- Gerenciador da interface: monta a ScreenGui escalada, mantém a pilha de
-- telas de menu, o HUD, a fila de avisos e as configurações do jogador.
-- Cada tela é um ModuleScript desta pasta que retorna uma função
--   (app, params) -> { frame: GuiObject, focus: GuiObject?, update: ((dt) -> ())?, back: (() -> boolean)? }
-- e é reconstruída sempre que é aberta (assim reflete o estado atual).

local GuiService = game:GetService("GuiService")
local Lighting = game:GetService("Lighting")
local LocalizationService = game:GetService("LocalizationService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Theme = require(script.Parent:WaitForChild("Theme"))
local Data = require(script.Parent:WaitForChild("Data"))
local Text = Data.Text

local App = {}

local REF = Vector2.new(1280, 720)

App.ctx = nil :: any -- {send, input, renderer, sounds, net}
App.state = nil :: any -- pasta State replicada
App.settings = {
	locale = "", colorblind = 0, text_scale = 0, reduce_flashes = false, music = 80, sfx = 100, shake = true,
	master = 100, damage = 80, sounds = {}, -- sounds: grupo -> false quando desligado (ver Sounds.GROUPS)
}

local gui: ScreenGui
local scale: UIScale
local root: Frame -- área de referência 1280x720 escalada
local screenLayer: Frame
local hudLayer: Frame
local overlay: Frame
local vignette: Frame
local announceLabel: TextLabel
local toastList: Frame
local colorFilter: ColorCorrectionEffect
local stack: { { name: string, params: any, screen: any } } = {}
local announceQueue = {}
local announceTimer = 0
local hud: any = nil
local settingsDirty = 0

App.root = nil :: any
App.hudLayer = nil :: any

-- Escala -----------------------------------------------------------------------

local function rescale()
	local view = workspace.CurrentCamera.ViewportSize
	if view.X < 2 or view.Y < 2 then
		return
	end
	local s = math.min(view.X / REF.X, view.Y / REF.Y)
	scale.Scale = s
	root.Size = UDim2.fromOffset(view.X / s, view.Y / s)
end

-- Telas ------------------------------------------------------------------------

local function loadScreen(name: string): any
	local mod = script.Parent:FindFirstChild(name)
	if not mod then
		warn("[Fogkeeper] tela inexistente: " .. name)
		return nil
	end
	return require(mod)
end

local function focus(screen)
	if screen and screen.focus and App.ctx and App.ctx.input and App.ctx.input.usingPad then
		GuiService.SelectedObject = screen.focus
	end
end

local function destroyTop()
	local top = stack[#stack]
	if top and top.screen and top.screen.frame then
		if top.screen.close then
			top.screen.close()
		end
		top.screen.frame:Destroy()
	end
end

-- Abre uma tela por cima das outras (a de baixo fica escondida).
function App.open(name: string, params: any?)
	local builder = loadScreen(name)
	if not builder then
		return
	end
	local below = stack[#stack]
	if below and below.screen and below.screen.frame then
		below.screen.frame.Visible = false
	end
	local ok, screen = pcall(builder, App, params)
	if not ok then
		warn("[Fogkeeper] erro ao abrir " .. name .. ": " .. tostring(screen))
		if below and below.screen and below.screen.frame then
			below.screen.frame.Visible = true
		end
		return
	end
	screen.frame.Parent = screenLayer
	table.insert(stack, { name = name, params = params, screen = screen })
	focus(screen)
	if App.ctx and App.ctx.sounds then
		App.ctx.sounds.play("menu_open")
	end
end

-- Fecha todas e abre esta.
function App.replace(name: string?, params: any?)
	while #stack > 0 do
		destroyTop()
		table.remove(stack)
	end
	GuiService.SelectedObject = nil
	if name then
		App.open(name, params)
	end
end

-- Volta uma tela. Retorna false se não havia para onde voltar.
function App.back(): boolean
	local top = stack[#stack]
	if not top then
		return false
	end
	if top.screen.back and top.screen.back() == false then
		return false
	end
	if #stack <= 1 and not top.screen.closable then
		return false
	end
	destroyTop()
	table.remove(stack)
	local below = stack[#stack]
	if below then
		below.screen.frame.Visible = true
		focus(below.screen)
	else
		GuiService.SelectedObject = nil
	end
	if App.ctx and App.ctx.sounds then
		App.ctx.sounds.play("menu_back")
	end
	return true
end

function App.top(): string?
	local t = stack[#stack]
	return t and t.name
end

-- Reconstrói a tela do topo (depois de trocar idioma ou tamanho do texto).
-- `withHud` reconstrói também o HUD (idioma e tamanho do texto); as telas que
-- só querem se atualizar (compra na loja) chamam sem ele.
function App.refresh(withHud: boolean?)
	if withHud and hud and hud.rebuild then
		hud.rebuild()
	end
	local top = stack[#stack]
	if not top then
		return
	end
	local name, params = top.name, top.params
	destroyTop()
	table.remove(stack)
	App.open(name, params)
end

-- Avisos e efeitos de tela -------------------------------------------------------

function App.announce(text: string, args: { any }?, color: Color3?, big: boolean?)
	-- Formato e argumentos vêm do servidor: um desencontro não pode derrubar a fila.
	local ok, shown = pcall(Text.format, text, args or {})
	if not ok then
		shown = Text.t(tostring(text))
	end
	table.insert(announceQueue, { text = shown, color = color or Theme.GOLD, big = big == true })
	if #announceQueue > 6 then
		table.remove(announceQueue, 1)
	end
end

-- Recado pequeno no canto (conquistas, desbloqueios, relíquias).
function App.toast(text: string, color: Color3?)
	local l = Theme.label(toastList, text, 16, color or Theme.GOOD, Theme.BOLD, {
		Size = UDim2.fromOffset(420, 30), BackgroundTransparency = 0.15, BackgroundColor3 = Theme.INK,
		TextXAlignment = Enum.TextXAlignment.Center,
	})
	Theme.corner(l, 8)
	Theme.stroke(l, color or Theme.GOOD, 1.5)
	task.delay(4, function()
		local tw = TweenService:Create(l, TweenInfo.new(0.5), { TextTransparency = 1, BackgroundTransparency = 1 })
		tw:Play()
		tw.Completed:Wait()
		l:Destroy()
	end)
end

function App.hurt()
	if App.settings.reduce_flashes then
		return
	end
	vignette.BackgroundColor3 = Theme.DANGER
	vignette.BackgroundTransparency = 0.78
	TweenService:Create(vignette, TweenInfo.new(0.4), { BackgroundTransparency = 1 }):Play()
end

-- Clarão de tela inteira (sem efeito com "Reduzir efeitos piscantes").
function App.flashScreen(color: Color3, strength: number)
	if App.settings.reduce_flashes then
		return
	end
	vignette.BackgroundColor3 = color
	vignette.BackgroundTransparency = 1 - strength
	TweenService:Create(vignette, TweenInfo.new(0.5), { BackgroundTransparency = 1 }):Play()
end

-- Configurações -------------------------------------------------------------------

-- Filtro de daltonismo: o Roblox não tem matriz de cor como o shader do
-- Godot, então é uma aproximação com tinta, contraste e saturação que
-- separa melhor as cores problemáticas de cada tipo.
local COLORBLIND = {
	[1] = { TintColor = Color3.new(1.0, 0.94, 0.86), Saturation = 0.25, Contrast = 0.12 }, -- protanopia
	[2] = { TintColor = Color3.new(0.95, 0.95, 1.0), Saturation = 0.3, Contrast = 0.12 }, -- deuteranopia
	[3] = { TintColor = Color3.new(1.0, 0.92, 0.95), Saturation = 0.2, Contrast = 0.1 }, -- tritanopia
}

function App.applySettings()
	local s = App.settings
	Theme.textScale = Theme.TEXT_SCALES[(s.text_scale or 0) + 1] or 1
	local code = s.locale
	if not code or code == "" then
		local ok, id = pcall(function()
			return LocalizationService.RobloxLocaleId
		end)
		code = if ok then id else "pt-br"
	end
	Text.setLocale(code)
	local cb = COLORBLIND[s.colorblind or 0]
	colorFilter.Enabled = cb ~= nil
	if cb then
		colorFilter.TintColor = cb.TintColor
		colorFilter.Saturation = cb.Saturation
		colorFilter.Contrast = cb.Contrast
	end
	if App.ctx and App.ctx.sounds then
		App.ctx.sounds.applySettings(s)
	end
end

-- Muda uma configuração, aplica na hora e manda ao servidor (com espera,
-- para vários cliques virarem uma gravação só).
function App.setSetting(key: string, value: any, rebuild: boolean?)
	App.settings[key] = value
	App.applySettings()
	settingsDirty = 1.0
	if rebuild then
		App.refresh(true)
	end
end

-- Lê as configurações salvas no progresso (na primeira vez que chegam).
local loadedSettings = false
local function syncSettings()
	if loadedSettings then
		return
	end
	local raw = Players.LocalPlayer:GetAttribute("ProgressJson")
	if type(raw) ~= "string" or raw == "" then
		return
	end
	loadedSettings = true
	local saved = Data.progress().settings or {}
	for k, v in saved do
		App.settings[k] = v
	end
	App.applySettings()
	App.refresh(true)
end

-- Montagem e quadro a quadro -------------------------------------------------------

function App.build(ctx)
	App.ctx = ctx
	App.state = ctx.state
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui") :: PlayerGui
	pcall(function()
		playerGui.ScreenOrientation = Enum.ScreenOrientation.LandscapeSensor
	end)
	-- AutoLocalize desligado: as traduções vêm do módulo Text.
	gui = Theme.make("ScreenGui", playerGui, {
		Name = "Fogkeeper", ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		AutoLocalize = false, DisplayOrder = 5,
	})
	vignette = Theme.make("Frame", gui, {
		Size = UDim2.fromScale(1, 1), BackgroundColor3 = Theme.DANGER, BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 50,
	})
	root = Theme.make("Frame", gui, {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), BackgroundTransparency = 1, Name = "Root",
	})
	scale = Theme.make("UIScale", root, {})
	hudLayer = Theme.make("Frame", root, { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Name = "Hud", ZIndex = 1 })
	screenLayer = Theme.make("Frame", root, { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Name = "Screens", ZIndex = 2 })
	overlay = Theme.make("Frame", root, { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Name = "Overlay", ZIndex = 3 })
	App.root = root
	App.hudLayer = hudLayer
	App.overlay = overlay
	rescale()
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale)

	announceLabel = Theme.label(overlay, "", 42, Theme.GOLD, Theme.HEAD, {
		Position = UDim2.fromScale(0.5, 0.27), AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(1000, 60),
		TextTransparency = 1, TextStrokeTransparency = 1, ZIndex = 5,
	})
	toastList = Theme.make("Frame", overlay, {
		Size = UDim2.fromOffset(420, 300), Position = UDim2.new(0.5, 0, 1, -150), AnchorPoint = Vector2.new(0.5, 1),
		BackgroundTransparency = 1,
	})
	local layout = Theme.list(toastList, 6)
	layout.VerticalAlignment = Enum.VerticalAlignment.Bottom

	colorFilter = Instance.new("ColorCorrectionEffect")
	colorFilter.Name = "FogkeeperColorFilter"
	colorFilter.Enabled = false
	colorFilter.Parent = Lighting

	hud = require(script.Parent:WaitForChild("Hud"))
	hud.build(App, hudLayer)
	App.hud = hud
	App.applySettings()

	-- Compra de óleo entregue (server/Monetization manda só para o comprador).
	local net = game:GetService("ReplicatedStorage"):WaitForChild("FogkeeperNet")
	net:WaitForChild("Fx").OnClientEvent:Connect(function(name, data)
		if name == "purchase" and type(data) == "table" and (data.oil or 0) > 0 then
			App.toast(Text.format("+%d de óleo", { math.floor(data.oil) }), Theme.GOLD)
		end
	end)
end

-- Troca de fase vinda do servidor: saguão, história, partida, fim.
function App.onPhase(phase: string)
	GuiService.SelectedObject = nil
	if phase == "lobby" then
		hud.setVisible(false)
		App.replace("TitleScreen")
	elseif phase == "story" then
		hud.setVisible(false)
		App.replace("StoryScreen")
	elseif phase == "playing" then
		App.replace(nil)
		hud.setVisible(true)
	elseif phase == "ended" then
		hud.setVisible(true)
		App.replace("EndScreen")
	end
end

local function updateAnnounce(dt: number)
	announceTimer -= dt
	if announceTimer <= 0 and #announceQueue > 0 then
		local a = table.remove(announceQueue, 1)
		announceTimer = if a.big then 2.4 else 1.6
		announceLabel.Text = a.text
		announceLabel.TextColor3 = a.color
		announceLabel.TextSize = math.floor((if a.big then 46 else 30) * Theme.textScale + 0.5)
	end
	local alpha = if announceTimer > 0 then math.clamp(announceTimer / 0.4, 0, 1) else 0
	announceLabel.TextTransparency = 1 - alpha
	announceLabel.TextStrokeTransparency = 1 - alpha * 0.6
end

function App.update(dt: number)
	syncSettings()
	if settingsDirty > 0 then
		settingsDirty -= dt
		if settingsDirty <= 0 and App.ctx then
			App.ctx.send("settings", Data.encode(App.settings))
		end
	end
	local top = stack[#stack]
	if top and top.screen.update then
		local ok, err = pcall(top.screen.update, dt)
		if not ok then
			warn("[Fogkeeper] " .. top.name .. ": " .. tostring(err))
		end
	end
	hud.update(dt)
	updateAnnounce(dt)
end

-- Botão "voltar" (Esc, B do controle): fecha a tela do topo ou abre o menu do
-- jogador durante a partida.
function App.backPressed()
	if App.back() then
		return
	end
	local phase = App.state:GetAttribute("Phase")
	if phase == "playing" and #stack == 0 then
		App.open("PlayerMenu")
	end
end

return App
