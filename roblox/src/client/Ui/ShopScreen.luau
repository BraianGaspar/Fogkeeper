-- Loja de Robux: Game Passes (VIP e visuais) e Developer Products (óleo e
-- reacender o farol). Preços reais vêm do MarketplaceService; as compras só
-- acontecem pelas janelas oficiais do Roblox. Quem tem "Feixes Arco-íris"
-- escolhe a cor do feixe aqui. Catálogo em shared/Monetization.luau.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Theme = require(script.Parent:WaitForChild("Theme"))
local Data = require(script.Parent:WaitForChild("Data"))
local Catalog = require(ReplicatedStorage:WaitForChild("Fogkeeper"):WaitForChild("Monetization"))
local Text = Data.Text

local prices: { [string]: number } = {} -- "pass:id" / "product:id" -> preço em Robux

-- Preço em Robux. "R$" seria lido como reais no Brasil; o ícone de Robux
-- (U+E002) não existe nas fontes antigas do Theme (Garamond), então vai por extenso.
local function robux(n: number): string
	return Data.number(n) .. " Robux"
end

-- Busca o preço uma vez (assíncrono) e chama `done` com o texto do botão.
local function fetchPrice(kind: string, id: number, done: (string) -> ())
	local key = kind .. ":" .. id
	if prices[key] then
		done(robux(prices[key]))
		return
	end
	task.spawn(function()
		local ok, info = pcall(function()
			return MarketplaceService:GetProductInfo(id, if kind == "pass" then Enum.InfoType.GamePass else Enum.InfoType.Product)
		end)
		if ok and type(info) == "table" and type(info.PriceInRobux) == "number" then
			prices[key] = info.PriceInRobux
			done(robux(info.PriceInRobux))
		end
	end)
end

local function owned(key: string): boolean
	local list = string.split(Players.LocalPlayer:GetAttribute("Passes") or "", ",")
	return table.find(list, key) ~= nil
end

local function item(parent: Instance, order: number, title: string, desc: string): Frame
	local r = Theme.make("Frame", parent, {
		Size = UDim2.new(1, -12, 0, 72), BackgroundColor3 = Theme.PANEL_LIGHT, BackgroundTransparency = 0.3, BorderSizePixel = 0,
		LayoutOrder = order,
	})
	Theme.corner(r, 8)
	Theme.label(r, title, 18, Theme.GOLD, Theme.HEAD, {
		Position = UDim2.fromOffset(14, 6), Size = UDim2.new(1, -260, 0, 24), TextXAlignment = Enum.TextXAlignment.Left,
	})
	Theme.label(r, desc, 13, Theme.TEXT, Theme.BODY, {
		Position = UDim2.fromOffset(14, 30), Size = UDim2.new(1, -260, 0, 38), TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
	})
	return r
end

local function buyButton(row: Frame, kind: string, id: number, isOwned: boolean): TextButton
	local b = Theme.smallButton(row, "", UDim2.fromOffset(200, 44), function()
		if id == 0 or isOwned then
			return
		end
		if kind == "pass" then
			MarketplaceService:PromptGamePassPurchase(Players.LocalPlayer, id)
		else
			MarketplaceService:PromptProductPurchase(Players.LocalPlayer, id)
		end
	end, { Position = UDim2.new(1, -12, 0.5, 0), AnchorPoint = Vector2.new(1, 0.5) })
	if isOwned then
		b.Text = Text.t("Possui")
		Theme.setSelected(b, true)
		Theme.setDisabled(b, true)
	elseif id == 0 then
		b.Text = Text.t("Indisponível")
		Theme.setDisabled(b, true)
	else
		b.Text = Text.t("Comprar")
		fetchPrice(kind, id, function(price)
			if b.Parent then
				b.Text = Text.format("Comprar  •  %s", { price })
			end
		end)
	end
	return b
end

return function(app, _params)
	local frame, box = Theme.screen(980, 660, Text.t("Loja"))
	Theme.label(box, Text.t("Visuais não dão vantagem na partida. Tudo é comprado pelas janelas oficiais do Roblox."),
		14, Theme.TEXT_DIM, Theme.BODY, { LayoutOrder = 10 })
	local scroll = Theme.scroll(box, UDim2.new(1, 0, 0, 470), { LayoutOrder = 20 })
	Theme.list(scroll, 6)
	local order = 0
	local function nextOrder(): number
		order += 1
		return order
	end
	local first: GuiObject? = nil
	local passesShown = Players.LocalPlayer:GetAttribute("Passes") or ""

	Theme.label(scroll, Text.t("Passes"), 20, Theme.GOLD, Theme.HEAD, { LayoutOrder = nextOrder() })
	for _, pass in Catalog.PASSES do
		local row = item(scroll, nextOrder(), Text.t(pass.name), Text.t(pass.desc))
		local b = buyButton(row, "pass", pass.id, owned(pass.key))
		first = first or b
	end

	-- Cores do feixe (só para quem tem o passe).
	if owned("rainbow") then
		Theme.label(scroll, Text.t("Cor do seu feixe"), 20, Theme.GOLD, Theme.HEAD, { LayoutOrder = nextOrder() })
		local colors = Theme.make("Frame", scroll, { Size = UDim2.new(1, -12, 0, 48), BackgroundTransparency = 1, LayoutOrder = nextOrder() })
		Theme.list(colors, 8, true)
		for _, c in Catalog.BEAM_COLORS do
			local b = Theme.smallButton(colors, Text.t(c.name), UDim2.fromOffset(118, 42), function()
				app.ctx.send("cosmetic", "beam", c.key)
			end)
			if c.color then
				b.TextColor3 = c.color
			end
		end
	end

	Theme.label(scroll, Text.t("Óleo e reacender"), 20, Theme.GOLD, Theme.HEAD, { LayoutOrder = nextOrder() })
	for _, product in Catalog.PRODUCTS do
		local row = item(scroll, nextOrder(), Text.t(product.name), Text.t(product.desc))
		local revive = product.key == "revive"
		local b = buyButton(row, "product", if revive then 0 else product.id, false)
		if revive then
			-- Só faz sentido quando a luz se apaga: a compra aparece no HUD nessa hora.
			b.Text = Text.t("Na hora da derrota")
			Theme.setDisabled(b, true)
		end
	end

	Theme.backButton(box, app, 30)
	return {
		frame = frame,
		focus = first,
		closable = true,
		update = function()
			-- Um passe comprado agora chega pelo atributo Passes: reconstrói.
			if (Players.LocalPlayer:GetAttribute("Passes") or "") ~= passesShown then
				app.refresh()
			end
		end,
	}
end
