-- Configurações do jogador, salvas no progresso dele (DataStore): idioma,
-- áudio, acessibilidade e a lista de controles. No Roblox a janela, a
-- resolução e a qualidade gráfica ficam no menu do próprio Roblox.

local Theme = require(script.Parent:WaitForChild("Theme"))
local Data = require(script.Parent:WaitForChild("Data"))
local Text = Data.Text

local COLORBLIND_NAMES = { "Desligado", "Protanopia", "Deuteranopia", "Tritanopia" } -- i18n
local TEXT_SCALE_LABELS = { "100%", "112%", "125%" }

local CONTROLS = { -- i18n
	{ "Andar", "WASD ou setas", "Analógico esquerdo" }, -- i18n
	{ "Apontar a lanterna", "Mouse ou toque", "Analógico direito (câmera)" }, -- i18n
	{ "Pular", "Espaço", "A" }, -- i18n
	{ "Habilidade 1", "Q", "LB" }, -- i18n
	{ "Habilidade 2", "E", "RB" }, -- i18n
	{ "Habilidade 3", "R ou F", "Y" }, -- i18n
	{ "Escolha uma melhoria", "1-4", "Direcional" }, -- i18n
	{ "Trocar cartas", "T", "X" }, -- i18n
	{ "Banir uma carta", "B", "View" }, -- i18n
	{ "Menu", "Esc", "Menu" },
}

return function(app, _params)
	local frame, box = Theme.screen(900, 660, Text.t("Configurações"))
	local s = app.settings
	local scroll = Theme.scroll(box, UDim2.new(1, 0, 0, 500), { LayoutOrder = 10 })
	Theme.list(scroll, 8)
	local order = 0
	local function nextOrder(): number
		order += 1
		return order
	end
	local function section(title: string)
		Theme.label(scroll, Text.t(title), 22, Theme.GOLD, Theme.HEAD, { LayoutOrder = nextOrder() })
	end
	local function row(name: string): Frame
		local r = Theme.make("Frame", scroll, { Size = UDim2.new(1, -16, 0, 42), BackgroundTransparency = 1, LayoutOrder = nextOrder() })
		Theme.label(r, Text.t(name), 17, Theme.TEXT, Theme.BODY, {
			Size = UDim2.new(0.45, 0, 1, 0), TextXAlignment = Enum.TextXAlignment.Left,
		})
		local holder = Theme.make("Frame", r, {
			Size = UDim2.new(0.55, 0, 1, 0), Position = UDim2.fromScale(0.45, 0), BackgroundTransparency = 1,
		})
		Theme.list(holder, 0, true, Enum.HorizontalAlignment.Right)
		return holder
	end
	local first: GuiObject? = nil

	section("Geral")
	local codes, names = {}, {}
	for _, l in Data.LANGUAGES do
		table.insert(codes, l[1])
		table.insert(names, if l[1] == "" then Text.t(l[2]) else l[2])
	end
	local lang = Theme.selector(row("Idioma"), names, table.find(codes, s.locale or "") or 1, function(i)
		app.setSetting("locale", codes[i], true)
	end, 320)
	first = lang:FindFirstChildWhichIsA("TextButton")

	section("Áudio")
	Theme.slider(row("Trilha sonora"), s.music or 80, function(v)
		app.setSetting("music", v)
	end)
	Theme.slider(row("Efeitos sonoros"), s.sfx or 100, function(v)
		app.setSetting("sfx", v)
	end)
	-- O Roblox não deixa o jogo escolher a saída de som; fica no menu dele.
	Theme.label(scroll, Text.t("A saída de áudio (fone ou alto-falante) é escolhida fora do jogo: no menu do Roblox (Esc → Configurações) ou no som do Windows."),
		14, Theme.TEXT_DIM, Theme.BODY, { LayoutOrder = nextOrder(), Size = UDim2.new(1, -16, 0, 40) })

	section("Acessibilidade")
	local cbNames = {}
	for _, n in COLORBLIND_NAMES do
		table.insert(cbNames, Text.t(n))
	end
	Theme.selector(row("Filtro para daltonismo"), cbNames, (s.colorblind or 0) + 1, function(i)
		app.setSetting("colorblind", i - 1)
	end, 300)
	Theme.selector(row("Tamanho do texto"), TEXT_SCALE_LABELS, (s.text_scale or 0) + 1, function(i)
		app.setSetting("text_scale", i - 1, true)
	end, 220)
	Theme.toggle(row("Reduzir efeitos piscantes"), s.reduce_flashes == true, function(on)
		app.setSetting("reduce_flashes", on)
	end)
	Theme.toggle(row("Tremor de tela"), s.shake ~= false, function(on)
		app.setSetting("shake", on)
	end)
	Theme.label(scroll, Text.t("Reduzir efeitos piscantes desliga relâmpagos, clarões e bordas vermelhas de dano. O tamanho do texto vale ao abrir a próxima tela."),
		13, Theme.TEXT_DIM, Theme.BODY, { LayoutOrder = nextOrder(), Size = UDim2.new(1, -16, 0, 36) })

	section("Controles")
	for _, c in CONTROLS do
		local r = Theme.make("Frame", scroll, { Size = UDim2.new(1, -16, 0, 26), BackgroundTransparency = 1, LayoutOrder = nextOrder() })
		Theme.label(r, Text.t(c[1]), 15, Theme.TEXT, Theme.BODY, { Size = UDim2.fromScale(0.4, 1), TextXAlignment = Enum.TextXAlignment.Left })
		Theme.label(r, Text.t(c[2]), 15, Theme.GOLD, Theme.BOLD, { Size = UDim2.fromScale(0.35, 1), Position = UDim2.fromScale(0.4, 0) })
		Theme.label(r, c[3], 15, Theme.GOLD, Theme.BOLD, { Size = UDim2.fromScale(0.25, 1), Position = UDim2.fromScale(0.75, 0) })
	end

	Theme.backButton(box, app, 30)
	return { frame = frame, focus = first }
end
