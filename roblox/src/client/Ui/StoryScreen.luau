-- História do mapa antes da partida (fase "story"): "Como você chegou
-- aqui". Qualquer jogador pode pular; senão termina sozinha em StoryEnd.

local Theme = require(script.Parent:WaitForChild("Theme"))
local Data = require(script.Parent:WaitForChild("Data"))
local Text = Data.Text

return function(app, _params)
	local frame = Theme.make("Frame", nil, {
		Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.25, BorderSizePixel = 0,
		Active = true,
	})
	local box = Theme.make("Frame", frame, {
		Size = UDim2.fromOffset(880, 460), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
	})
	Theme.list(box, 12)
	local map = Data.map(app.state:GetAttribute("Map"))
	local mode = app.state:GetAttribute("Mode")
	Theme.label(box, Text.t(if mode == "boss_rush" then "Modo Chefões" else map.name), 48, Theme.GOLD, Theme.HEAD, { LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 56) })
	Theme.divider(box, 460, 2)
	Theme.label(box, Text.t("Como você chegou aqui"), 20, Theme.GOLD, Theme.HEAD, { LayoutOrder = 3 })
	local full = Text.t(map.story or "")
	local story = Theme.label(box, full, 20, Theme.TEXT, Theme.BODY, { LayoutOrder = 4, Size = UDim2.new(1, 0, 0, 200) })
	story.MaxVisibleGraphemes = 0
	local total = utf8.len(full) or #full
	local countdown = Theme.label(box, "", 14, Theme.TEXT_DIM, Theme.BODY, { LayoutOrder = 5 })
	local skip = Theme.button(box, Text.t("Pular história"), UDim2.fromOffset(280, 48), function()
		app.ctx.send("skip_story")
	end, { LayoutOrder = 6 })
	local shown = 0
	return {
		frame = frame,
		focus = skip,
		back = function()
			app.ctx.send("skip_story")
			return false
		end,
		update = function(dt: number)
			-- O texto aparece aos poucos, como uma narração.
			shown = math.min(total, shown + dt * 60)
			story.MaxVisibleGraphemes = if shown >= total then -1 else math.floor(shown)
			local left = (app.state:GetAttribute("StoryEnd") or 0) - workspace:GetServerTimeNow()
			countdown.Text = if left > 0 then string.format("%d s", math.ceil(left)) else ""
		end,
	}
end
