-- Fileira de cartas de escolha (mapas, faróis, faroleiros), como as
-- ChoiceCard do Godot: número, prévia, nome, subtítulo e descrição. Cartas
-- bloqueadas mostram cadeado e o custo em óleo. A carta destacada mostra
-- a descrição longa num quadro embaixo.

local Theme = require(script.Parent:WaitForChild("Theme"))
local Data = require(script.Parent:WaitForChild("Data"))
local Text = Data.Text

local ChoiceGrid = {}

-- items: { {id, title, subtitle?, desc?, long?, symbol?, color?, locked?, cost?, goal?} }
-- opts: { width = largura da carta, height, selected = id, onChoose = fn(item), longTitle? }
function ChoiceGrid.build(parent: Instance, items: { any }, opts: { [string]: any }, order: number?)
	local holder = Theme.make("Frame", parent, {
		Size = UDim2.new(1, 0, 0, (opts.height or 300) + (if opts.longTitle then 120 else 0)), BackgroundTransparency = 1,
		LayoutOrder = order or 10,
	})
	Theme.list(holder, 10)
	local row = Theme.make("Frame", holder, { Size = UDim2.new(1, 0, 0, opts.height or 300), BackgroundTransparency = 1, LayoutOrder = 1 })
	Theme.list(row, 8, true)
	local longBox: TextLabel? = nil
	local longHead: TextLabel? = nil
	if opts.longTitle then
		local box = Theme.make("Frame", holder, {
			Size = UDim2.new(1, -20, 0, 110), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.6,
			BorderSizePixel = 0, LayoutOrder = 2,
		})
		Theme.corner(box, 8)
		Theme.stroke(box, Theme.GOLD_DARK, 1)
		Theme.padding(box, 10)
		Theme.list(box, 2, false, Enum.HorizontalAlignment.Left)
		longHead = Theme.label(box, opts.longTitle, 17, Theme.GOLD, Theme.HEAD, { LayoutOrder = 1, TextXAlignment = Enum.TextXAlignment.Left })
		longBox = Theme.label(box, "", 14, Theme.TEXT, Theme.BODY, {
			LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 70), TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
		})
	end
	local buttons = {}
	local first: GuiObject? = nil
	local selectedButton: GuiObject? = nil
	local function showLong(item)
		if longBox then
			(longBox :: TextLabel).Text = item.long or ""
		end
	end
	for i, item in items do
		local b = Theme.button(row, "", UDim2.fromOffset(opts.width or 170, opts.height or 300), function()
			showLong(item)
			opts.onChoose(item)
		end, { LayoutOrder = i })
		Theme.padding(b, 8)
		Theme.list(b, 4)
		local accent = item.color or Theme.GOLD
		Theme.label(b, tostring(i), 14, accent, Theme.BOLD, { LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 16), TextXAlignment = Enum.TextXAlignment.Left })
		local preview = Theme.make("Frame", b, {
			Size = UDim2.new(1, 0, 0, 92), BackgroundColor3 = accent:Lerp(Theme.INK, 0.72), BorderSizePixel = 0, LayoutOrder = 2,
		})
		Theme.corner(preview, 8)
		Theme.stroke(preview, accent, 1.5, 0.3)
		Theme.make("UIGradient", preview, { Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(0.5, 0.5, 0.6)), Rotation = 90 })
		Theme.make("TextLabel", preview, {
			Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = if item.locked then "🔒" else (item.symbol or "✦"),
			TextScaled = true, Font = Theme.BOLD, TextColor3 = accent,
		})
		Theme.make("UIPadding", preview, { PaddingTop = UDim.new(0.2, 0), PaddingBottom = UDim.new(0.2, 0) })
		if item.locked and item.cost then
			Theme.label(preview, Text.format("%s de óleo", { Data.number(item.cost) }), 14, Theme.GOLD, Theme.BOLD, {
				Size = UDim2.new(1, 0, 0, 18), Position = UDim2.new(0, 0, 1, 2), ZIndex = 3,
			})
		end
		Theme.label(b, item.title, 18, Theme.TEXT, Theme.HEAD, { LayoutOrder = 3, Size = UDim2.new(1, 0, 0, 46) })
		if item.subtitle and item.subtitle ~= "" then
			Theme.label(b, item.subtitle, 13, accent, Theme.BOLD, { LayoutOrder = 4, Size = UDim2.new(1, 0, 0, 18) })
		end
		Theme.label(b, item.desc or "", 13, Theme.TEXT_DIM, Theme.BODY, {
			LayoutOrder = 5, Size = UDim2.new(1, 0, 0, 90), TextYAlignment = Enum.TextYAlignment.Top,
		})
		b.SelectionGained:Connect(function()
			showLong(item)
		end)
		b.MouseEnter:Connect(function()
			showLong(item)
		end)
		if item.id == opts.selected then
			Theme.setSelected(b, true)
			selectedButton = b
			showLong(item)
		end
		if not first then
			first = b
		end
		buttons[item.id] = b
	end
	return {
		frame = holder,
		buttons = buttons,
		focus = selectedButton or first,
		head = longHead,
		select = function(id: string)
			for bid, b in buttons do
				Theme.setSelected(b, bid == id)
			end
		end,
	}
end

-- Texto de bloqueio com meta e custo (como no Godot).
function ChoiceGrid.lockText(id: string, cost: number, oil: number): string
	local goal = Data.goalText(id)
	if oil < cost then
		local s = Text.format("Óleo insuficiente: você tem %s.", { Data.number(oil) })
		return if goal ~= "" then Text.format("Ou libere de graça: %s.", { goal }) .. "\n" .. s else s
	end
	local s = Text.format("Escolha para comprar por %s de óleo (você tem %s).", { Data.number(cost), Data.number(oil) })
	return if goal ~= "" then s .. "\n" .. Text.format("Ou libere de graça: %s.", { goal }) else s
end

return ChoiceGrid
