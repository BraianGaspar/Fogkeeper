-- Faróis selecionáveis. São só aparência (o ranking continua justo): cores
-- da torre, das listras, do telhado, da lanterna e do feixe, e a forma.
-- Porta de scripts/core/keepers.gd. World monta o farol com estes dados.

local Keepers = {}

-- golden e obsidian vêm do Game Pass "Faróis lendários" (shared/Monetization.luau).
Keepers.ORDER = { "classic", "stone", "iron", "crystal", "golden", "obsidian" }

-- shape: "striped" (faixas alternadas), "stone" (blocos e musgo), "iron"
-- (treliça com anéis de latão), "crystal" (lanterna translúcida).
Keepers.LIST = {
	classic = {
		name = "Farol Clássico", desc = "Listras vermelhas e brancas, como manda a tradição.", shape = "striped",
		base = Color3.new(0.93, 0.9, 0.85), stripe = Color3.new(0.76, 0.16, 0.15), roof = Color3.new(0.16, 0.16, 0.19),
		lamp = Color3.new(1.0, 0.88, 0.55), beam = Color3.new(1.0, 0.9, 0.62), trim = Color3.new(0.3, 0.3, 0.33),
	},
	stone = {
		name = "Torre de Pedra", desc = "Pedra antiga coberta de musgo, de antes de qualquer mapa.", shape = "stone",
		base = Color3.new(0.55, 0.53, 0.5), stripe = Color3.new(0.32, 0.45, 0.27), roof = Color3.new(0.3, 0.22, 0.16),
		lamp = Color3.new(1.0, 0.75, 0.4), beam = Color3.new(1.0, 0.8, 0.5), trim = Color3.new(0.38, 0.36, 0.33),
	},
	iron = {
		name = "Farol de Ferro", desc = "Ferro escuro e latão polido, feito para tempestades.", shape = "iron",
		base = Color3.new(0.22, 0.23, 0.26), stripe = Color3.new(0.78, 0.6, 0.3), roof = Color3.new(0.12, 0.12, 0.14),
		lamp = Color3.new(1.0, 0.68, 0.32), beam = Color3.new(1.0, 0.76, 0.45), trim = Color3.new(0.65, 0.5, 0.25),
	},
	crystal = {
		name = "Farol de Cristal", desc = "Uma lanterna de cristal que brilha em tons gelados.", shape = "crystal",
		base = Color3.new(0.8, 0.9, 0.98), stripe = Color3.new(0.35, 0.6, 0.85), roof = Color3.new(0.2, 0.3, 0.45),
		lamp = Color3.new(0.85, 0.95, 1.0), beam = Color3.new(0.85, 0.94, 1.0), trim = Color3.new(0.55, 0.75, 0.95),
	},
	golden = {
		name = "Farol de Ouro", desc = "Ouro polido e lanterna de mel, digno de um rei do mar.", shape = "iron",
		base = Color3.new(0.85, 0.66, 0.22), stripe = Color3.new(1.0, 0.86, 0.45), roof = Color3.new(0.45, 0.3, 0.1),
		lamp = Color3.new(1.0, 0.9, 0.5), beam = Color3.new(1.0, 0.88, 0.5), trim = Color3.new(1.0, 0.95, 0.7),
	},
	obsidian = {
		name = "Farol de Obsidiana", desc = "Pedra vulcânica negra e uma chama violeta que corta a névoa.", shape = "stone",
		base = Color3.new(0.12, 0.1, 0.14), stripe = Color3.new(0.45, 0.2, 0.6), roof = Color3.new(0.08, 0.06, 0.1),
		lamp = Color3.new(0.8, 0.55, 1.0), beam = Color3.new(0.85, 0.65, 1.0), trim = Color3.new(0.55, 0.3, 0.75),
	},
}

function Keepers.get(id: string)
	return Keepers.LIST[id] or Keepers.LIST.classic
end

return Keepers
