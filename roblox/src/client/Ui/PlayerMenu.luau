-- Menu do jogador durante a partida (ícone ☰ no canto, tecla P, Menu do
-- controle). Abrir o menu NÃO pausa: "Pausar" é uma opção dele e congela a
-- noite para todos (o servidor para a simulação); qualquer faroleiro retoma
-- pelo próprio menu ou pelo aviso de pausa do HUD.
-- "Sair para o menu" encerra a noite para todos e só o anfitrião pode; a
-- partida abandonada não dá recompensas nem entra no ranking.

local Players = game:GetService("Players")

local Theme = require(script.Parent:WaitForChild("Theme"))
local Data = require(script.Parent:WaitForChild("Data"))
local Text = Data.Text

-- Anfitrião: quem ocupa a menor vaga (mesma regra do servidor).
local function isHost(): boolean
	local me = Players.LocalPlayer
	local mine = me:GetAttribute("Slot")
	if not mine then
		return false
	end
	for _, p in Players:GetPlayers() do
		local s = p:GetAttribute("Slot")
		if s and s < mine then
			return false
		end
	end
	return true
end

return function(app, _params)
	local phase = app.state:GetAttribute("Phase")
	local playing = phase == "playing"
	local solo = #Players:GetPlayers() <= 1
	local frame, box = Theme.screen(520, 540, Text.t("Menu"))
	local note = Theme.label(box, "", 15, Theme.TEXT_DIM, Theme.BODY, { LayoutOrder = 10 })
	local resume = Theme.button(box, Text.t("Voltar ao jogo"), UDim2.fromOffset(300, 48), function()
		app.back()
	end, { LayoutOrder = 19, TextColor3 = Theme.GOLD })
	-- Pausar / retomar: o texto acompanha o estado replicado.
	local pause = Theme.button(box, "", UDim2.fromOffset(300, 48), function()
		app.ctx.send("pause", app.state:GetAttribute("Paused") ~= true)
	end, { LayoutOrder = 20 })
	if not playing then
		Theme.setDisabled(pause, true)
	end
	Theme.button(box, Text.t("Configurações"), UDim2.fromOffset(300, 48), function()
		app.open("SettingsScreen")
	end, { LayoutOrder = 21 })
	Theme.button(box, Text.t("Bestiário"), UDim2.fromOffset(300, 48), function()
		app.open("BestiaryScreen")
	end, { LayoutOrder = 22 })
	Theme.button(box, Text.t("Loja"), UDim2.fromOffset(300, 48), function()
		app.open("ShopScreen")
	end, { LayoutOrder = 23 })

	local host = isHost()
	local quit = Theme.button(box, Text.t("Sair para o menu"), UDim2.fromOffset(300, 48), function()
		if not host then
			return
		end
		app.open("ConfirmScreen", {
			title = Text.t("Sair para o menu"),
			body = if solo
				then Text.t("A noite termina aqui: esta partida não dá óleo nem entra no ranking.")
				else Text.t("A noite termina para todos os faroleiros: esta partida não dá óleo nem entra no ranking."),
			options = {
				{ Text.t("Sair para o menu"), function()
					app.ctx.send("quit")
				end },
				{ Text.t("Continuar"), nil },
			},
		})
	end, { LayoutOrder = 24, TextColor3 = Theme.DANGER })
	if not host then
		Theme.setDisabled(quit, true)
		Theme.label(box, Text.t("Só o anfitrião pode encerrar a noite para todos."), 13, Theme.TEXT_DIM, Theme.BODY, { LayoutOrder = 25 })
	end

	return {
		frame = frame,
		focus = resume,
		closable = true,
		update = function()
			local paused = app.state:GetAttribute("Paused") == true
			pause.Text = if paused then Text.t("Retomar a noite") else Text.t("Pausar")
			note.Text = if not paused then ""
				elseif solo then Text.t("A noite está pausada.")
				else Text.t("A noite está pausada para todos os faroleiros.")
		end,
	}
end
