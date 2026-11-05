-- HUD da partida: vida do farol e estados (tinta, pedra, sono, encanto),
-- relógio do amanhecer com os marcos dos chefes, pontuação, barra do chefe,
-- relíquias, XP, as 3 habilidades, o painel do tutorial e as cartas de
-- melhoria (LevelUp). Lê os atributos de State e do jogador a cada quadro.

local GuiService = game:GetService("GuiService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ReviveCatalog = require(ReplicatedStorage:WaitForChild("Fogkeeper"):WaitForChild("Monetization"))
local Theme = require(script.Parent:WaitForChild("Theme"))
local Data = require(script.Parent:WaitForChild("Data"))
local Icons = require(script.Parent:WaitForChild("Icons"))
local LevelUp = require(script.Parent:WaitForChild("LevelUp"))
local Text = Data.Text

local Hud = {}

local app: any
local layer: Frame
local frame: Frame
local refs: { [string]: any } = {}
local levelUp: any = nil
local abilitySlots = {}
local shownLoadout = ""
local shownRelics = ""
local tutRaw: any = nil -- TutorialJson já decodificado (não decodifica a cada quadro)
local tutValue: any = nil

-- Textos de toque para os passos do tutorial que falam de teclas (o servidor
-- manda só teclado e controle). Índices de Tutorial.Step.
local TUTORIAL_TOUCH = {
	[1] = "Ande com o polegar esquerdo e toque no mar para apontar a lanterna: o seu feixe sai da sua mão e segue o ponto tocado.", -- i18n
	[4] = "Com brasas suficientes, você escolhe uma melhoria. As cartas aparecem no canto da tela e a partida não pausa: toque na carta que quiser. Os botões embaixo delas trocam as cartas ou banem uma.", -- i18n
	[5] = "Toque nos três botões embaixo: Clarão (fere e atordoa em volta), Sobrecarga (feixe concentrado) e Sino da Névoa (puxa as brasas e cura). Use as três.", -- i18n
}

-- Dica da primeira partida (para quem não fez o tutorial), por aparelho.
local FIRST_RUN_HINT = 25 -- segundos
local FIRST_RUN_TEXT = {
	mouse = "Aponte a lanterna com o mouse e queime as criaturas antes que cheguem ao farol. Q, E e R usam as habilidades.", -- i18n
	touch = "Toque no mar para apontar a lanterna e queime as criaturas antes que cheguem ao farol. Os botões embaixo usam as habilidades.", -- i18n
	pad = "Gire a câmera com o analógico direito para apontar a lanterna e queime as criaturas. LB, RB e Y usam as habilidades.", -- i18n
}

local STATUS = {
	{ attr = "Ink", text = "Tinta: alcance reduzido", color = Color3.new(0.75, 0.62, 1.0) },
	{ attr = "Petrified", text = "Farol petrificado!", color = Color3.new(0.75, 0.75, 0.7) },
	{ attr = "Asleep", text = "O farol cochila...", color = Color3.new(0.6, 0.75, 1.0) },
	{ attr = "Charmed", text = "O canto da Iara puxa as criaturas!", color = Color3.new(0.5, 0.95, 0.85) },
}

local function loadout(): { string }
	local raw = Players.LocalPlayer:GetAttribute("Loadout")
	if type(raw) == "string" and raw ~= "" then
		return string.split(raw, ",")
	end
	return Data.Balance.DEFAULT_LOADOUT or { "flash", "overcharge", "bell" }
end

-- Medidas do HUD conforme o aparelho, em unidades do HUD (o App já aplicou
-- a escala extra do celular em App.hudScale).
local function metrics()
	local k = app.hudScale or 1
	local px = math.max(0.1, (app.uiScale or 1) * k) -- pixels reais por unidade do HUD
	local safe = app.safe or {}
	local touch = app.touch == true
	-- Alvo de toque de ~48 px reais (o Roblox recomenda 44 ou mais).
	local minTouch = if touch then math.ceil(48 / px) else 0
	return {
		touch = touch,
		top = (safe.top or 0) / k,
		right = (safe.right or 0) / k,
		slot = math.clamp(math.max(64, minTouch), 64, 104),
		menu = math.clamp(math.max(52, minTouch), 52, 96),
	}
end

-- Texto do HUD sem painel atrás (sobre o céu ou o mar): contorno mais forte.
local function worldLabel(l: TextLabel): TextLabel
	l.TextStrokeTransparency = 0.15
	return l
end

-- Habilidades ---------------------------------------------------------------------

local builtSlot = 0

local function buildAbilities()
	for _, s in abilitySlots do
		s.frame:Destroy()
	end
	abilitySlots = {}
	local ids = loadout()
	shownLoadout = table.concat(ids, ",")
	local m = metrics()
	local size = m.slot
	builtSlot = size
	for i, id in ids do
		local slot = Theme.make("TextButton", frame, {
			Size = UDim2.fromOffset(size, size), Position = UDim2.new(0.5, (i - 2) * (size + 16), 1, -66), AnchorPoint = Vector2.new(0.5, 1),
			BackgroundColor3 = Color3.new(0.08, 0.08, 0.13), BorderSizePixel = 0, Text = "", AutoButtonColor = false,
			Selectable = false,
		})
		Theme.corner(slot, 10)
		local stroke = Theme.stroke(slot, Theme.GOLD, 2)
		local icon = Icons.make(slot, id, math.floor(size * 0.8))
		icon.AnchorPoint = Vector2.new(0.5, 0.5)
		icon.Position = UDim2.fromScale(0.5, 0.5)
		local cover = Theme.make("Frame", slot, {
			Size = UDim2.fromScale(1, 0), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.35, BorderSizePixel = 0,
			ZIndex = 3,
		})
		Theme.corner(cover, 10)
		local count = Theme.label(slot, "", 22, Theme.TEXT, Theme.HEAD, { Size = UDim2.fromScale(1, 1), ZIndex = 4 })
		local key = Theme.label(slot, "", 12, Theme.TEXT_DIM, Theme.BOLD, {
			Size = UDim2.new(1, 20, 0, 16), Position = UDim2.new(0, -10, 1, 2),
		})
		slot.Activated:Connect(function()
			if app.ctx and app.ctx.useAbility then
				app.ctx.useAbility(i)
			end
		end)
		table.insert(abilitySlots, { frame = slot, stroke = stroke, cover = cover, count = count, key = key, id = id, ready = true })
	end
end

local function updateAbilities(t: number)
	if app.state:GetAttribute("Paused") == true or app.state:GetAttribute("Reviving") == true then
		return -- recargas congeladas junto com a noite (pausa ou espera do reacender)
	end
	local me = Players.LocalPlayer
	local now = workspace:GetServerTimeNow()
	local input = app.ctx and app.ctx.input
	for i, s in abilitySlots do
		local left = (me:GetAttribute("Cd" .. i) or 0) - now
		-- A recarga real pode ser menor que a base (relíquias da Cuca e da
		-- Cailleach): o anel usa o tempo que faltava quando a habilidade foi usada.
		if left > (s.lastLeft or 0) + 0.5 then
			s.full = left
		end
		s.lastLeft = left
		local cd = s.full or Data.ability(s.id).cooldown or 20
		local ready = left <= 0.05
		s.cover.Size = UDim2.fromScale(1, if ready then 0 else math.clamp(left / cd, 0, 1))
		s.count.Text = if ready then "" else tostring(math.ceil(left))
		s.stroke.Color = if ready then Theme.GOLD else Theme.GOLD_DARK
		s.stroke.Thickness = if ready then 2 + math.sin(t * 3 + i) * 0.6 else 1.5
		if ready and not s.ready and app.ctx and app.ctx.sounds then
			app.ctx.sounds.play("ability_ready")
		end
		s.ready = ready
		-- No toque a tecla não diz nada: o botão é o próprio alvo.
		s.key.Text = if input and input.device() ~= "touch" then input.label("ability_" .. i) else ""
	end
end

-- Posições que dependem do aparelho, da barra do Roblox e da escala.
local function layout()
	if not frame or not refs.topLeft then
		return
	end
	local m = metrics()
	if m.slot ~= builtSlot then
		buildAbilities()
	end
	refs.topLeft.Position = UDim2.fromOffset(20, math.max(10, m.top + 4))
	-- Menu no canto de cima à direita; se o Roblox ocupar esse canto, desce.
	local menuY = if m.right > 0 then m.top + 6 else 12
	refs.menuButton.Size = UDim2.fromOffset(m.menu, m.menu)
	refs.menuButton.Position = UDim2.new(1, -(16 + m.right), 0, menuY)
	local scoreX = -(16 + m.right + m.menu + 14)
	refs.score.Position = UDim2.new(1, scoreX, 0, menuY - 8)
	refs.kills.Position = UDim2.new(1, scoreX, 0, menuY + 38)
	-- XP: no toque a barra é mais curta, para não passar sob as cartas.
	local xpWidth = if m.touch then 580 else 820
	refs.xpBack.Size = UDim2.fromOffset(xpWidth, 18)
	refs.xpBack.Position = UDim2.new(0.5, -xpWidth / 2 + 15, 1, -30)
	refs.medal.Position = UDim2.new(0.5, -xpWidth / 2 + 31, 1, -21)
	-- Tutorial logo acima das habilidades (que crescem no toque).
	refs.tutorial.Position = UDim2.new(0.5, -70, 1, -(88 + m.slot))
	if levelUp and levelUp.layout then
		levelUp.layout(m.touch, m.right, menuY + m.menu + 12)
	end
end

-- Montagem -----------------------------------------------------------------------

local function build()
	if frame then
		frame:Destroy()
	end
	refs = {}
	frame = Theme.make("Frame", layer, { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, Name = "Hud" })

	-- Vida do farol e estados. Ficam num grupo logo abaixo da barra do Roblox
	-- (menu e chat ocupam o canto de cima à esquerda); ver layout().
	local topLeft = Theme.make("Frame", frame, { Size = UDim2.fromOffset(440, 132), BackgroundTransparency = 1, Name = "TopLeft" })
	refs.topLeft = topLeft
	worldLabel(Theme.label(topLeft, Text.t("Farol"), 20, Theme.GOLD, Theme.HEAD, {
		Position = UDim2.fromOffset(0, 0), Size = UDim2.fromOffset(330, 24), TextXAlignment = Enum.TextXAlignment.Left,
	}))
	local _, hpFill = Theme.bar(topLeft, UDim2.fromOffset(330, 24), UDim2.fromOffset(0, 28), Theme.HP)
	refs.hpFill = hpFill
	refs.hpText = Theme.label(topLeft, "", 15, Theme.TEXT, Theme.BOLD, { Position = UDim2.fromOffset(0, 28), Size = UDim2.fromOffset(330, 24) })
	refs.status = worldLabel(Theme.label(topLeft, "", 15, Theme.TEXT, Theme.BOLD, {
		Position = UDim2.fromOffset(0, 56), Size = UDim2.fromOffset(420, 20), TextXAlignment = Enum.TextXAlignment.Left,
	}))
	refs.relics = worldLabel(Theme.label(topLeft, "", 14, Color3.new(0.7, 0.9, 1.0), Theme.BODY, {
		Position = UDim2.fromOffset(0, 78), Size = UDim2.fromOffset(420, 40), TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
	}))

	-- Relógio do amanhecer.
	refs.clock = worldLabel(Theme.label(frame, "18:00", 36, Theme.TEXT, Theme.HEAD, {
		Position = UDim2.new(0.5, 0, 0, 6), AnchorPoint = Vector2.new(0.5, 0), Size = UDim2.fromOffset(240, 40),
	}))
	local dayBack, dayFill = Theme.bar(frame, UDim2.fromOffset(380, 10), UDim2.new(0.5, -190, 0, 50), Theme.GOLD)
	refs.dayBack = dayBack
	refs.dayFill = dayFill
	Theme.label(dayBack, "🌙", 16, Theme.TEXT, Theme.BOLD, { Size = UDim2.fromOffset(20, 20), Position = UDim2.new(0, -26, 0.5, -10) })
	Theme.label(dayBack, "☀️", 16, Theme.TEXT, Theme.BOLD, { Size = UDim2.fromOffset(20, 20), Position = UDim2.new(1, 6, 0.5, -10) })
	refs.bossMark = Theme.make("Frame", dayBack, {
		Size = UDim2.fromOffset(10, 10), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Theme.DANGER, BorderSizePixel = 0,
		Rotation = 45, Visible = false, ZIndex = 3,
	})
	-- Texto claro (não cinza) com contorno: fica sobre o céu, sem painel atrás.
	refs.dawn = worldLabel(Theme.label(frame, "", 15, Theme.TEXT, Theme.BODY, {
		Position = UDim2.new(0.5, 0, 0, 62), AnchorPoint = Vector2.new(0.5, 0), Size = UDim2.fromOffset(520, 20),
	}))

	-- Pontuação e menu (posições em layout()).
	refs.score = worldLabel(Theme.label(frame, "0", 42, Theme.GOLD, Theme.HEAD, {
		AnchorPoint = Vector2.new(1, 0), Size = UDim2.fromOffset(320, 46), TextXAlignment = Enum.TextXAlignment.Right,
	}))
	refs.kills = worldLabel(Theme.label(frame, "", 15, Theme.TEXT, Theme.BODY, {
		AnchorPoint = Vector2.new(1, 0), Size = UDim2.fromOffset(320, 20), TextXAlignment = Enum.TextXAlignment.Right,
	}))
	-- Ícone de menu (três traços, ☰); também abre com a tecla P e o Menu do
	-- controle. Pausar é uma das opções do menu.
	local menuButton = Theme.button(frame, "", UDim2.fromOffset(52, 52), function()
		app.open("PlayerMenu")
	end, { AnchorPoint = Vector2.new(1, 0) })
	for i = 0, 2 do
		local bar = Theme.make("Frame", menuButton, { Size = UDim2.fromScale(0.5, 0.077), Position = UDim2.fromScale(0.5, 0.5 + (i - 1) * 0.173),
			AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Theme.GOLD, BorderSizePixel = 0 })
		Theme.make("UICorner", bar, { CornerRadius = UDim.new(0, 2) })
	end
	refs.menuButton = menuButton

	-- Aviso de pausa para quem não abriu o menu (outro faroleiro pausou).
	local pause = Theme.make("Frame", frame, { Size = UDim2.fromOffset(460, 150), Position = UDim2.fromScale(0.5, 0.42),
		AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Theme.INK, BackgroundTransparency = 0.15, Visible = false })
	Theme.make("UICorner", pause, { CornerRadius = UDim.new(0, 10) })
	Theme.make("UIStroke", pause, { Color = Theme.GOLD_DARK, Thickness = 1.5 })
	refs.pauseText = Theme.label(pause, "", 26, Theme.GOLD, Theme.HEAD, { Position = UDim2.fromOffset(0, 18), Size = UDim2.new(1, 0, 0, 34) })
	refs.pauseButton = Theme.button(pause, Text.t("Continuar"), UDim2.fromOffset(240, 48), function()
		app.ctx.send("pause", false)
	end, { Position = UDim2.new(0.5, 0, 1, -16), AnchorPoint = Vector2.new(0.5, 1) })
	refs.pause = pause

	-- Reacender o farol (Developer Product): aparece para todos quando a luz se
	-- apaga no modo Normal, durante Balance.REVIVE_WINDOW segundos.
	local revive = Theme.make("Frame", frame, { Size = UDim2.fromOffset(520, 190), Position = UDim2.fromScale(0.5, 0.42),
		AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Theme.INK, BackgroundTransparency = 0.1, Visible = false })
	Theme.make("UICorner", revive, { CornerRadius = UDim.new(0, 10) })
	Theme.make("UIStroke", revive, { Color = Theme.DANGER, Thickness = 2 })
	Theme.label(revive, Text.t("A luz se apagou"), 30, Theme.DANGER, Theme.HEAD, { Position = UDim2.fromOffset(0, 14), Size = UDim2.new(1, 0, 0, 36) })
	refs.reviveText = Theme.label(revive, "", 16, Theme.TEXT, Theme.BODY, { Position = UDim2.fromOffset(20, 56), Size = UDim2.new(1, -40, 0, 44) })
	refs.reviveButton = Theme.button(revive, Text.t("Reacender o farol"), UDim2.fromOffset(300, 48), function()
		local product = ReviveCatalog.product("revive")
		if product and product.id ~= 0 then
			MarketplaceService:PromptProductPurchase(Players.LocalPlayer, product.id)
		end
	end, { Position = UDim2.new(0.5, 0, 1, -16), AnchorPoint = Vector2.new(0.5, 1), TextColor3 = Theme.GOLD })
	refs.revive = revive

	-- Barra do chefe.
	local bossBack, bossFill = Theme.bar(frame, UDim2.fromOffset(560, 18), UDim2.new(0.5, -280, 0, 112), Theme.DANGER)
	refs.bossBack = bossBack
	refs.bossFill = bossFill
	refs.bossName = Theme.label(bossBack, "", 17, Theme.DANGER, Theme.HEAD, { Position = UDim2.fromOffset(0, -26), Size = UDim2.new(1, 0, 0, 24) })

	-- XP e nível.
	-- Largura e posição em layout() (no celular a barra encolhe para não
	-- passar por baixo das cartas de melhoria).
	local xpBack, xpFill = Theme.bar(frame, UDim2.fromOffset(820, 18), nil, Theme.XP)
	refs.xpBack = xpBack
	refs.xpFill = xpFill
	refs.xpText = Theme.label(xpBack, "", 14, Theme.TEXT, Theme.BOLD, { Size = UDim2.fromScale(1, 1), TextStrokeTransparency = 0.2, ZIndex = 2 })
	local medal = Theme.make("Frame", frame, {
		Size = UDim2.fromOffset(46, 46), AnchorPoint = Vector2.new(1, 0.5), BackgroundColor3 = Color3.new(0.2, 0.12, 0.35),
		BorderSizePixel = 0,
	})
	refs.medal = medal
	Theme.corner(medal, 46)
	Theme.stroke(medal, Theme.GOLD, 2)
	refs.level = Theme.label(medal, "1", 22, Theme.GOLD, Theme.HEAD, { Size = UDim2.fromScale(1, 1) })

	-- Tutorial.
	local tut = Theme.panel(frame, {
		-- Um pouco à esquerda do centro: as cartas de melhoria ocupam o canto
		-- direito. Cresce para cima conforme o texto (altura em layout()).
		Size = UDim2.fromOffset(640, 0), AutomaticSize = Enum.AutomaticSize.Y, AnchorPoint = Vector2.new(0.5, 1), Visible = false,
	})
	Theme.padding(tut, 14)
	Theme.list(tut, 4, false, Enum.HorizontalAlignment.Left)
	refs.tutorial = tut
	tutRaw = nil
	refs.tutTitle = Theme.label(tut, "", 20, Theme.GOLD, Theme.HEAD, { TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 1 })
	refs.tutBody = Theme.label(tut, "", 15, Theme.TEXT, Theme.BODY, {
		TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 2,
	})
	refs.tutProgress = Theme.label(tut, "", 14, Theme.GOOD, Theme.BOLD, { TextXAlignment = Enum.TextXAlignment.Right, LayoutOrder = 3 })

	if levelUp and levelUp.destroy then
		levelUp.destroy() -- solta a conexão da versão anterior
	end
	levelUp = LevelUp.build(app, frame)
	abilitySlots = {}
	buildAbilities()
	shownRelics = ""
	layout()
end

function Hud.build(appRef, parent: Frame)
	app = appRef
	layer = parent
	build()
end

-- Reconstrói depois de trocar idioma ou tamanho do texto.
function Hud.rebuild()
	local visible = frame and frame.Visible
	build()
	frame.Visible = visible == true
end

-- O App chama quando muda a escala, a barra do Roblox ou o tamanho da tela.
function Hud.layout()
	layout()
end

-- Cartas de melhoria na tela (o Client esconde o botão de pular do celular,
-- que ficaria por cima delas).
function Hud.cardsOpen(): boolean
	return levelUp ~= nil and levelUp.visible ~= nil and levelUp.visible()
end

function Hud.setVisible(on: boolean)
	frame.Visible = on
	if on then
		buildAbilities()
	end
end

function Hud.pick(i: number)
	if levelUp then
		levelUp.pick(i)
	end
end

function Hud.reroll()
	if levelUp then
		levelUp.reroll()
	end
end

function Hud.toggleBanish()
	if levelUp then
		levelUp.toggleBanish()
	end
end

-- Quadro a quadro -----------------------------------------------------------------

local t = 0

function Hud.update(dt: number)
	if not frame.Visible then
		return
	end
	t += dt
	local state = app.state
	local hp = state:GetAttribute("Hp") or 0
	local maxHp = math.max(1, state:GetAttribute("MaxHp") or 1)
	refs.hpFill.Size = UDim2.fromScale(math.clamp(hp / maxHp, 0, 1), 1)
	refs.hpText.Text = string.format("%d / %d", math.ceil(hp), math.ceil(maxHp))

	local status = {}
	local statusColor = Theme.TEXT
	for _, s in STATUS do
		if state:GetAttribute(s.attr) == true then
			table.insert(status, Text.t(s.text))
			statusColor = s.color
		end
	end
	refs.status.Text = table.concat(status, "   •   ")
	refs.status.TextColor3 = statusColor

	local relics = state:GetAttribute("Relics") or ""
	if relics ~= shownRelics then
		shownRelics = relics
		local names = {}
		for _, id in string.split(relics, ",") do
			if id ~= "" then
				table.insert(names, Text.t(Data.relic(id).name))
			end
		end
		refs.relics.Text = if #names > 0 then Text.format("Relíquias: %s", { table.concat(names, ", ") }) else ""
	end

	-- Relógio: a hora da história, o tempo de partida e o próximo chefe.
	local phase = state:GetAttribute("Phase")
	local elapsed = 0
	if phase == "ended" then
		elapsed = state:GetAttribute("RunSeconds") or 0
	else
		elapsed = math.max(0, workspace:GetServerTimeNow() - (state:GetAttribute("RunStart") or workspace:GetServerTimeNow()))
	end
	local mode = state:GetAttribute("Mode") or "normal"
	local endless = state:GetAttribute("Endless") == true
	local run = Data.RUN_DURATION
	-- CycleSeconds (servidor) já trata sem fim, Modo Chefões e tutorial.
	local cycle = state:GetAttribute("CycleSeconds")
	if mode == "boss_rush" then
		refs.clock.Text = Data.time(elapsed)
		refs.dayFill.Size = UDim2.fromScale(math.clamp((cycle or 0) / run, 0, 1), 1)
		refs.dawn.Text = Text.t("Modo Chefões")
	elseif endless then
		local night = state:GetAttribute("Night") or 1
		local inNight = if type(cycle) == "number" then cycle else elapsed % run
		refs.clock.Text = Data.clock(inNight)
		refs.dayFill.Size = UDim2.fromScale(math.clamp(inNight / run, 0, 1), 1)
		refs.dawn.Text = Text.format("Noite %d (sem fim)   •   %s de partida", { night, Data.time(elapsed) })
	else
		local shown = math.min(if type(cycle) == "number" then cycle else elapsed, run)
		refs.clock.Text = Data.clock(shown)
		refs.dayFill.Size = UDim2.fromScale(shown / run, 1)
		refs.dawn.Text = Text.format("%s de partida   •   amanhecer em %s", { Data.time(elapsed), Data.time(run - shown) })
	end
	-- NextBossAt é hora do servidor (RunStart + segundos da partida).
	local nextAt = state:GetAttribute("NextBossAt")
	local nextBoss = state:GetAttribute("NextBoss") or ""
	refs.bossMark.Visible = nextBoss ~= "" and type(nextAt) == "number" and nextAt > 0 and mode ~= "boss_rush"
	if refs.bossMark.Visible then
		local at = nextAt - (state:GetAttribute("RunStart") or 0)
		local frac = if endless then ((at - run) % run) / run else math.clamp(at / run, 0, 1)
		refs.bossMark.Position = UDim2.fromScale(frac, 0.5)
	end

	local device = if app.ctx.input and app.ctx.input.device then app.ctx.input.device() else "mouse"
	local reviving = state:GetAttribute("Reviving") == true
	refs.revive.Visible = reviving
	if reviving then
		local left = math.max(0, math.ceil((state:GetAttribute("ReviveUntil") or 0) - workspace:GetServerTimeNow()))
		refs.reviveText.Text = Text.format("Qualquer faroleiro pode reacender o farol com Robux: ele volta com metade da vida e a noite continua (a partida sai do ranking). %d s", { left })
	end

	local paused = state:GetAttribute("Paused") == true
	refs.pause.Visible = paused and app.top() == nil and not reviving
	if paused then
		local by = state:GetAttribute("PausedBy") or ""
		refs.pauseText.Text = if by ~= "" then Text.format("Pausado por %s", { by }) else Text.t("Pausado")
	end
	-- Controle: o botão do aviso (reacender ou continuar) recebe o foco
	-- sozinho; sem isso o A não teria o que apertar.
	local wanted = if reviving then refs.reviveButton elseif refs.pause.Visible then refs.pauseButton else nil
	local selected = GuiService.SelectedObject
	if wanted and device == "pad" and app.top() == nil and selected == nil then
		GuiService.SelectedObject = wanted
	elseif selected and (selected == refs.reviveButton or selected == refs.pauseButton) and selected ~= wanted then
		GuiService.SelectedObject = nil
	end

	refs.score.Visible = mode ~= "tutorial" -- o tutorial não vale pontos
	refs.score.Text = Data.number(state:GetAttribute("Score") or 0)
	refs.kills.Text = Text.format("%s criaturas queimadas", { Data.number(state:GetAttribute("Kills") or 0) })

	local boss = state:GetAttribute("BossName") or ""
	refs.bossBack.Visible = boss ~= ""
	if boss ~= "" then
		local title = Data.bossTitle(boss)
		local name = Data.creatureName(boss)
		refs.bossName.Text = if title ~= "" then name .. " — " .. title else name
		refs.bossFill.Size = UDim2.fromScale(math.clamp(state:GetAttribute("BossHp") or 0, 0, 1), 1)
	end

	local xp = state:GetAttribute("Xp") or 0
	local need = math.max(1, state:GetAttribute("XpNeeded") or 1)
	local level = state:GetAttribute("Level") or 1
	refs.xpFill.Size = UDim2.fromScale(math.clamp(xp / need, 0, 1), 1)
	refs.xpText.Text = Text.format("%d / %d XP   (%d%%)   —   próximo nível: %d", {
		math.floor(xp), math.floor(need), math.floor(xp / need * 100), level + 1 })
	refs.level.Text = tostring(level)

	-- Tutorial.
	local rawTut = state:GetAttribute("TutorialJson")
	if rawTut ~= tutRaw then
		tutRaw = rawTut
		tutValue = Data.decode(rawTut)
	end
	local tut = tutValue
	local inTutorial = mode == "tutorial" and type(tut) == "table" and phase == "playing"
	-- Primeira partida de quem pulou o tutorial: uma dica curta de como mirar
	-- nos primeiros segundos, no mesmo quadro (some sozinha).
	local firstRun = not inTutorial and phase == "playing" and mode ~= "tutorial" and elapsed < FIRST_RUN_HINT
		and type(Players.LocalPlayer:GetAttribute("ProgressJson")) == "string"
		and (tonumber(Data.progress().stats.runs) or 0) == 0
	refs.tutorial.Visible = inTutorial or firstRun
	if inTutorial then
		refs.tutTitle.Text = Text.t(tut.title or "")
		local touchBody = TUTORIAL_TOUCH[tonumber(tut.step) or 0]
		if device == "pad" and tut.padBody then
			refs.tutBody.Text = Text.format(tut.padBody, tut.padArgs or {})
		elseif device == "touch" and touchBody then
			refs.tutBody.Text = Text.t(touchBody)
		else
			refs.tutBody.Text = Text.format(tut.body or "", tut.args or {})
		end
		refs.tutProgress.Text = tut.progress or ""
	elseif firstRun then
		refs.tutTitle.Text = Text.t("Mantenha a luz sobre as criaturas")
		refs.tutBody.Text = Text.t(FIRST_RUN_TEXT[device] or FIRST_RUN_TEXT.mouse)
		refs.tutProgress.Text = ""
	end

	local ids = table.concat(loadout(), ",")
	if ids ~= shownLoadout then
		buildAbilities()
	end
	updateAbilities(t)
	if levelUp then
		levelUp.update(dt, phase == "playing")
	end
end

return Hud
