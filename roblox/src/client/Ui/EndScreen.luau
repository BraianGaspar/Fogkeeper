-- Fim da partida (ResultJson): título, estatísticas, pontuação por critério,
-- dano por fonte, brasas, recompensas do jogador e, ao amanhecer, a
-- votação para continuar noite adentro. Volta sozinho ao saguão em ReturnAt.

local Players = game:GetService("Players")

local Theme = require(script.Parent:WaitForChild("Theme"))
local Data = require(script.Parent:WaitForChild("Data"))
local Text = Data.Text

local function multText(m: number): string
	local s = string.format("%.2f", m or 1)
	s = string.gsub(s, "0+$", "")
	s = string.gsub(s, "%.$", "")
	return (string.gsub(s, "%.", ","))
end

local function column(parent: Instance, title: string, order: number): Frame
	local col = Theme.make("Frame", parent, { Size = UDim2.new(0.5, -12, 1, 0), BackgroundTransparency = 1, LayoutOrder = order })
	Theme.list(col, 2, false, Enum.HorizontalAlignment.Left)
	Theme.label(col, title, 19, Theme.GOLD, Theme.HEAD, { LayoutOrder = 0, TextXAlignment = Enum.TextXAlignment.Left })
	return col
end

return function(app, _params)
	local state = app.state
	local r = Data.decode(state:GetAttribute("ResultJson")) or {}
	local score = r.score or {}
	local mode = r.mode or "normal"
	local victory = r.victory == true
	-- Morrer na primeira noite do modo sem fim deixa nights = 0; o atributo
	-- Endless de State continua ligado nesse caso.
	local endless = (r.nights or 0) > 0 or state:GetAttribute("Endless") == true
	local map = Data.map(r.map)

	local frame, box = Theme.screen(980, 680, nil)
	local heading = Text.t("A luz se apagou")
	if mode == "tutorial" then
		heading = Text.t("Pronto!")
	elseif mode == "boss_rush" then
		heading = if victory then Text.t("Todos os chefes caíram!") else Text.format("Chefes derrotados: %d de %d", { math.floor(r.bosses or 0), math.floor(r.rushTotal or 15) })
	elseif victory and not endless then
		heading = Text.t("Amanheceu!")
	elseif endless then
		-- Noite 1 é a normal; a noite em curso no modo sem fim é nights + 2 (como o atributo Night).
		heading = Text.format("A luz se apagou na noite %d", { math.floor(r.nights or 0) + 2 })
	end
	local head = Theme.title(box, heading, 42, 0)
	head.TextColor3 = if victory then Theme.GOLD else Theme.DANGER
	local sub = ""
	if mode == "tutorial" then
		sub = Text.t("Na partida de verdade, resista até o amanhecer (06:00). Boa sorte, faroleiro.")
	elseif mode == "boss_rush" then
		sub = Text.format("Modo Chefões em %s.", { Data.time(r.seconds) })
	elseif victory and not endless then
		sub = Text.format("O sol nasceu às 06:00 sobre %s. O farol resistiu à noite inteira.", { Text.t(map.name) })
	elseif not endless then
		local secs = r.seconds or 0
		local left = math.max(0, Data.RUN_DURATION - secs)
		local hours = left / Data.RUN_DURATION * 12
		sub = Text.format("A luz se apagou às %s. Faltavam %s (%s de partida) para o amanhecer.", {
			Data.clock(secs), string.format("%dh%02d", math.floor(hours), math.floor((hours % 1) * 60)), Data.time(left) })
	end
	Theme.label(box, sub, 17, Theme.TEXT, Theme.BODY, { LayoutOrder = 10, Size = UDim2.new(1, 0, 0, 44) })

	local cols = Theme.make("Frame", box, { Size = UDim2.new(1, 0, 0, 270), BackgroundTransparency = 1, LayoutOrder = 20 })
	Theme.list(cols, 24, true)
	local stats = column(cols, Text.t("Partida"), 1)
	local n = 1
	local function stat(parent, name, value, color)
		n += 1
		Theme.statRow(parent, name, value, color, n)
	end
	if mode ~= "boss_rush" then
		stat(stats, Text.t("Mapa"), Text.t(map.name))
	end
	stat(stats, Text.t("Modo"), Text.t(Data.MODE_NAMES[mode] or mode))
	stat(stats, Text.t("Dificuldade"), Data.difficultyName(r.difficulty))
	if (r.tide or 0) > 0 then
		stat(stats, Text.t("Maré"), tostring(r.tide), Theme.WATER)
	end
	stat(stats, Text.t("Faroleiro"), Text.t(Data.hero(Players.LocalPlayer:GetAttribute("Hero")).name))
	stat(stats, Text.t("Tempo sobrevivido"), Data.time(r.seconds))
	stat(stats, Text.t("Nível alcançado"), tostring(r.level or 1))
	stat(stats, Text.t("Criaturas queimadas"), Data.number(r.kills))
	stat(stats, Text.t("Chefes derrotados"), tostring(r.bosses or 0))

	-- O tutorial não vale pontos: a coluna de pontuação fica escondida.
	local points = column(cols, Text.t("Pontuação"), 2)
	points.Visible = mode ~= "tutorial"
	local rows = {
		{ "Criaturas queimadas", score.kills }, { "Tempo sobrevivido", score.survival }, { "Modo sem fim", score.endless },
		{ "Bônus de chefes", score.bosses }, { "Bônus de vitória", score.victory }, { "Bônus de vida restante", score.health },
	}
	for _, row in rows do
		if row[1] ~= "Modo sem fim" or (row[2] or 0) > 0 then
			stat(points, Text.t(row[1]), "+" .. Data.number(row[2] or 0))
		end
	end
	stat(points, Text.t("Subtotal"), Data.number(score.subtotal), Theme.TEXT)
	stat(points, Text.format("Multiplicador (%s)", { Data.difficultyName(r.difficulty) }), "×" .. multText(score.multiplier), Theme.GOLD)
	local total = Theme.label(points, "0", 40, Theme.GOLD, Theme.HEAD, {
		LayoutOrder = 99, TextXAlignment = Enum.TextXAlignment.Right, Size = UDim2.new(1, 0, 0, 46),
	})

	-- Dano por fonte, brasas, relíquias.
	local extras = {}
	local damage = {}
	for _, d in r.damage or {} do
		if type(d) == "table" and d[1] then
			table.insert(damage, string.format("%s %d%%", Text.t(Data.DAMAGE_NAMES[d[1]] or d[1]), math.floor((d[2] or 0) * 100 + 0.5)))
		end
	end
	if #damage > 0 then
		table.insert(extras, Text.format("Dano: %s", { table.concat(damage, "  ·  ") }))
	end
	local em = r.embers or { 0, 0 }
	-- Brasas valem XP fracionado no cooperativo: %d exige inteiro.
	table.insert(extras, Text.format("Brasas: %d recolhidas, %d apagadas", { math.floor(em[1] or 0), math.floor(em[2] or 0) }))
	if r.relics and #r.relics > 0 then
		local names = {}
		for _, id in r.relics do
			table.insert(names, Text.t(Data.relic(id).name))
		end
		table.insert(extras, Text.format("Relíquias: %s", { table.concat(names, ", ") }))
	end
	if r.revived then
		table.insert(extras, Text.t("Farol reacendido com Robux: esta partida não entra no ranking mundial."))
	end
	Theme.label(box, table.concat(extras, "\n"), 14, Theme.TEXT, Theme.BODY, { LayoutOrder = 30, Size = UDim2.new(1, 0, 0, 72) })

	-- Recompensas deste jogador.
	local mine = (r.rewards or {})[tostring(Players.LocalPlayer.UserId)] or {}
	local rewards = {}
	if (mine.oil or 0) > 0 then
		table.insert(rewards, Text.format("+%d de óleo (total: %s)", { math.floor(mine.oil), Data.number(Data.progress().oil) }))
	end
	for _, u in mine.unlocks or {} do
		table.insert(rewards, Text.format("Liberado: %s", { Text.t(u) }))
	end
	for _, a in mine.achievements or {} do
		table.insert(rewards, Text.format("Conquista: %s", { Text.t(a) }))
	end
	if (mine.tide or 0) > 0 then
		table.insert(rewards, Text.format("Liberado: %s", { Text.format("Maré %d", { math.floor(mine.tide) }) }))
	end
	Theme.label(box, table.concat(rewards, "   •   "), 15, Color3.new(0.45, 0.95, 0.85), Theme.BOLD, {
		LayoutOrder = 40, Size = UDim2.new(1, 0, 0, 40),
	})

	-- Continuar noite adentro (vitória ao amanhecer, modo normal ou diário).
	local actions = Theme.make("Frame", box, { Size = UDim2.new(1, 0, 0, 52), BackgroundTransparency = 1, LayoutOrder = 50 })
	Theme.list(actions, 12, true)
	local canContinue = if r.canContinue ~= nil then r.canContinue == true else (victory and mode ~= "boss_rush" and mode ~= "tutorial")
	local voted = false
	local continueButton = Theme.button(actions, Text.t("Continuar noite adentro"), UDim2.fromOffset(360, 48), function()
		voted = not voted
		app.ctx.send("endless", voted)
	end, { LayoutOrder = 1, Visible = canContinue, TextColor3 = Theme.GOLD })
	local ranking = Theme.button(actions, Text.t("Ver ranking"), UDim2.fromOffset(240, 48), function()
		app.open("RankingScreen", { mode = mode, map = r.map, difficulty = r.difficulty })
	end, { LayoutOrder = 2 })
	local footer = Theme.label(box, "", 14, Theme.TEXT_DIM, Theme.BODY, { LayoutOrder = 60 })
	if canContinue then
		Theme.label(box, Text.t("Modo sem fim: a névoa volta e as noites seguem, cada vez mais difíceis. Os pontos continuam somando nesta partida."),
			13, Theme.TEXT_DIM, Theme.BODY, { LayoutOrder = 61, Size = UDim2.new(1, 0, 0, 36) })
	end

	local shownTotal = 0
	local counted = false
	local target = score.total or 0
	return {
		frame = frame,
		focus = if canContinue then continueButton else ranking,
		back = function()
			return false
		end,
		update = function(dt: number)
			shownTotal = math.min(target, shownTotal + math.max(1, target * dt / 1.2))
			-- Fim da contagem: um toque de recompensa (só se houve pontos ou óleo).
			if not counted and shownTotal >= target then
				counted = true
				if (target > 0 or (mine.oil or 0) > 0) and app.ctx and app.ctx.sounds then
					app.ctx.sounds.play("meta")
				end
			end
			total.Text = Data.number(shownTotal)
			local left = (state:GetAttribute("ReturnAt") or 0) - workspace:GetServerTimeNow()
			local votes = math.floor(state:GetAttribute("EndlessVotes") or 0)
			local text = Text.format("Voltando ao saguão em %d s", { math.max(0, math.ceil(left)) })
			if canContinue then
				text ..= string.format("   •   %s: %d/%d", Text.t("Modo sem fim"), votes, #Players:GetPlayers())
			end
			footer.Text = text
			Theme.setSelected(continueButton, voted)
			-- Voto marcado também por símbolo (não só pela cor da borda).
			continueButton.Text = (if voted then "✓ " else "") .. Text.t("Continuar noite adentro")
		end,
	}
end
