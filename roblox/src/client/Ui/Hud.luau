-- HUD da partida: vida do farol e estados (tinta, pedra, sono, encanto),
-- relógio do amanhecer com os marcos dos chefes, pontuação, barra do chefe,
-- relíquias, XP, as 3 habilidades, o painel do tutorial e as cartas de
-- melhoria (LevelUp). Lê os atributos de State e do jogador a cada quadro.

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

-- Habilidades ---------------------------------------------------------------------

local function buildAbilities()
	for _, s in abilitySlots do
		s.frame:Destroy()
	end
	abilitySlots = {}
	local ids = loadout()
	shownLoadout = table.concat(ids, ",")
	for i, id in ids do
		local slot = Theme.make("TextButton", frame, {
			Size = UDim2.fromOffset(64, 64), Position = UDim2.new(0.5, (i - 2) * 80, 1, -66), AnchorPoint = Vector2.new(0.5, 1),
			BackgroundColor3 = Color3.new(0.08, 0.08, 0.13), BorderSizePixel = 0, Text = "", AutoButtonColor = false,
			Selectable = false,
		})
		Theme.corner(slot, 10)
		local stroke = Theme.stroke(slot, Theme.GOLD, 2)
		local icon = Icons.make(slot, id, 52)
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
		s.key.Text = if input then input.label("ability_" .. i) else ""
	end
end

-- Montagem -----------------------------------------------------------------------

local function build()
	if frame then
		frame:Destroy()
	end
	refs = {}
	frame = Theme.make("Frame", layer, { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, Name = "Hud" })

	-- Vida do farol e estados.
	Theme.label(frame, Text.t("Farol"), 20, Theme.GOLD, Theme.HEAD, {
		Position = UDim2.fromOffset(20, 10), Size = UDim2.fromOffset(330, 24), TextXAlignment = Enum.TextXAlignment.Left,
	})
	local _, hpFill = Theme.bar(frame, UDim2.fromOffset(330, 24), UDim2.fromOffset(20, 38), Theme.HP)
	refs.hpFill = hpFill
	refs.hpText = Theme.label(frame, "", 15, Theme.TEXT, Theme.BOLD, { Position = UDim2.fromOffset(20, 38), Size = UDim2.fromOffset(330, 24) })
	refs.status = Theme.label(frame, "", 15, Theme.TEXT, Theme.BOLD, {
		Position = UDim2.fromOffset(20, 66), Size = UDim2.fromOffset(420, 20), TextXAlignment = Enum.TextXAlignment.Left,
	})
	refs.relics = Theme.label(frame, "", 14, Color3.new(0.7, 0.9, 1.0), Theme.BODY, {
		Position = UDim2.fromOffset(20, 88), Size = UDim2.fromOffset(420, 40), TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
	})

	-- Relógio do amanhecer.
	refs.clock = Theme.label(frame, "18:00", 36, Theme.TEXT, Theme.HEAD, {
		Position = UDim2.new(0.5, 0, 0, 6), AnchorPoint = Vector2.new(0.5, 0), Size = UDim2.fromOffset(240, 40),
	})
	local dayBack, dayFill = Theme.bar(frame, UDim2.fromOffset(380, 10), UDim2.new(0.5, -190, 0, 50), Theme.GOLD)
	refs.dayBack = dayBack
	refs.dayFill = dayFill
	Theme.label(dayBack, "🌙", 16, Theme.TEXT, Theme.BOLD, { Size = UDim2.fromOffset(20, 20), Position = UDim2.new(0, -26, 0.5, -10) })
	Theme.label(dayBack, "☀️", 16, Theme.TEXT, Theme.BOLD, { Size = UDim2.fromOffset(20, 20), Position = UDim2.new(1, 6, 0.5, -10) })
	refs.bossMark = Theme.make("Frame", dayBack, {
		Size = UDim2.fromOffset(10, 10), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Theme.DANGER, BorderSizePixel = 0,
		Rotation = 45, Visible = false, ZIndex = 3,
	})
	refs.dawn = Theme.label(frame, "", 14, Theme.TEXT_DIM, Theme.BODY, {
		Position = UDim2.new(0.5, 0, 0, 62), AnchorPoint = Vector2.new(0.5, 0), Size = UDim2.fromOffset(520, 18),
	})

	-- Pontuação e menu.
	refs.score = Theme.label(frame, "0", 42, Theme.GOLD, Theme.HEAD, {
		Position = UDim2.new(1, -82, 0, 4), AnchorPoint = Vector2.new(1, 0), Size = UDim2.fromOffset(320, 46),
		TextXAlignment = Enum.TextXAlignment.Right,
	})
	refs.kills = Theme.label(frame, "", 15, Theme.TEXT, Theme.BODY, {
		Position = UDim2.new(1, -82, 0, 50), AnchorPoint = Vector2.new(1, 0), Size = UDim2.fromOffset(320, 20),
		TextXAlignment = Enum.TextXAlignment.Right,
	})
	-- Ícone de menu (três traços, ☰); também abre com a tecla P e o Menu do
	-- controle. Pausar é uma das opções do menu.
	local menuButton = Theme.button(frame, "", UDim2.fromOffset(52, 52), function()
		app.open("PlayerMenu")
	end, { Position = UDim2.new(1, -16, 0, 12), AnchorPoint = Vector2.new(1, 0) })
	for i = 0, 2 do
		local bar = Theme.make("Frame", menuButton, { Size = UDim2.fromOffset(26, 4), Position = UDim2.new(0.5, 0, 0.5, (i - 1) * 9),
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
	Theme.button(pause, Text.t("Continuar"), UDim2.fromOffset(240, 48), function()
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
	local _, xpFill = Theme.bar(frame, UDim2.fromOffset(820, 18), UDim2.new(0.5, -390, 1, -30), Theme.XP)
	refs.xpFill = xpFill
	refs.xpText = Theme.label(frame, "", 13, Theme.TEXT, Theme.BOLD, { Position = UDim2.new(0.5, -390, 1, -30), Size = UDim2.fromOffset(820, 18) })
	local medal = Theme.make("Frame", frame, {
		Size = UDim2.fromOffset(46, 46), Position = UDim2.new(0.5, -420, 1, -44), BackgroundColor3 = Color3.new(0.2, 0.12, 0.35),
		BorderSizePixel = 0,
	})
	Theme.corner(medal, 46)
	Theme.stroke(medal, Theme.GOLD, 2)
	refs.level = Theme.label(medal, "1", 22, Theme.GOLD, Theme.HEAD, { Size = UDim2.fromScale(1, 1) })

	-- Tutorial.
	local tut = Theme.panel(frame, {
		-- Um pouco à esquerda do centro: as cartas de melhoria ocupam o canto direito.
		Size = UDim2.fromOffset(640, 120), Position = UDim2.new(0.5, -70, 1, -150), AnchorPoint = Vector2.new(0.5, 1), Visible = false,
	})
	Theme.padding(tut, 14)
	Theme.list(tut, 4, false, Enum.HorizontalAlignment.Left)
	refs.tutorial = tut
	tutRaw = nil
	refs.tutTitle = Theme.label(tut, "", 20, Theme.GOLD, Theme.HEAD, { TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 1 })
	refs.tutBody = Theme.label(tut, "", 15, Theme.TEXT, Theme.BODY, {
		TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, 0, 0, 44), LayoutOrder = 2,
	})
	refs.tutProgress = Theme.label(tut, "", 14, Theme.GOOD, Theme.BOLD, { TextXAlignment = Enum.TextXAlignment.Right, LayoutOrder = 3 })

	if levelUp and levelUp.destroy then
		levelUp.destroy() -- solta a conexão da versão anterior
	end
	levelUp = LevelUp.build(app, frame)
	abilitySlots = {}
	buildAbilities()
	shownRelics = ""
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
	refs.tutorial.Visible = mode == "tutorial" and type(tut) == "table" and phase == "playing"
	if refs.tutorial.Visible then
		refs.tutTitle.Text = Text.t(tut.title or "")
		local pad = app.ctx.input and app.ctx.input.usingPad and tut.padBody
		if pad then
			refs.tutBody.Text = Text.format(tut.padBody, tut.padArgs or {})
		else
			refs.tutBody.Text = Text.format(tut.body or "", tut.args or {})
		end
		refs.tutProgress.Text = tut.progress or ""
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
