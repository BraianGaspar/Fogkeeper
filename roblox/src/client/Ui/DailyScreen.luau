-- Desafio diário: regras do dia (mapa, faroleiro, maré, semente), iguais
-- para todo mundo. O anfitrião começa; os outros esperam.

local Theme = require(script.Parent:WaitForChild("Theme"))
local Data = require(script.Parent:WaitForChild("Data"))
local Text = Data.Text

return function(app, _params)
	local frame, box = Theme.screen(700, 400, Text.t("Desafio diário"))
	local rules = Data.decode(app.state:GetAttribute("DailyJson")) or {}
	local body = if rules.date
		then Text.format("Hoje (%s): %s, com %s, na Maré %d. Todo mundo joga a mesma noite, com a mesma semente.", {
			rules.date, Text.t(Data.map(rules.map).name), Text.t(Data.hero(rules.hero).name), math.floor(rules.tide or 0) })
		else ""
	Theme.label(box, body, 18, Theme.TEXT, Theme.BODY, { LayoutOrder = 10, Size = UDim2.new(1, 0, 0, 90) })
	Theme.label(box, Text.t("Os bônus da oficina não valem no desafio diário: todos começam iguais."), 14, Theme.TEXT_DIM, Theme.BODY,
		{ LayoutOrder = 12 })
	local best = (Data.progress().stats or {}).daily_best
	if best and rules.date and best.date == rules.date then
		Theme.label(box, Text.format("Seu melhor hoje: %s pontos.", { Data.number(best.score) }), 16, Theme.GOLD, Theme.BOLD, { LayoutOrder = 11 })
	end
	local row = Theme.make("Frame", box, { Size = UDim2.new(1, 0, 0, 52), BackgroundTransparency = 1, LayoutOrder = 20 })
	Theme.list(row, 14, true)
	Theme.backButton(row, app, 1)
	local play = Theme.button(row, Text.t("Jogar agora"), UDim2.fromOffset(260, 50), function()
		if Data.isHost() then
			app.ctx.send("mode", "daily")
			-- O servidor ignora comandos do saguão a menos de Balance.LOBBY_COOLDOWN
			-- (0,25 s) do anterior: o "start" vai um pouco depois.
			task.delay(0.4, function()
				if app.state:GetAttribute("Phase") == "lobby" then
					app.ctx.send("start")
				end
			end)
		else
			app.toast(Text.t("O anfitrião prepara a partida. Escolha seu faroleiro e fique pronto."), Theme.TEXT)
		end
	end, { LayoutOrder = 2, TextColor3 = Theme.GOLD })
	return { frame = frame, focus = play }
end
