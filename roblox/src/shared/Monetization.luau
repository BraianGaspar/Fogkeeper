-- Catálogo de compras com Robux. Os IDs vêm do Creator Dashboard (ver
-- roblox/README.md, seção "Monetização"); 0 = desativado, e o jogo funciona
-- normalmente sem nada configurado (a loja mostra "Indisponível").
-- Regras: nada de prêmio aleatório; visuais não dão vantagem na partida; o
-- reviver é limitado e tira a partida do ranking mundial.

local Monetization = {}

-- Game Passes (compra única). `key` é o nome interno usado nos atributos.
Monetization.PASSES = {
	{ key = "vip", id = 0, name = "VIP do Farol",
		desc = "Ganha o dobro de óleo em cada partida e um selo dourado no saguão e acima do avatar." },
	{ key = "rainbow", id = 0, name = "Feixes Arco-íris",
		desc = "Libera cores novas para o seu feixe de luz. Só visual." },
	{ key = "golden_lantern", id = 0, name = "Lanterna dourada",
		desc = "Brasas douradas flutuam em volta do seu avatar. Só visual." },
	{ key = "legendary_lighthouses", id = 0, name = "Faróis lendários",
		desc = "Libera o Farol de Ouro e o Farol de Obsidiana para quando você for o anfitrião. Só visual." },
}

-- Developer Products (compra repetível).
Monetization.PRODUCTS = {
	{ key = "oil_small", id = 0, oil = 150, name = "Barril pequeno de óleo", desc = "+150 de óleo para a oficina." },
	{ key = "oil_medium", id = 0, oil = 450, name = "Barril de óleo", desc = "+450 de óleo para a oficina." },
	{ key = "oil_large", id = 0, oil = 1200, name = "Tonel de óleo", desc = "+1.200 de óleo para a oficina." },
	{ key = "revive", id = 0, name = "Reacender o farol",
		desc = "Quando a luz se apaga, o farol volta com metade da vida e a noite continua. Uma vez por partida, só no modo Normal; a partida sai do ranking mundial." },
}

-- Cores do passe "Feixes Arco-íris" (a cor padrão, sem passe, é a do farol/vaga).
Monetization.BEAM_COLORS = {
	{ key = "default", name = "Padrão", color = nil },
	{ key = "ruby", name = "Rubi", color = Color3.fromRGB(255, 90, 90) },
	{ key = "emerald", name = "Esmeralda", color = Color3.fromRGB(90, 240, 140) },
	{ key = "sapphire", name = "Safira", color = Color3.fromRGB(90, 160, 255) },
	{ key = "amethyst", name = "Ametista", color = Color3.fromRGB(190, 120, 255) },
	{ key = "sunset", name = "Pôr do sol", color = Color3.fromRGB(255, 150, 60) },
	{ key = "frost", name = "Geada", color = Color3.fromRGB(200, 245, 255) },
}

-- Faróis liberados por passe (dados de aparência em shared/Keepers.luau).
Monetization.PASS_KEEPERS = { golden = "legendary_lighthouses", obsidian = "legendary_lighthouses" }

local passByKey, passById, productByKey, productById, colorByKey = {}, {}, {}, {}, {}
for _, p in Monetization.PASSES do
	passByKey[p.key] = p
	if p.id ~= 0 then
		passById[p.id] = p
	end
end
for _, p in Monetization.PRODUCTS do
	productByKey[p.key] = p
	if p.id ~= 0 then
		productById[p.id] = p
	end
end
for _, c in Monetization.BEAM_COLORS do
	colorByKey[c.key] = c
end

function Monetization.pass(key: string)
	return passByKey[key]
end

function Monetization.passById(id: number)
	return passById[id]
end

function Monetization.product(key: string)
	return productByKey[key]
end

function Monetization.productById(id: number)
	return productById[id]
end

function Monetization.beamColor(key: string)
	return colorByKey[key]
end

-- Passe que libera um farol, ou nil se o farol não depende de passe.
function Monetization.keeperPass(keeperId: string): string?
	return Monetization.PASS_KEEPERS[keeperId]
end

return Monetization
