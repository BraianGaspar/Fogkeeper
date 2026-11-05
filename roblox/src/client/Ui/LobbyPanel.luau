-- Painel do saguão: quem está no servidor (anfitrião, faroleiro, pronto) e
-- como está a próxima partida (modo, mapa, farol, dificuldade, maré).
-- Atualiza sozinho; usado na tela inicial e na tela de espera.

local Players = game:GetService("Players")

local Theme = require(script.Parent:WaitForChild("Theme"))
local Data = require(script.Parent:WaitForChild("Data"))
local Text = Data.Text

local LobbyPanel = {}

function LobbyPanel.build(app, parent: Instance, props: { [string]: any }?)
	local panel = Theme.panel(parent, props)
	Theme.padding(panel, 14)
	Theme.list(panel, 4, false, Enum.HorizontalAlignment.Left)
	local setup = Theme.label(panel, "", 15, Theme.TEXT, Theme.BODY, {
		LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 64), TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
	})
	local playersTitle = Theme.label(panel, "", 17, Theme.GOLD, Theme.HEAD, { LayoutOrder = 2, TextXAlignment = Enum.TextXAlignment.Left })
	local list = Theme.label(panel, "", 15, Theme.TEXT, Theme.BODY, {
		LayoutOrder = 3, Size = UDim2.new(1, 0, 0, 96), TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
	})
	local self = { frame = panel }

	function self.update()
		local state = app.state
		local mode = state:GetAttribute("Mode") or "normal"
		local lines = {}
		table.insert(lines, Text.t("Modo") .. ": " .. Text.t(Data.MODE_NAMES[mode] or mode))
		if mode ~= "boss_rush" then
			table.insert(lines, Text.t("Mapa") .. ": " .. Text.t(Data.map(state:GetAttribute("Map")).name)
				.. "   •   " .. Text.t("Farol") .. ": " .. Text.t(Data.keeper(state:GetAttribute("Keeper")).name))
		end
		local tide = state:GetAttribute("Tide") or 0
		local diff = Text.t("Dificuldade") .. ": " .. Data.difficultyName(state:GetAttribute("Difficulty"))
		if tide > 0 then
			diff ..= "   •   " .. Text.format("Maré %d", { tide })
		end
		table.insert(lines, diff)
		setup.Text = table.concat(lines, "\n")

		local players = Players:GetPlayers()
		table.sort(players, function(a, b)
			return (a:GetAttribute("Slot") or 9) < (b:GetAttribute("Slot") or 9)
		end)
		playersTitle.Text = Text.t("Faroleiros") .. string.format(" (%d/4)", #players)
		local rows = {}
		local host = Data.host()
		for _, p in players do
			local slot = p:GetAttribute("Slot")
			local mark = if p == host then "👑 " elseif p:GetAttribute("Ready") then "✅ " else "• "
			local hero = Text.t(Data.hero(p:GetAttribute("Hero")).name)
			local name = if p:GetAttribute("Vip") == true then p.DisplayName .. " [VIP]" else p.DisplayName -- selo do passe VIP
			table.insert(rows, if slot then string.format("%s%s — %s", mark, name, hero) else "👀 " .. p.DisplayName)
		end
		list.Text = table.concat(rows, "\n")
	end

	self.update()
	return self
end

return LobbyPanel
