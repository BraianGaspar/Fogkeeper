-- Oficina do faroleiro: melhorias permanentes (META), desbloqueios por
-- óleo e as 3 habilidades equipadas. Tudo é de cada jogador.

local Players = game:GetService("Players")

local Theme = require(script.Parent:WaitForChild("Theme"))
local Data = require(script.Parent:WaitForChild("Data"))
local Icons = require(script.Parent:WaitForChild("Icons"))
local Text = Data.Text

local KIND_NAMES = { map = "Mapa", keeper = "Farol", hero = "Faroleiro", ability = "Habilidade", upgrade = "Carta de melhoria" }

local function row(parent: Instance, order: number, iconId: string?, title: string, desc: string, action: string?, onClick: (() -> ())?, done: boolean?)
	local r = Theme.make("Frame", parent, {
		Size = UDim2.new(1, -12, 0, 68), BackgroundColor3 = Theme.PANEL_LIGHT, BackgroundTransparency = 0.3, BorderSizePixel = 0,
		LayoutOrder = order,
	})
	Theme.corner(r, 8)
	if iconId then
		local icon = Icons.make(r, iconId, 48)
		icon.Position = UDim2.fromOffset(10, 10)
	end
	Theme.label(r, title, 17, Theme.GOLD, Theme.HEAD, {
		Position = UDim2.fromOffset(70, 6), Size = UDim2.new(1, -300, 0, 22), TextXAlignment = Enum.TextXAlignment.Left,
	})
	Theme.label(r, desc, 13, Theme.TEXT, Theme.BODY, {
		Position = UDim2.fromOffset(70, 28), Size = UDim2.new(1, -300, 0, 36), TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
	})
	local b = Theme.smallButton(r, action or "", UDim2.fromOffset(210, 44), onClick, {
		Position = UDim2.new(1, -12, 0.5, 0), AnchorPoint = Vector2.new(1, 0.5),
	})
	if done then
		Theme.setSelected(b, true)
		Theme.setDisabled(b, true)
	end
	return b
end

return function(app, _params)
	local frame, box = Theme.screen(1080, 660, Text.t("Oficina do faroleiro"))
	local progress = Data.progress()
	local oil = progress.oil or 0
	Theme.label(box, Text.format("Óleo do farol: %s", { Data.number(oil) }), 18, Theme.GOLD, Theme.BOLD, { LayoutOrder = 10 })
	Theme.label(box, Text.t("Cada partida rende óleo, até as derrotas. Gaste-o aqui em melhorias que valem para todas as noites."),
		14, Theme.TEXT_DIM, Theme.BODY, { LayoutOrder = 11 })
	local scroll = Theme.scroll(box, UDim2.new(1, 0, 0, 430), { LayoutOrder = 20 })
	Theme.list(scroll, 6)
	local first: GuiObject? = nil
	local order = 0
	local function nextOrder(): number
		order += 1
		return order
	end
	local function buy(kind: string, id: string, cost: number)
		if oil < cost then
			app.toast(Text.t("Óleo insuficiente. Jogue mais noites para juntar óleo."), Theme.DANGER)
			return
		end
		app.ctx.send(kind, id)
	end

	-- Habilidades equipadas.
	Theme.label(scroll, Text.t("Habilidades equipadas"), 20, Theme.GOLD, Theme.HEAD, { LayoutOrder = nextOrder() })
	local loadoutRow = Theme.make("Frame", scroll, { Size = UDim2.new(1, -12, 0, 52), BackgroundTransparency = 1, LayoutOrder = nextOrder() })
	Theme.list(loadoutRow, 10, true)
	local current = string.split(Players.LocalPlayer:GetAttribute("Loadout") or "", ",")
	if #current < 3 then
		current = table.clone(Data.Balance.DEFAULT_LOADOUT or { "flash", "overcharge", "bell" })
	end
	local available = {}
	for _, a in Data.abilities() do
		if Data.isUnlocked(progress, a.id) then
			table.insert(available, a.id)
		end
	end
	for slot = 1, 3 do
		local options, names = {}, {}
		for _, id in available do
			if id == current[slot] or not table.find(current, id) then
				table.insert(options, id)
				table.insert(names, Text.format("Habilidade %d", { slot }) .. ": " .. Text.t(Data.ability(id).name))
			end
		end
		local index = table.find(options, current[slot]) or 1
		Theme.selector(loadoutRow, names, index, function(i)
			app.ctx.send("loadout", slot, options[i])
		end, 330).LayoutOrder = slot
	end

	-- Melhorias permanentes.
	Theme.label(scroll, Text.t("Melhorias permanentes"), 20, Theme.GOLD, Theme.HEAD, { LayoutOrder = nextOrder() })
	for _, m in Data.meta() do
		local level = progress.meta[m.id] or 0
		local full = level >= (m.max or 1)
		local cost = (m.cost or 0) * (level + 1)
		local b = row(scroll, nextOrder(), m.id, string.format("%s  (%d/%d)", Text.t(m.name), level, m.max or 1), Text.t(m.desc or ""),
			if full then Text.t("Completo") else Text.format("Comprar: %s de óleo", { Data.number(cost) }),
			function()
				buy("meta", m.id, cost)
			end, full)
		first = first or b
	end

	-- Desbloqueios.
	Theme.label(scroll, Text.t("Desbloqueios"), 20, Theme.GOLD, Theme.HEAD, { LayoutOrder = nextOrder() })
	for _, u in Data.unlocks() do
		local done = progress.unlocked[u.id] == true
		local desc = Text.t(KIND_NAMES[u.kind] or "")
		local goal = Data.goalText(u.id)
		if not done and goal ~= "" then
			desc ..= "  •  " .. Text.format("ou de graça: %s", { goal })
		end
		local iconId = if u.kind == "ability" or u.kind == "upgrade" then u.id else "lock"
		row(scroll, nextOrder(), if done then (if u.kind == "ability" or u.kind == "upgrade" then u.id else "ready") else iconId,
			Data.unlockName(u.id), desc,
			if done then Text.t("Liberado") else Text.format("Comprar: %s de óleo", { Data.number(u.cost or 0) }),
			function()
				buy("buy", u.id, u.cost or 0)
			end, done)
	end

	Theme.backButton(box, app, 30)
	return {
		frame = frame,
		focus = first,
		update = function()
			-- Compras e trocas de habilidade chegam do servidor: reconstrói para mostrar.
			local loadout = Players.LocalPlayer:GetAttribute("Loadout") or ""
			if Data.progress().oil ~= oil or (loadout ~= "" and loadout ~= table.concat(current, ",")) then
				app.refresh()
			end
		end,
	}
end
