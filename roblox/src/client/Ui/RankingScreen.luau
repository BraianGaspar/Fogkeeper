-- Ranking mundial (top 10). Abas: partida normal (por mapa e dificuldade),
-- Modo Chefões e o desafio de hoje. O cliente pede a chave com
-- Lobby("ranking", chave) e mostra TopJson quando TopKey bate.

local Theme = require(script.Parent:WaitForChild("Theme"))
local Data = require(script.Parent:WaitForChild("Data"))
local Text = Data.Text

return function(app, params)
	params = params or {}
	local state = app.state
	local mode = params.mode or "normal"
	local map = params.map or state:GetAttribute("Map") or Data.mapOrder()[1]
	local difficulty = params.difficulty or state:GetAttribute("Difficulty") or "normal"
	local daily = Data.decode(state:GetAttribute("DailyJson")) or {}
	local key = if mode == "daily" then "daily|" .. (daily.date or "")
		elseif mode == "boss_rush" then "boss_rush||normal"
		else string.format("normal|%s|%s", map, difficulty)

	local frame, box = Theme.screen(900, 660, Text.t("Ranking"))
	local function reopen(changes)
		local p = { mode = mode, map = map, difficulty = difficulty }
		for k, v in changes do
			p[k] = v
		end
		app.back()
		app.open("RankingScreen", p)
	end

	local tabs = Theme.make("Frame", box, { Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1, LayoutOrder = 10 })
	Theme.list(tabs, 8, true)
	local first: GuiObject? = nil
	for i, m in { { "normal", "Normal" }, { "boss_rush", "Modo Chefões" }, { "daily", "Diário de hoje" } } do
		local b = Theme.smallButton(tabs, Text.t(m[2]), UDim2.fromOffset(220, 38), function()
			if m[1] ~= mode then
				reopen({ mode = m[1] })
			end
		end, { LayoutOrder = i })
		Theme.setSelected(b, m[1] == mode)
		if m[1] == mode then
			first = b
		end
	end
	if mode == "normal" then
		local names, ids = {}, Data.mapOrder()
		for _, id in ids do
			table.insert(names, Text.t(Data.map(id).name))
		end
		local filters = Theme.make("Frame", box, { Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1, LayoutOrder = 11 })
		Theme.list(filters, 16, true)
		Theme.selector(filters, names, table.find(ids, map) or 1, function(i)
			reopen({ map = ids[i] })
		end, 320).LayoutOrder = 1
		local dnames, dids = {}, Data.difficultyOrder()
		for _, id in dids do
			table.insert(dnames, Data.difficultyName(id))
		end
		Theme.selector(filters, dnames, table.find(dids, difficulty) or 1, function(i)
			reopen({ difficulty = dids[i] })
		end, 260).LayoutOrder = 2
	end

	local head = Theme.make("Frame", box, { Size = UDim2.new(1, -40, 0, 24), BackgroundTransparency = 1, LayoutOrder = 20 })
	local function cols(parent: Instance, a: string, b: string, c: string, color: Color3, font: Enum.Font)
		Theme.label(parent, a, 16, color, font, { Size = UDim2.fromScale(0.15, 1), TextXAlignment = Enum.TextXAlignment.Left })
		Theme.label(parent, b, 16, color, font, { Size = UDim2.fromScale(0.55, 1), Position = UDim2.fromScale(0.15, 0), TextXAlignment = Enum.TextXAlignment.Left })
		Theme.label(parent, c, 16, color, font, { Size = UDim2.fromScale(0.3, 1), Position = UDim2.fromScale(0.7, 0), TextXAlignment = Enum.TextXAlignment.Right })
	end
	cols(head, Text.t("Posição"), Text.t("Jogador"), Text.t("Pontos"), Theme.GOLD, Theme.BOLD)
	local rows = Theme.make("Frame", box, { Size = UDim2.new(1, -40, 0, 330), BackgroundTransparency = 1, LayoutOrder = 21 })
	Theme.list(rows, 4)
	local status = Theme.label(box, "", 15, Theme.TEXT_DIM, Theme.BODY, { LayoutOrder = 22 })
	Theme.backButton(box, app, 30)

	app.ctx.send("ranking", key)
	local shown = nil
	local resend = 1
	return {
		frame = frame,
		focus = first,
		update = function(dt: number)
			local raw = state:GetAttribute("TopJson")
			if state:GetAttribute("TopKey") ~= key then
				status.Text = "…"
				-- O pedido pode ter caído no intervalo mínimo do servidor
				-- (trocas rápidas de aba): pede de novo.
				resend -= dt
				if resend <= 0 then
					resend = 1.5
					app.ctx.send("ranking", key)
				end
				return
			end
			if raw == shown then
				return
			end
			shown = raw
			rows:ClearAllChildren()
			Theme.list(rows, 4)
			local top = Data.decode(raw) or {}
			for i, entry in top do
				local r = Theme.make("Frame", rows, { Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1, LayoutOrder = i })
				local me = entry.name == game:GetService("Players").LocalPlayer.Name
				cols(r, Data.ordinal(i), tostring(entry.name), Data.number(entry.score),
					if me then Theme.GOLD elseif i <= 3 then Theme.TEXT else Theme.TEXT_DIM, if me then Theme.BOLD else Theme.BODY)
			end
			status.Text = if #top == 0 then Text.t("Nenhuma partida nesta categoria ainda.") else ""
		end,
	}
end
