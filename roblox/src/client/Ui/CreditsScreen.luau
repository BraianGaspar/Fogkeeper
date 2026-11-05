-- Créditos e licenças da versão Roblox. Aqui não há motor Godot nem a fonte
-- Cinzel (o Roblox usa as próprias fontes), então só ficam autoria, origem
-- das lendas e o aviso de uso de IA.

local Theme = require(script.Parent:WaitForChild("Theme"))
local Data = require(script.Parent:WaitForChild("Data"))
local Text = Data.Text

return function(app, _params)
	local frame, box = Theme.screen(820, 560, Text.t("Créditos e licenças"))
	local lines = {
		{ "FOGKEEPER", 34, Theme.GOLD, Theme.HEAD },
		{ Text.t("Criado por Braian Gaspar da Rosa.") .. " " .. Text.t("Todos os direitos reservados."), 17, Theme.TEXT, Theme.BODY },
		{ Text.t("Criaturas e lendas inspiradas em mitos de domínio público das culturas grega, hebraica, nórdica, brasileira, japonesa e egípcia."),
			15, Theme.TEXT_DIM, Theme.BODY },
		{ Text.t("Código, arte, sons e traduções feitos com assistência de IA (Claude, da Anthropic) e revisados pelo autor."),
			15, Theme.TEXT_DIM, Theme.BODY },
		{ Text.t("Versão para Roblox do jogo original feito em Godot."), 15, Theme.TEXT_DIM, Theme.BODY },
	}
	for i, l in lines do
		Theme.label(box, l[1], l[2], l[3], l[4], { LayoutOrder = 10 + i, Size = UDim2.new(1, 0, 0, l[2] * 2 + 16) })
	end
	local back = Theme.backButton(box, app, 30)
	return { frame = frame, focus = back }
end
