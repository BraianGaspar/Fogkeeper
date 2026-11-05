-- Confirmação com título, texto e opções. params = {title, body, options = {{texto, fn}}}.
-- Cada opção fecha esta tela antes de rodar a ação.

local Theme = require(script.Parent:WaitForChild("Theme"))
local Data = require(script.Parent:WaitForChild("Data"))
local Text = Data.Text

return function(app, params)
	local frame, box = Theme.screen(620, 300, params.title)
	box.AutomaticSize = Enum.AutomaticSize.Y
	Theme.label(box, params.body or "", 17, Theme.TEXT, Theme.BODY, { LayoutOrder = 10, Size = UDim2.new(1, 0, 0, 90) })
	local row = Theme.make("Frame", box, { Size = UDim2.new(1, 0, 0, 50), BackgroundTransparency = 1, LayoutOrder = 20 })
	Theme.list(row, 12, true)
	local first: GuiObject? = nil
	for i, opt in params.options or {} do
		local b = Theme.button(row, opt[1], UDim2.fromOffset(240, 46), function()
			app.back()
			if opt[2] then
				opt[2]()
			end
		end, { LayoutOrder = i })
		first = first or b
	end
	if not params.options or #params.options == 0 then
		first = Theme.backButton(row, app, 1, Text.t("Voltar"))
	end
	return { frame = frame, focus = first, closable = true }
end
