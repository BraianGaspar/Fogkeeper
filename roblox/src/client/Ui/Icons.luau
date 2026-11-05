-- Ícones de habilidades, melhorias, evoluções e dificuldades. No Godot eles
-- eram desenhados em código; aqui são um medalhão com um símbolo (emoji),
-- que o Roblox desenha sem precisar de imagens enviadas.

local Theme = require(script.Parent:WaitForChild("Theme"))

local Icons = {}

Icons.SYMBOLS = {
	-- Habilidades
	flash = "☀️", overcharge = "⚡", bell = "🔔", mirror = "🪞", tide = "🌊", beacon = "✴️",
	-- Melhorias
	wide_lens = "🔆", long_lens = "🔭", intense_flame = "🔥", gears = "⚙️", twin_lens = "✳️", pulse = "💫",
	sweeper = "🔄", walls = "🧱", repairs = "🛠️", magnet = "🧲", combustion = "💥", vital_embers = "💗",
	fresh_oil = "🛢️",
	-- Evoluções
	fresnel = "💎", crown = "👑", ember_tide = "🌋", bastion = "🏰", fan = "🌟",
	-- Oficina
	granite = "🪨", polish = "✨", fine_gears = "⚙️", long_wick = "🕯️", copper = "🧲", reroll = "🔁",
	banish = "🚫", fourth_card = "🃏", head_start = "🎁", fisher = "🎣",
	-- Diversos
	oil = "🛢️", relic = "🏺", boss = "💀", lock = "🔒", crown_host = "👑", ready = "✅", tide_level = "🌊",
}

-- Medalhão redondo com o símbolo; `color` tinge a moldura (dourado por padrão).
function Icons.make(parent: Instance?, id: string, size: number, color: Color3?): Frame
	local f = Theme.make("Frame", nil, {
		Size = UDim2.fromOffset(size, size), BackgroundColor3 = Theme.INK, BorderSizePixel = 0, Name = "Icon",
	})
	Theme.corner(f, size)
	Theme.stroke(f, color or Theme.GOLD, math.max(1.5, size / 24))
	Theme.make("UIGradient", f, {
		Color = ColorSequence.new((color or Theme.GOLD):Lerp(Theme.INK, 0.65), Theme.INK), Rotation = 90,
	})
	Theme.make("TextLabel", f, {
		Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = Icons.SYMBOLS[id] or "✦",
		TextScaled = true, Font = Theme.BOLD, TextColor3 = color or Theme.GOLD, Name = "Symbol",
	})
	Theme.make("UIPadding", f, {
		PaddingTop = UDim.new(0.18, 0), PaddingBottom = UDim.new(0.18, 0), PaddingLeft = UDim.new(0.18, 0), PaddingRight = UDim.new(0.18, 0),
	})
	f.Parent = parent
	return f
end

-- Chamas da dificuldade: uma por nível (Fácil 1 ... Impossível 5).
function Icons.flames(parent: Instance?, level: number, size: number): TextLabel
	return Theme.label(parent, string.rep("🔥", level), size, Theme.GOLD, Theme.BOLD, { Size = UDim2.new(1, 0, 0, size + 6) })
end

return Icons
