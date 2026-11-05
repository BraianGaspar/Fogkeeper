-- Escolha do farol (só aparência; o anfitrião escolhe o do time).

local Theme = require(script.Parent:WaitForChild("Theme"))
local Data = require(script.Parent:WaitForChild("Data"))
local ChoiceGrid = require(script.Parent:WaitForChild("ChoiceGrid"))
local Catalog = require(game:GetService("ReplicatedStorage"):WaitForChild("Fogkeeper"):WaitForChild("Monetization"))
local Text = Data.Text

local function color(v: any, fallback: Color3): Color3
	return if typeof(v) == "Color3" then v else fallback
end

return function(app, params)
	local frame, box = Theme.screen(1000, 560, Text.t("Escolha o seu farol"))
	local progress = Data.progress()
	local oil = progress.oil or 0
	local items = {}
	local passesShown = game:GetService("Players").LocalPlayer:GetAttribute("Passes") or ""
	for _, id in Data.keeperOrder() do
		local k = Data.keeper(id)
		local entry = Data.unlockEntry(id)
		local locked = not Data.isUnlocked(progress, id)
		-- Faróis do Game Pass "Faróis lendários": liberados por posse, não por óleo.
		local pass = Catalog.keeperPass(id)
		local passes = string.split(game:GetService("Players").LocalPlayer:GetAttribute("Passes") or "", ",")
		if pass then
			locked = table.find(passes, pass) == nil
		end
		table.insert(items, {
			id = id, title = Text.t(k.name), desc = Text.t(k.desc or ""), symbol = "🗼",
			color = color(k.stripe or k.lamp, Theme.GOLD), locked = locked, cost = entry and entry.cost,
			pass = pass,
			long = if locked and pass then Text.t("Liberado pelo Game Pass Faróis lendários (Loja).")
				elseif locked and entry then ChoiceGrid.lockText(id, entry.cost or 0, oil) else Text.t(k.desc or ""),
		})
	end
	local grid
	grid = ChoiceGrid.build(box, items, {
		width = 150, height = 300, selected = app.state:GetAttribute("Keeper"),
		onChoose = function(item)
			if item.locked then
				if item.pass then
					app.open("ShopScreen")
					return
				end
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
			app.ctx.send("keeper", item.id)
			grid.select(item.id)
			if params and params.flow then
				app.open("HeroScreen", { flow = true })
			end
		end,
	}, 10)
	Theme.label(box, Text.t("Só a aparência muda: a força de todos é a mesma, para o ranking ser justo."), 15, Theme.TEXT_DIM, Theme.BODY, {
		LayoutOrder = 15,
	})
	Theme.backButton(box, app, 20)
	return {
		frame = frame,
		focus = grid.focus,
		update = function()
			if Data.progress().oil ~= oil or (game:GetService("Players").LocalPlayer:GetAttribute("Passes") or "") ~= passesShown then
				app.refresh()
			end
		end,
	}
end
