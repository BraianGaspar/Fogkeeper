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
	-- Começa abaixo da barra do Roblox (menu e chat no canto de cima).
	Theme.make("UIPadding", column, { PaddingTop = UDim.new(0, (app.safe and app.safe.top) or 0) })

	local logo = Theme.label(column, "FOGKEEPER", 88, Theme.GOLD, Theme.HEAD, { LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 96) })
	logo.TextStrokeTransparency = 0.2
	Theme.divider(column, 440, 2)
	local tagline = Theme.label(column, Text.t("As criaturas da névoa temem a luz. Resista até o amanhecer."), 19, Theme.TEXT, Theme.BODY, {
		LayoutOrder = 3, Size = UDim2.fromOffset(560, 28),
	})

	local panel = Theme.panel(column, { Size = UDim2.fromOffset(470, 430), LayoutOrder = 4 })
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
	-- Primeira vez (sem partidas nem tutorial, sozinho no servidor): convite
	-- em destaque para o tutorial, logo abaixo de Jogar.
	local function isNew(): boolean
		if type(game:GetService("Players").LocalPlayer:GetAttribute("ProgressJson")) ~= "string" then
			return false -- progresso ainda não chegou
		end
		local stats = Data.progress().stats
		return (tonumber(stats.runs) or 0) == 0 and stats.tutorial_done ~= true
			and #game:GetService("Players"):GetPlayers() <= 1
	end
	local invite = Theme.button(panel, Text.t("Primeira vez? Aprenda a jogar no tutorial"), UDim2.fromOffset(430, 50), function()
		send("tutorial")
	end, { LayoutOrder = 2, TextSize = math.floor(20 * Theme.textScale + 0.5), TextColor3 = Theme.GOLD, Visible = false })
	local inviteStroke = invite:FindFirstChildOfClass("UIStroke")
	if inviteStroke then
		inviteStroke.Color = Theme.GOLD
		inviteStroke.Thickness = 2.5
	end
	local grid = Theme.make("Frame", panel, { Size = UDim2.fromOffset(430, 280), BackgroundTransparency = 1, LayoutOrder = 3 })
	Theme.grid(grid, Vector2.new(211, 40), 8)
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
		Theme.button(grid, Text.t(e[1]), UDim2.fromOffset(211, 40), e[2], { LayoutOrder = i, TextSize = 18 })
	end
	local oil = Theme.label(panel, "", 16, Theme.GOLD, Theme.BODY, { LayoutOrder = 4 })

	local lobby = LobbyPanel.build(app, frame, {
		Size = UDim2.fromOffset(400, 230), Position = UDim2.new(1, -20, 1, -20), AnchorPoint = Vector2.new(1, 1),
	})
	local role = Theme.label(frame, "", 14, Theme.TEXT_DIM, Theme.BODY, {
		Size = UDim2.fromOffset(400, 20), Position = UDim2.new(1, -20, 1, -256), AnchorPoint = Vector2.new(1, 1), -- logo acima do painel (topo em -250)
		TextXAlignment = Enum.TextXAlignment.Right,
	})

	-- O convite troca de lugar com a frase de efeito (cabe no celular).
	local function showInvite()
		local new = isNew()
		if invite.Visible ~= new then
			invite.Visible = new
			tagline.Visible = not new
			panel.Size = UDim2.fromOffset(470, if new then 488 else 430)
		end
	end
	showInvite()

	return {
		frame = frame,
		focus = if invite.Visible then invite else play,
		update = function()
			showInvite()
			oil.Text = Text.format("Óleo do farol: %s", { Data.number(Data.progress().oil) })
			lobby.update()
			host = Data.isHost()
			-- Sozinho no servidor, "anfitrião" só confunde: sem recado.
			role.Text = if #game:GetService("Players"):GetPlayers() <= 1 then ""
				elseif host then Text.t("Você é o anfitrião: escolha o mapa e comece a partida.")
				else Text.t("O anfitrião prepara a partida. Escolha seu faroleiro e fique pronto.")
		end,
		back = function()
			return false
		end,
	}
end
