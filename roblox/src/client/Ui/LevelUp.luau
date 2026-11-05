-- Cartas de melhoria. A partida é cooperativa e não pausa: as cartas ficam
-- num canto da tela até o jogador escolher (clique, toque, 1-4 ou
-- direcional). "Trocar cartas" (T / X do controle) sorteia outra mão e
-- "Banir uma carta" (B / View) tira uma carta da partida.

local Players = game:GetService("Players")

local Theme = require(script.Parent:WaitForChild("Theme"))
local Data = require(script.Parent:WaitForChild("Data"))
local Icons = require(script.Parent:WaitForChild("Icons"))
local Text = Data.Text

local LevelUp = {}

local KEYS_PAD = { "←", "↑", "→", "↓" }

function LevelUp.build(app, parent: Frame)
	local me = Players.LocalPlayer
	local self = {}
	local panel = Theme.make("Frame", parent, {
		Size = UDim2.fromOffset(330, 560), Position = UDim2.new(1, -14, 0.5, 36), AnchorPoint = Vector2.new(1, 0.5),
		BackgroundTransparency = 1, Visible = false,
	})
	Theme.list(panel, 6)
	local title = Theme.label(panel, "", 22, Theme.GOLD, Theme.HEAD, { LayoutOrder = 0 })
	local cards = {}
	for i = 1, 4 do
		local c = Theme.button(panel, "", UDim2.fromOffset(330, 96), function()
			self.pick(i)
		end, { LayoutOrder = i, Visible = false })
		local icon = Icons.make(c, "fresh_oil", 46)
		icon.Position = UDim2.fromOffset(10, 25)
		local name = Theme.label(c, "", 17, Theme.GOLD, Theme.HEAD, {
			Position = UDim2.fromOffset(64, 6), Size = UDim2.new(1, -72, 0, 22), TextXAlignment = Enum.TextXAlignment.Left,
		})
		local desc = Theme.label(c, "", 13, Theme.TEXT, Theme.BODY, {
			Position = UDim2.fromOffset(64, 30), Size = UDim2.new(1, -72, 0, 44), TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
		})
		local tag = Theme.label(c, "", 11, Theme.TEXT_DIM, Theme.BOLD, {
			Position = UDim2.new(0, 64, 1, -18), Size = UDim2.new(1, -72, 0, 14), TextXAlignment = Enum.TextXAlignment.Left,
		})
		local key = Theme.label(c, "", 13, Theme.TEXT_DIM, Theme.BOLD, {
			Position = UDim2.fromOffset(6, 4), Size = UDim2.fromOffset(20, 16), TextXAlignment = Enum.TextXAlignment.Left,
		})
		cards[i] = { button = c, icon = icon, name = name, desc = desc, tag = tag, key = key, id = "" }
	end
	local actions = Theme.make("Frame", panel, { Size = UDim2.fromOffset(330, 40), BackgroundTransparency = 1, LayoutOrder = 10 })
	Theme.list(actions, 8, true)
	local rerollButton = Theme.smallButton(actions, "", UDim2.fromOffset(161, 38), function()
		self.reroll()
	end, { LayoutOrder = 1 })
	local banishButton = Theme.smallButton(actions, "", UDim2.fromOffset(161, 38), function()
		self.toggleBanish()
	end, { LayoutOrder = 2 })
	local hint = Theme.label(panel, "", 12, Theme.TEXT_DIM, Theme.BODY, { LayoutOrder = 11, Size = UDim2.new(1, 0, 0, 30) })

	local banishing = false
	local pickedOffer = ""
	local shown = ""

	local pendingConn = me:GetAttributeChangedSignal("Pending"):Connect(function()
		pickedOffer = "" -- a escolha chegou ao servidor: libera a próxima
	end)

	-- O HUD é reconstruído ao trocar idioma ou tamanho do texto.
	function self.destroy()
		pendingConn:Disconnect()
	end

	local function offer(): { string }
		local raw = me:GetAttribute("Offer")
		return if type(raw) == "string" and raw ~= "" then string.split(raw, ",") else {}
	end

	function self.pick(i: number)
		local ids = offer()
		local id = ids[i]
		local key = table.concat(ids, ",")
		if not panel.Visible or not id or key == pickedOffer then
			return
		end
		if banishing then
			if Data.isEvolution(id) or id == "fresh_oil" then
				if app.ctx.sounds then
					app.ctx.sounds.play("denied")
				end
				return
			end
			banishing = false
			pickedOffer = key
			app.ctx.net.banish(id)
		else
			pickedOffer = key
			app.ctx.net.pick(id)
			if app.ctx.sounds then
				app.ctx.sounds.play("pick")
			end
		end
	end

	function self.reroll()
		if panel.Visible and (me:GetAttribute("Rerolls") or 0) > 0 then
			banishing = false
			app.ctx.net.reroll()
		end
	end

	function self.toggleBanish()
		if panel.Visible and (me:GetAttribute("Banishes") or 0) > 0 then
			banishing = not banishing
		end
	end

	local function refresh(ids: { string }, usingPad: boolean)
		for i, c in cards do
			local id = ids[i]
			c.button.Visible = id ~= nil
			c.id = id or ""
			if id then
				local u = Data.upgrade(id)
				local evo = Data.isEvolution(id)
				c.icon:Destroy()
				c.icon = Icons.make(c.button, id, 46, if evo then Theme.EVOLUTION else Theme.GOLD)
				c.icon.Position = UDim2.fromOffset(10, 25)
				c.name.Text = Text.t(u.name or id)
				c.name.TextColor3 = if evo then Theme.EVOLUTION else Theme.GOLD
				c.desc.Text = Text.t(u.desc or "")
				local scope = if u.scope == "own" then Text.t("seu feixe") else Text.t("para o time")
				c.tag.Text = if evo then Text.t("EVOLUÇÃO") .. "  •  " .. scope else scope
				c.key.Text = if usingPad then (KEYS_PAD[i] or "") else tostring(i)
			end
		end
	end

	function self.update(dt: number, playing: boolean)
		local ids = offer()
		local pending = me:GetAttribute("Pending") or 0
		panel.Visible = playing and pending > 0 and #ids > 0
		if not panel.Visible then
			banishing = false
			shown = ""
			return
		end
		local usingPad = app.ctx.input and app.ctx.input.usingPad
		local key = table.concat(ids, ",") .. (if usingPad then "|pad" else "|kb")
		if key ~= shown then
			shown = key
			refresh(ids, usingPad)
		end
		title.Text = if banishing then Text.t("Banir uma carta") else Text.t("Escolha uma melhoria")
		if pending > 1 then
			title.Text ..= string.format("  ×%d", pending)
		end
		title.TextColor3 = if banishing then Theme.DANGER else Theme.GOLD
		for _, c in cards do
			local s = c.button:FindFirstChildOfClass("UIStroke")
			if s and c.button:GetAttribute("Selected") ~= true then
				s.Color = if banishing then Theme.DANGER else Theme.GOLD_DARK
			end
		end
		local rerolls = me:GetAttribute("Rerolls") or 0
		local banishes = me:GetAttribute("Banishes") or 0
		rerollButton.Text = Text.format("Trocar cartas — %d", { rerolls })
		banishButton.Text = Text.format("Banir uma carta — %d", { banishes })
		Theme.setDisabled(rerollButton, rerolls <= 0)
		Theme.setDisabled(banishButton, banishes <= 0)
		Theme.setSelected(banishButton, banishing)
		local input = app.ctx.input
		if app.state:GetAttribute("Mode") == "tutorial" and input then
			hint.Text = if usingPad
				then Text.format("Direcional: cada direção escolhe uma carta   •   %s troca   •   %s bane",
					{ input.label("reroll"), input.label("banish") })
				else Text.t("1 a 4 ou clique para escolher   •   T troca   •   B bane")
		else
			hint.Text = ""
		end
	end

	return self
end

return LevelUp
