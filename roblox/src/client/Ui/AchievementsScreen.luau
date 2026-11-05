-- Conquistas do jogador: liberadas em dourado, as outras apagadas.

local Theme = require(script.Parent:WaitForChild("Theme"))
local Data = require(script.Parent:WaitForChild("Data"))
local Text = Data.Text

return function(app, _params)
	local frame, box = Theme.screen(1000, 640, Text.t("Conquistas"))
	local done = Data.progress().achievements
	local list = Data.Achievements.LIST or {}
	local count = 0
	for _, a in list do
		if done[a.id] then
			count += 1
		end
	end
	Theme.label(box, Text.format("%d de %d conquistas", { count, #list }), 17, Theme.GOLD, Theme.BOLD, { LayoutOrder = 10 })
	local scroll = Theme.scroll(box, UDim2.new(1, 0, 0, 460), { LayoutOrder = 20, Selectable = true }) -- controle: selecionar e rolar com o analógico
	Theme.grid(scroll, Vector2.new(460, 66), 8)
	for i, a in list do
		local on = done[a.id] == true
		local cell = Theme.make("Frame", scroll, {
			BackgroundColor3 = if on then Color3.new(0.2, 0.15, 0.07) else Theme.PANEL_LIGHT, BackgroundTransparency = if on then 0.1 else 0.5,
			BorderSizePixel = 0, LayoutOrder = i,
		})
		Theme.corner(cell, 8)
		Theme.stroke(cell, if on then Theme.GOLD else Theme.GOLD_DARK, if on then 2 else 1, if on then 0 else 0.5)
		Theme.label(cell, if on then "🏆" else "🔒", 26, Theme.GOLD, Theme.BOLD, { Size = UDim2.fromOffset(56, 66) })
		Theme.label(cell, Text.t(a.name or a.id), 16, if on then Theme.GOLD else Theme.TEXT_DIM, Theme.HEAD, {
			Position = UDim2.fromOffset(56, 6), Size = UDim2.new(1, -64, 0, 22), TextXAlignment = Enum.TextXAlignment.Left,
		})
		Theme.label(cell, Text.t(a.desc or ""), 13, if on then Theme.TEXT else Theme.TEXT_DIM, Theme.BODY, {
			Position = UDim2.fromOffset(56, 28), Size = UDim2.new(1, -64, 0, 34), TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
		})
	end
	local back = Theme.backButton(box, app, 30)
	return { frame = frame, focus = back }
end
