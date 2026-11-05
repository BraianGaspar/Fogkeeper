-- Dificuldade e maré, e o botão de começar. O anfitrião escolhe; os outros
-- veem a escolha dele e marcam "pronto". As marés liberadas são as do
-- anfitrião (stats.tide_max do progresso dele).

local Players = game:GetService("Players")

local Theme = require(script.Parent:WaitForChild("Theme"))
local Data = require(script.Parent:WaitForChild("Data"))
local Icons = require(script.Parent:WaitForChild("Icons"))
local LobbyPanel = require(script.Parent:WaitForChild("LobbyPanel"))
local Text = Data.Text

local function multText(m: number): string
	local s = string.format("%.2f", m)
	s = string.gsub(s, "0+$", "")
	s = string.gsub(s, "%.$", "")
	return (string.gsub(s, "%.", ","))
end

return function(app, _params)
	local frame, box = Theme.screen(1100, 690, Text.t("Escolha a dificuldade"))
	local host = Data.isHost()
	local state = app.state
	local row = Theme.make("Frame", box, { Size = UDim2.new(1, 0, 0, 170), BackgroundTransparency = 1, LayoutOrder = 10 })
	Theme.list(row, 10, true)
	local buttons = {}
	local first: GuiObject? = nil
	for i, id in Data.difficultyOrder() do
		local b = Theme.button(row, "", UDim2.fromOffset(196, 160), function()
			if host then
				app.ctx.send("difficulty", id)
			end
		end, { LayoutOrder = i })
		Theme.padding(b, 8)
		Theme.list(b, 6)
		Icons.flames(b, i, 22).LayoutOrder = 1
		Theme.label(b, Data.difficultyName(id), 22, Theme.TEXT, Theme.HEAD, { LayoutOrder = 2 })
		Theme.label(b, Text.format("Pontuação ×%s", { multText(Data.difficultyMult(id)) }), 14, Theme.GOLD, Theme.BOLD, { LayoutOrder = 3 })
		buttons[id] = b
		first = first or b
	end

	-- Marés: lista cumulativa (a Maré N soma as regras de 1 até N).
	local tideRow = Theme.make("Frame", box, { Size = UDim2.new(1, 0, 0, 42), BackgroundTransparency = 1, LayoutOrder = 20 })
	Theme.list(tideRow, 12, true)
	local hostPlayer = Data.host()
	local maxTide = 0
	if hostPlayer then
		maxTide = math.min(#Data.tides(), (Data.progress(hostPlayer).stats or {}).tide_max or 0)
	end
	local tideLabel = Theme.label(tideRow, "", 18, Theme.WATER, Theme.HEAD, { Size = UDim2.fromOffset(240, 40), LayoutOrder = 2 })
	local tideMinus = Theme.smallButton(tideRow, "‹", UDim2.fromOffset(40, 40), function()
		if host then
			app.ctx.send("tide", math.max(0, (state:GetAttribute("Tide") or 0) - 1))
		end
	end, { LayoutOrder = 1 })
	local tidePlus = Theme.smallButton(tideRow, "›", UDim2.fromOffset(40, 40), function()
		if host then
			app.ctx.send("tide", math.min(maxTide, (state:GetAttribute("Tide") or 0) + 1))
		end
	end, { LayoutOrder = 3 })
	tideRow.Visible = maxTide > 0
	local tideRules = Theme.label(box, "", 13, Theme.TEXT_DIM, Theme.BODY, {
		LayoutOrder = 21, Size = UDim2.new(1, 0, 0, 60), Visible = maxTide > 0,
	})

	local lobby = LobbyPanel.build(app, box, { Size = UDim2.fromOffset(560, 190), LayoutOrder = 30 })

	local actions = Theme.make("Frame", box, { Size = UDim2.new(1, 0, 0, 52), BackgroundTransparency = 1, LayoutOrder = 40 })
	Theme.list(actions, 14, true)
	Theme.backButton(actions, app, 1)
	local start = Theme.button(actions, "", UDim2.fromOffset(300, 50), function()
		if host then
			app.ctx.send("start")
		else
			app.ctx.send("ready", not Players.LocalPlayer:GetAttribute("Ready"))
		end
	end, { LayoutOrder = 2, TextColor3 = Theme.GOLD, TextSize = 26 })

	return {
		frame = frame,
		focus = if host then first else start,
		update = function()
			host = Data.isHost()
			local current = state:GetAttribute("Difficulty") or "normal"
			for id, b in buttons do
				Theme.setSelected(b, id == current)
				Theme.setDisabled(b, not host and id ~= current)
			end
			local tide = state:GetAttribute("Tide") or 0
			tideLabel.Text = if tide > 0 then Text.format("Maré %d", { math.floor(tide) }) else Text.t("Sem maré")
			local rules = {}
			for i = 1, tide do
				local t = Data.tides()[i]
				if t then
					table.insert(rules, Text.t(t.desc or ""))
				end
			end
			tideRules.Text = table.concat(rules, "  •  ")
			tideMinus.Visible = host
			tidePlus.Visible = host
			lobby.update()
			if host then
				start.Text = Text.t("Começar")
			else
				start.Text = if Players.LocalPlayer:GetAttribute("Ready") then "✅ " .. Text.t("Pronto") else Text.t("Pronto")
			end
		end,
	}
end
