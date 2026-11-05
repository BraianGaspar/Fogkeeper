-- Escolha do mapa (só o anfitrião). Mapas bloqueados mostram o custo em
-- óleo e a meta que libera de graça; escolher um bloqueado pede confirmação
-- da compra. Embaixo, a história de como o faroleiro chegou ali.

local Theme = require(script.Parent:WaitForChild("Theme"))
local Data = require(script.Parent:WaitForChild("Data"))
local ChoiceGrid = require(script.Parent:WaitForChild("ChoiceGrid"))
local Text = Data.Text

local LOOK = {
	bay = { "🌊", Color3.new(0.5, 0.75, 1.0) }, fjord = { "❄️", Color3.new(0.6, 0.9, 1.0) },
	amazon = { "🌿", Color3.new(0.5, 0.95, 0.5) }, japan = { "⛩️", Color3.new(1.0, 0.55, 0.65) },
	egypt = { "🏜️", Color3.new(1.0, 0.82, 0.4) }, greece = { "🏛️", Color3.new(0.75, 0.85, 1.0) },
	celtic = { "☘️", Color3.new(0.5, 1.0, 0.7) },
}

return function(app, params)
	local frame, box = Theme.screen(1240, 640, Text.t("Escolha o mapa"))
	local progress = Data.progress()
	local oil = progress.oil or 0
	local items = {}
	for _, id in Data.mapOrder() do
		local m = Data.map(id)
		local look = LOOK[id] or { "✦", Theme.GOLD }
		local accent = (Data.Maps.ACCENT or {})[id]
		if typeof(accent) == "Color3" then
			look = { look[1], accent }
		end
		local entry = Data.unlockEntry(id)
		local locked = not Data.isUnlocked(progress, id)
		local bosses = {}
		for _, b in m.bosses or {} do
			table.insert(bosses, Data.creatureName(b))
		end
		table.insert(items, {
			id = id, title = Text.t(m.name), subtitle = table.concat(bosses, " · "), desc = Text.t(m.tagline or ""),
			long = if locked and entry then ChoiceGrid.lockText(id, entry.cost or 0, oil) else Text.t(m.story or ""),
			symbol = look[1], color = look[2], locked = locked, cost = entry and entry.cost,
		})
	end
	local grid
	grid = ChoiceGrid.build(box, items, {
		width = 164, height = 330, -- 7 cartas + espaços cabem nos 1204 px úteis do painel selected = app.state:GetAttribute("Map"), longTitle = Text.t("Como você chegou aqui"),
		onChoose = function(item)
			if item.locked then
				local entry = Data.unlockEntry(item.id)
				local cost = entry and entry.cost or 0
				if oil < cost then
					app.toast(Text.format("Óleo insuficiente: você tem %s.", { Data.number(oil) }), Theme.DANGER)
					return
				end
				app.open("ConfirmScreen", {
					title = item.title,
					body = Text.format("Escolha para comprar por %s de óleo (você tem %s).", { Data.number(cost), Data.number(oil) }),
					options = {
						{ Text.format("Comprar: %s de óleo", { Data.number(cost) }), function()
							app.ctx.send("buy", item.id)
						end },
						{ Text.t("Voltar"), nil },
					},
				})
				return
			end
			app.ctx.send("map", item.id)
			grid.select(item.id)
			if params and params.flow then
				app.open("KeeperScreen", { flow = true })
			end
		end,
	}, 10)
	Theme.backButton(box, app, 20)
	return {
		frame = frame,
		focus = grid.focus,
		update = function()
			-- A compra liberou o mapa: reconstrói para tirar o cadeado.
			if Data.progress().oil ~= oil then
				app.refresh()
			end
		end,
	}
end
