-- Identidade visual da interface, a mesma do UiTheme do Godot: tinta escura,
-- dourado, painéis com moldura e botões que acendem. Tudo é desenhado numa
-- tela de referência de 1280x720 (o App escala com UIScale).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Text = require(ReplicatedStorage:WaitForChild("Fogkeeper"):WaitForChild("Text"))

local Theme = {}

Theme.GOLD = Color3.new(1.0, 0.8, 0.42)
Theme.GOLD_DARK = Color3.new(0.52, 0.36, 0.15)
Theme.INK = Color3.new(0.035, 0.04, 0.075)
Theme.PANEL = Color3.new(0.05, 0.06, 0.1)
Theme.PANEL_LIGHT = Color3.new(0.1, 0.11, 0.17)
Theme.TEXT = Color3.new(0.93, 0.9, 0.84)
Theme.TEXT_DIM = Color3.new(0.62, 0.6, 0.57)
Theme.DANGER = Color3.new(0.95, 0.38, 0.32)
Theme.GOOD = Color3.new(0.55, 0.9, 0.6)
Theme.XP = Color3.new(0.62, 0.36, 0.95)
Theme.HP = Color3.new(0.88, 0.25, 0.22)
Theme.WATER = Color3.new(0.5, 0.85, 1.0)
Theme.EVOLUTION = Color3.new(0.85, 0.7, 1.0)

Theme.HEAD = Enum.Font.Garamond
Theme.BODY = Enum.Font.GothamMedium
Theme.BOLD = Enum.Font.GothamBold

-- Multiplicador do tamanho do texto (Configurações > Acessibilidade).
Theme.textScale = 1
Theme.TEXT_SCALES = { 1.0, 1.12, 1.25 }

-- Instância com propriedades; Parent por último (mais barato e sem piscar).
function Theme.make(class: string, parent: Instance?, props: { [string]: any }?): any
	local inst = Instance.new(class)
	for k, v in props or {} do
		(inst :: any)[k] = v
	end
	inst.Parent = parent
	return inst
end

function Theme.corner(parent: Instance, r: number?)
	Theme.make("UICorner", parent, { CornerRadius = UDim.new(0, r or 10) })
end

function Theme.stroke(parent: Instance, color: Color3?, thickness: number?, transparency: number?)
	return Theme.make("UIStroke", parent, {
		Color = color or Theme.GOLD_DARK, Thickness = thickness or 1.5, Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end

function Theme.padding(parent: Instance, all: number, top: number?)
	Theme.make("UIPadding", parent, {
		PaddingTop = UDim.new(0, top or all), PaddingBottom = UDim.new(0, all),
		PaddingLeft = UDim.new(0, all), PaddingRight = UDim.new(0, all),
	})
end

function Theme.list(parent: Instance, padding: number?, horizontal: boolean?, align: Enum.HorizontalAlignment?)
	return Theme.make("UIListLayout", parent, {
		Padding = UDim.new(0, padding or 8), SortOrder = Enum.SortOrder.LayoutOrder,
		FillDirection = if horizontal then Enum.FillDirection.Horizontal else Enum.FillDirection.Vertical,
		HorizontalAlignment = align or Enum.HorizontalAlignment.Center,
		VerticalAlignment = if horizontal then Enum.VerticalAlignment.Center else Enum.VerticalAlignment.Top,
	})
end

function Theme.grid(parent: Instance, cell: Vector2, padding: number?)
	return Theme.make("UIGridLayout", parent, {
		CellSize = UDim2.fromOffset(cell.X, cell.Y), CellPadding = UDim2.fromOffset(padding or 8, padding or 8),
		SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Center,
	})
end

-- Painel ornamentado: fundo escuro com leve degradê e moldura dourada.
-- (Sem filhos decorativos: os painéis recebem UIListLayout direto.)
function Theme.panel(parent: Instance?, props: { [string]: any }?): Frame
	local f = Theme.make("Frame", nil, {
		BackgroundColor3 = Theme.PANEL, BackgroundTransparency = 0.04, BorderSizePixel = 0,
	})
	for k, v in props or {} do
		(f :: any)[k] = v
	end
	Theme.corner(f, 12)
	Theme.stroke(f, Theme.GOLD_DARK, 2)
	Theme.make("UIGradient", f, {
		Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(0.72, 0.72, 0.8)), Rotation = 90,
	})
	f.Parent = parent
	return f
end

function Theme.label(parent: Instance?, text: string, size: number, color: Color3?, font: Enum.Font?, props: { [string]: any }?): TextLabel
	local s = math.floor(size * Theme.textScale + 0.5)
	local l = Theme.make("TextLabel", nil, {
		BackgroundTransparency = 1, Text = text, TextSize = s, TextColor3 = color or Theme.TEXT, Font = font or Theme.BODY,
		Size = UDim2.new(1, 0, 0, s + 8), TextWrapped = true, TextStrokeTransparency = 0.55,
		TextStrokeColor3 = Color3.new(0, 0, 0),
	})
	for k, v in props or {} do
		(l :: any)[k] = v
	end
	l.Parent = parent
	return l
end

-- Título de tela com o divisor dourado embaixo (ocupa as ordens `order` e
-- `order + 1`; use ordens de 10 em 10 no resto da tela).
function Theme.title(parent: Instance, text: string, size: number?, order: number?): TextLabel
	local l = Theme.label(parent, text, size or 36, Theme.GOLD, Theme.HEAD, { LayoutOrder = order or 0 })
	Theme.divider(parent, 420, (order or 0) + 1)
	return l
end

function Theme.divider(parent: Instance, width: number, order: number?): Frame
	local holder = Theme.make("Frame", parent, {
		Size = UDim2.new(1, 0, 0, 8), BackgroundTransparency = 1, LayoutOrder = order or 0,
	})
	local line = Theme.make("Frame", holder, {
		Size = UDim2.fromOffset(width, 2), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		BackgroundColor3 = Theme.GOLD, BorderSizePixel = 0,
	})
	Theme.make("UIGradient", line, {
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.15), NumberSequenceKeypoint.new(1, 1),
		}),
	})
	Theme.make("Frame", holder, {
		Size = UDim2.fromOffset(8, 8), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		BackgroundColor3 = Theme.GOLD, BorderSizePixel = 0, Rotation = 45,
	})
	return holder
end

local function hoverable(b: GuiButton, normal: Color3, hover: Color3)
	b.MouseEnter:Connect(function()
		if b:GetAttribute("Selected") ~= true then
			b.BackgroundColor3 = hover
		end
	end)
	b.MouseLeave:Connect(function()
		if b:GetAttribute("Selected") ~= true then
			b.BackgroundColor3 = normal
		end
	end)
	b.SelectionGained:Connect(function()
		if b:GetAttribute("Selected") ~= true then
			b.BackgroundColor3 = hover
		end
	end)
	b.SelectionLost:Connect(function()
		if b:GetAttribute("Selected") ~= true then
			b.BackgroundColor3 = normal
		end
	end)
end

-- Botão padrão. `onClick` roda com Activated (mouse, toque e botão A do controle).
function Theme.button(parent: Instance?, text: string, size: UDim2, onClick: (() -> ())?, props: { [string]: any }?): TextButton
	local b = Theme.make("TextButton", nil, {
		Text = text, Size = size, Font = Theme.HEAD, TextSize = math.floor(22 * Theme.textScale + 0.5),
		TextColor3 = Theme.TEXT, AutoButtonColor = false, BackgroundColor3 = Theme.PANEL_LIGHT, BorderSizePixel = 0,
		TextWrapped = true, Selectable = true,
	})
	Theme.corner(b, 10)
	Theme.stroke(b, Theme.GOLD_DARK, 1.5)
	for k, v in props or {} do
		(b :: any)[k] = v
	end
	hoverable(b, Theme.PANEL_LIGHT, Color3.new(0.2, 0.16, 0.1))
	if onClick then
		b.Activated:Connect(function()
			if b:GetAttribute("Disabled") ~= true then
				onClick()
			end
		end)
	end
	b.Parent = parent
	return b
end

function Theme.smallButton(parent: Instance?, text: string, size: UDim2, onClick: (() -> ())?, props: { [string]: any }?): TextButton
	local b = Theme.button(parent, text, size, onClick, props)
	b.Font = Theme.BOLD
	b.TextSize = math.floor(16 * Theme.textScale + 0.5)
	return b
end

-- Marca um botão como escolhido (borda dourada e fundo aceso) ou não.
function Theme.setSelected(b: GuiButton, on: boolean)
	b:SetAttribute("Selected", on)
	b.BackgroundColor3 = if on then Color3.new(0.26, 0.19, 0.08) else Theme.PANEL_LIGHT
	local s = b:FindFirstChildOfClass("UIStroke")
	if s then
		s.Color = if on then Theme.GOLD else Theme.GOLD_DARK
		s.Thickness = if on then 2.5 else 1.5
	end
end

function Theme.setDisabled(b: GuiButton, off: boolean)
	b:SetAttribute("Disabled", off)
	if b:IsA("TextButton") then
		(b :: TextButton).TextTransparency = if off then 0.5 else 0
	end
end

-- Barra com fundo, moldura e preenchimento; retorna (fundo, preenchimento).
function Theme.bar(parent: Instance, size: UDim2, position: UDim2?, color: Color3): (Frame, Frame)
	local back = Theme.make("Frame", parent, {
		Size = size, Position = position or UDim2.new(), BackgroundColor3 = Color3.new(0.06, 0.06, 0.09), BorderSizePixel = 0,
	})
	Theme.corner(back, 6)
	Theme.stroke(back, Theme.GOLD_DARK, 1.5)
	local fill = Theme.make("Frame", back, {
		Size = UDim2.fromScale(1, 1), BackgroundColor3 = color, BorderSizePixel = 0, Name = "Fill",
	})
	Theme.corner(fill, 6)
	Theme.make("UIGradient", fill, {
		Color = ColorSequence.new(color:Lerp(Color3.new(1, 1, 1), 0.25), color),
		Rotation = 90,
	})
	return back, fill
end

function Theme.scroll(parent: Instance, size: UDim2, props: { [string]: any }?): ScrollingFrame
	local s = Theme.make("ScrollingFrame", parent, {
		Size = size, BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 6,
		ScrollBarImageColor3 = Theme.GOLD_DARK, AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(), ScrollingDirection = Enum.ScrollingDirection.Y, Selectable = false,
	})
	for k, v in props or {} do
		(s :: any)[k] = v
	end
	return s
end

-- Seletor "‹ valor ›" para listas de opções; chama onChange(índice).
function Theme.selector(parent: Instance, options: { string }, index: number, onChange: (number) -> (), width: number?): Frame
	local row = Theme.make("Frame", parent, { Size = UDim2.fromOffset(width or 300, 38), BackgroundTransparency = 1 })
	Theme.list(row, 6, true)
	local current = index
	local value: TextLabel
	local function set(i: number)
		current = ((i - 1) % #options) + 1
		value.Text = options[current]
		onChange(current)
	end
	Theme.smallButton(row, "‹", UDim2.fromOffset(38, 38), function()
		set(current - 1)
	end, { LayoutOrder = 1 })
	value = Theme.label(row, options[current] or "", 17, Theme.GOLD, Theme.BOLD, {
		Size = UDim2.fromOffset((width or 300) - 92, 38), LayoutOrder = 2,
	})
	Theme.smallButton(row, "›", UDim2.fromOffset(38, 38), function()
		set(current + 1)
	end, { LayoutOrder = 3 })
	return row
end

-- Botão liga/desliga.
function Theme.toggle(parent: Instance, on: boolean, onChange: (boolean) -> ()): TextButton
	local state = on
	local b: TextButton
	b = Theme.smallButton(parent, "", UDim2.fromOffset(120, 36), function()
		state = not state
		b.Text = if state then "✓" else "—"
		Theme.setSelected(b, state)
		onChange(state)
	end)
	b.Text = if state then "✓" else "—"
	Theme.setSelected(b, state)
	return b
end

-- Controle de 0 a 100 em passos de 10, com - e +.
function Theme.slider(parent: Instance, value: number, onChange: (number) -> ()): Frame
	local row = Theme.make("Frame", parent, { Size = UDim2.fromOffset(300, 36), BackgroundTransparency = 1 })
	Theme.list(row, 6, true)
	local v = value
	local fill: Frame
	local text: TextLabel
	local function set(n: number)
		v = math.clamp(n, 0, 100)
		fill.Size = UDim2.fromScale(v / 100, 1)
		text.Text = string.format("%d%%", v)
		onChange(v)
	end
	Theme.smallButton(row, "−", UDim2.fromOffset(36, 36), function()
		set(v - 10)
	end, { LayoutOrder = 1 })
	local back
	back, fill = Theme.bar(row, UDim2.fromOffset(150, 14), nil, Theme.GOLD)
	back.LayoutOrder = 2
	Theme.smallButton(row, "+", UDim2.fromOffset(36, 36), function()
		set(v + 10)
	end, { LayoutOrder = 3 })
	text = Theme.label(row, "", 15, Theme.TEXT, Theme.BOLD, { Size = UDim2.fromOffset(52, 36), LayoutOrder = 4 })
	fill.Size = UDim2.fromScale(v / 100, 1)
	text.Text = string.format("%d%%", v)
	return row
end

-- Moldura padrão de tela de menu: fundo escurecido de tela inteira e um
-- painel central com lista vertical. Retorna (frame da tela, painel).
function Theme.screen(width: number, height: number, titleText: string?): (Frame, Frame)
	local frame = Theme.make("Frame", nil, {
		Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.45, BorderSizePixel = 0,
		Active = true,
	})
	local box = Theme.panel(frame, {
		Size = UDim2.fromOffset(width, height), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5),
	})
	Theme.padding(box, 18)
	Theme.list(box, 8)
	if titleText then
		Theme.title(box, titleText, 34, 0)
	end
	return frame, box
end

-- Botão "Voltar" no fim de uma tela.
function Theme.backButton(parent: Instance, app: any, order: number?, label: string?): TextButton
	return Theme.button(parent, label or Text.t("Voltar"), UDim2.fromOffset(240, 46), function()
		app.back()
	end, { LayoutOrder = order or 999 })
end

-- Linha "rótulo .... valor" usada em estatísticas e pontuação.
function Theme.statRow(parent: Instance, name: string, value: string, valueColor: Color3?, order: number?): Frame
	local row = Theme.make("Frame", parent, { Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, LayoutOrder = order or 0 })
	Theme.label(row, name, 16, Theme.TEXT_DIM, Theme.BODY, {
		Size = UDim2.fromScale(0.65, 1), TextXAlignment = Enum.TextXAlignment.Left,
	})
	Theme.label(row, value, 16, valueColor or Theme.TEXT, Theme.BOLD, {
		Size = UDim2.fromScale(0.35, 1), Position = UDim2.fromScale(0.65, 0), TextXAlignment = Enum.TextXAlignment.Right,
	})
	return row
end

return Theme
