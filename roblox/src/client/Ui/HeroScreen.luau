-- Escolha do faroleiro: cada jogador escolhe o próprio. Faroleiros
-- bloqueados se compram com o óleo de quem escolhe.

local Players = game:GetService("Players")

local Theme = require(script.Parent:WaitForChild("Theme"))
local Data = require(script.Parent:WaitForChild("Data"))
local ChoiceGrid = require(script.Parent:WaitForChild("ChoiceGrid"))
local Text = Data.Text

local SYMBOLS = { keeper = "🕯️", monk = "📿", pirate = "🏴‍☠️", astronomer = "🔭", fisher = "🎣" }

return function(app, params)
	local frame, box = Theme.screen(1000, 560, Text.t("Escolha o faroleiro"))
	local progress = Data.progress()
	local oil = progress.oil or 0
	local items = {}
	for _, id in Data.heroOrder() do
		local h = Data.hero(id)
		local entry = Data.unlockEntry(id)
		local locked = not Data.isUnlocked(progress, id)
		table.insert(items, {
			id = id, title = Text.t(h.name), desc = Text.t(h.desc or ""), symbol = SYMBOLS[id] or "🕯️",
			color = Theme.GOLD, locked = locked, cost = entry and entry.cost,
			long = if locked and entry then ChoiceGrid.lockText(id, entry.cost or 0, oil) else Text.t(h.desc or ""),
		})
	end
	local daily = app.state:GetAttribute("Mode") == "daily"
	local grid
	grid = ChoiceGrid.build(box, items, {
		width = 180, height = 300, selected = Players.LocalPlayer:GetAttribute("Hero") or "keeper",
		onChoose = function(item)
			if daily then
				return -- no desafio diário o faroleiro é o do dia
			end
			if item.locked then
				local cost = item.cost or 0
				if oil < cost then
					app.toast(Text.format("Óleo insuficiente: você tem %s.", { Data.number(oil) }), Theme.DANGER)
					return
				end
				app.open("ConfirmScreen", {
					title = item.title, body = item.long,
					options = {
						{ Text.format("Comprar: %s de óleo", { Data.number(cost) }), function()
							app.ctx.send("buy", item.id)
						end },
						{ Text.t("Voltar"), nil },
					},
				})
				return
			end
			app.ctx.send("hero", item.id)
			grid.select(item.id)
			if params and params.flow then
				app.open("DifficultyScreen", { flow = true })
			end
		end,
	}, 10)
	Theme.label(box, Text.t("Cada faroleiro muda o jeito de usar a luz."), 15, Theme.TEXT_DIM, Theme.BODY, { LayoutOrder = 15 })
	Theme.backButton(box, app, 20)
	return {
		frame = frame,
		focus = grid.focus,
		update = function()
			if Data.progress().oil ~= oil then
				app.refresh()
			end
		end,
	}
end
