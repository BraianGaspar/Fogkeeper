-- Tela inicial (saguão): logotipo, menu como no Godot e o painel com os
-- jogadores do servidor. O anfitrião (vaga 1) prepara a partida; os outros
-- escolhem o próprio faroleiro e as habilidades e marcam "pronto".

local Theme = require(script.Parent:WaitForChild("Theme"))
local Data = require(script.Parent:WaitForChild("Data"))
local LobbyPanel = require(script.Parent:WaitForChild("LobbyPanel"))
local Text = Data.Text

return function(app, _params)
	local frame = Theme.make("Frame", nil, { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 })
	local column = Theme.make("Frame", frame, {
		Size = UDim2.new(0.5, 0, 1, 0), BackgroundTransparency = 1,
	})
	local layout = Theme.list(column, 6)
	layout.VerticalAlignment = Enum.VerticalAlignment.Center

	local logo = Theme.label(column, "FOGKEEPER", 88, Theme.GOLD, Theme.HEAD, { LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 96) })
	logo.TextStrokeTransparency = 0.2
	Theme.divider(column, 440, 2)
	Theme.label(column, Text.t("As criaturas da névoa temem a luz. Resista até o amanhecer."), 19, Theme.TEXT, Theme.BODY, {
		LayoutOrder = 3, Size = UDim2.fromOffset(560, 28),
	})

	local panel = Theme.panel(column, { Size = UDim2.fromOffset(470, 450), LayoutOrder = 4 })
	Theme.padding(panel, 18)
	Theme.list(panel, 8)
	local host = Data.isHost()
	local function send(...)
		app.ctx.send(...)
	end

	local play = Theme.button(panel, Text.t("Jogar"), UDim2.fromOffset(430, 54), function()
		if host then
			send("mode", "normal")
			app.open("MapScreen", { flow = true })
		else
			app.open("HeroScreen", { flow = true })
		end
	end, { LayoutOrder = 1, TextSize = 28, TextColor3 = Theme.GOLD })
	local grid = Theme.make("Frame", panel, { Size = UDim2.fromOffset(430, 300), BackgroundTransparency = 1, LayoutOrder = 2 })
	Theme.grid(grid, Vector2.new(211, 42), 8)
	local entries = {
		{ "Desafio diário", function()
			app.open("DailyScreen")
		end },
		{ "Modo Chefões", function()
			if host then
				send("mode", "boss_rush")
			end
			app.open("HeroScreen", { flow = true })
		end },
		{ "Oficina", function()
			app.open("WorkshopScreen")
		end },
		{ "Bestiário", function()
			app.open("BestiaryScreen")
		end },
		{ "Conquistas", function()
			app.open("AchievementsScreen")
		end },
		{ "Ranking", function()
			app.open("RankingScreen")
		end },
		{ "Histórico", function()
			app.open("HistoryScreen")
		end },
		{ "Tutorial", function()
			if #game:GetService("Players"):GetPlayers() > 1 then
				app.toast(Text.t("O tutorial é só para quem está sozinho no servidor."), Theme.DANGER)
			else
				send("tutorial")
			end
		end },
		{ "Configurações", function()
			app.open("SettingsScreen")
		end },
		{ "Créditos e licenças", function()
			app.open("CreditsScreen")
		end },
		{ "Loja", function()
			app.open("ShopScreen")
		end },
	}
	for i, e in entries do
		Theme.button(grid, Text.t(e[1]), UDim2.fromOffset(211, 42), e[2], { LayoutOrder = i, TextSize = 18 })
	end
	local oil = Theme.label(panel, "", 16, Theme.GOLD, Theme.BODY, { LayoutOrder = 3 })

	local lobby = LobbyPanel.build(app, frame, {
		Size = UDim2.fromOffset(400, 230), Position = UDim2.new(1, -20, 1, -20), AnchorPoint = Vector2.new(1, 1),
	})
	local role = Theme.label(frame, "", 14, Theme.TEXT_DIM, Theme.BODY, {
		Size = UDim2.fromOffset(400, 20), Position = UDim2.new(1, -20, 1, -256), AnchorPoint = Vector2.new(1, 1), -- logo acima do painel (topo em -250)
		TextXAlignment = Enum.TextXAlignment.Right,
	})

	return {
		frame = frame,
		focus = play,
		update = function()
			oil.Text = Text.format("Óleo do farol: %s", { Data.number(Data.progress().oil) })
			lobby.update()
			host = Data.isHost()
			role.Text = if host then Text.t("Você é o anfitrião: escolha o mapa e comece a partida.")
				else Text.t("O anfitrião prepara a partida. Escolha seu faroleiro e fique pronto.")
		end,
		back = function()
			return false
		end,
	}
end
