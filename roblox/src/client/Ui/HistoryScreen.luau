-- Histórico das últimas partidas do jogador (ProgressJson.history).

local Theme = require(script.Parent:WaitForChild("Theme"))
local Data = require(script.Parent:WaitForChild("Data"))
local Text = Data.Text

return function(app, _params)
	local frame, box = Theme.screen(1000, 640, Text.t("Histórico de partidas"))
	local history = Data.progress().history or {}
	Theme.label(box, Text.format("%d partidas registradas", { #history }), 16, Theme.GOLD, Theme.BOLD, { LayoutOrder = 10 })
	local scroll = Theme.scroll(box, UDim2.new(1, 0, 0, 450), { LayoutOrder = 20, Selectable = true }) -- controle: selecionar e rolar com o analógico
	Theme.list(scroll, 6)
	if #history == 0 then
		Theme.label(scroll, Text.t("Nenhuma partida ainda. Acenda o farol!"), 18, Theme.TEXT_DIM, Theme.BODY, { LayoutOrder = 1 })
	end
	for i, h in history do
		local row = Theme.make("Frame", scroll, {
			Size = UDim2.new(1, -12, 0, 58), BackgroundColor3 = Theme.PANEL_LIGHT, BackgroundTransparency = 0.3, BorderSizePixel = 0,
			LayoutOrder = i,
		})
		Theme.corner(row, 8)
		local win = h.victory == true
		Theme.label(row, Text.t(if win then "Vitória" else "Derrota"), 18, if win then Theme.GOOD else Theme.DANGER, Theme.HEAD, {
			Position = UDim2.fromOffset(14, 6), Size = UDim2.fromOffset(130, 24), TextXAlignment = Enum.TextXAlignment.Left,
		})
		Theme.label(row, h.date or "", 13, Theme.TEXT_DIM, Theme.BODY, {
			Position = UDim2.fromOffset(14, 32), Size = UDim2.fromOffset(130, 18), TextXAlignment = Enum.TextXAlignment.Left,
		})
		local parts = { Text.t(Data.MODE_NAMES[h.mode or "normal"] or "Normal") }
		if h.mode ~= "boss_rush" then
			table.insert(parts, Text.t(Data.map(h.map).name))
		end
		table.insert(parts, Data.difficultyName(h.difficulty))
		if (h.tide or 0) > 0 then
			table.insert(parts, Text.format("Maré %d", { h.tide }))
		end
		Theme.label(row, table.concat(parts, "  •  "), 15, Theme.TEXT, Theme.BODY, {
			Position = UDim2.fromOffset(160, 6), Size = UDim2.new(1, -380, 0, 22), TextXAlignment = Enum.TextXAlignment.Left,
		})
		Theme.label(row, Text.t("Duração") .. ": " .. Data.time(h.seconds) .. "   •   " .. Text.format("Nível %d", { h.level or 1 }), 13,
			Theme.TEXT_DIM, Theme.BODY, {
				Position = UDim2.fromOffset(160, 30), Size = UDim2.new(1, -380, 0, 20), TextXAlignment = Enum.TextXAlignment.Left,
			})
		Theme.label(row, Text.format("%s pts", { Data.number(h.score) }), 22, Theme.GOLD, Theme.HEAD, {
			Position = UDim2.new(1, -14, 0, 14), AnchorPoint = Vector2.new(1, 0), Size = UDim2.fromOffset(200, 28),
			TextXAlignment = Enum.TextXAlignment.Right,
		})
	end
	local back = Theme.backButton(box, app, 30)
	return { frame = frame, focus = back }
end
