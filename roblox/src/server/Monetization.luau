-- Compras com Robux: Game Passes (posse com cache), Developer Products
-- (ProcessReceipt idempotente: só confirma ao Roblox depois de salvar) e os
-- visuais (cor do feixe, brasas douradas no avatar). Catálogo em
-- shared/Monetization.luau; IDs 0 ficam desativados.
-- Atributos do jogador: Passes ("vip,rainbow"), Vip (bool), BeamColor (Color3).

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Fogkeeper")
local Balance = require(Shared:WaitForChild("Balance"))
local Catalog = require(Shared:WaitForChild("Monetization"))
local Net = require(Shared:WaitForChild("Net"))
local Progress = require(script.Parent:WaitForChild("Progress"))

local Monetization = {}

-- Chamado quando alguém compra "Reacender o farol"; retorna true se reacendeu
-- (Main liga isto). Falso = a janela já fechou e o comprador recebe óleo.
Monetization.onRevive = nil :: ((Player) -> boolean)?

local owned: { [number]: { [string]: boolean } } = {} -- userId -> passes possuídos
local MAX_RECEIPTS = 300

local function ownsPassAsync(player: Player, pass): boolean
	if pass.id == 0 then
		return false
	end
	local ok, result = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, pass.id)
	end)
	return ok and result == true
end

function Monetization.owns(player: Player, key: string): boolean
	local set = owned[player.UserId]
	return set ~= nil and set[key] == true
end

-- Atributos que a interface lê.
local function publish(player: Player)
	local keys = {}
	for _, pass in Catalog.PASSES do
		if Monetization.owns(player, pass.key) then
			table.insert(keys, pass.key)
		end
	end
	player:SetAttribute("Passes", table.concat(keys, ","))
	player:SetAttribute("Vip", Monetization.owns(player, "vip"))
	if not Monetization.owns(player, "rainbow") then
		player:SetAttribute("BeamColor", nil)
	end
end

-- Brasas douradas em volta do avatar (passe "Lanterna dourada").
local function decorate(player: Player, character: Model?)
	if not character or not Monetization.owns(player, "golden_lantern") then
		return
	end
	local root = character:WaitForChild("HumanoidRootPart", 10)
	if not root or root:FindFirstChild("GoldenEmbers") then
		return
	end
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "GoldenEmbers"
	emitter.Color = ColorSequence.new(Color3.fromRGB(255, 215, 110), Color3.fromRGB(255, 150, 40))
	emitter.LightEmission = 1
	emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.25), NumberSequenceKeypoint.new(1, 0) })
	emitter.Transparency = NumberSequence.new(0.1, 1)
	emitter.Lifetime = NumberRange.new(1, 1.8)
	emitter.Rate = 14
	emitter.Speed = NumberRange.new(0.5, 1.5)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Acceleration = Vector3.new(0, 2, 0)
	emitter.Parent = root
end

-- Selo VIP acima do avatar.
local function badge(player: Player, character: Model?)
	if not character or not Monetization.owns(player, "vip") then
		return
	end
	local head = character:WaitForChild("Head", 10)
	if not head or head:FindFirstChild("VipBadge") then
		return
	end
	local gui = Instance.new("BillboardGui")
	gui.Name = "VipBadge"
	gui.Size = UDim2.fromOffset(60, 22)
	gui.StudsOffset = Vector3.new(0, 2.6, 0)
	gui.AlwaysOnTop = true
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = Color3.fromRGB(70, 52, 20)
	label.TextColor3 = Color3.fromRGB(240, 200, 110)
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.Text = "VIP"
	label.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = label
	gui.Parent = head
end

local function refresh(player: Player)
	local set = {}
	for _, pass in Catalog.PASSES do
		set[pass.key] = ownsPassAsync(player, pass)
	end
	if player.Parent == nil then
		return -- saiu durante a consulta: não deixa entrada órfã
	end
	-- Compra feita durante a consulta (PromptGamePassPurchaseFinished) vale.
	for key, v in owned[player.UserId] or {} do
		set[key] = set[key] or v
	end
	owned[player.UserId] = set
	publish(player)
	decorate(player, player.Character)
	badge(player, player.Character)
end

-- Óleo com o VIP (Main usa na recompensa de cada partida).
function Monetization.oilMultiplier(player: Player): number
	return if Monetization.owns(player, "vip") then Balance.VIP_OIL else 1
end

-- Cor do feixe escolhida (só com o passe Arco-íris).
function Monetization.setBeamColor(player: Player, key: any)
	if typeof(key) ~= "string" or not Monetization.owns(player, "rainbow") then
		return
	end
	local entry = Catalog.beamColor(key)
	if entry then
		player:SetAttribute("BeamColor", entry.color)
	end
end

-- Recibos -----------------------------------------------------------------------

local function trimReceipts(player: Player)
	local receipts = Progress.get(player).receipts
	local n = 0
	for _ in receipts do
		n += 1
	end
	if n > MAX_RECEIPTS then
		table.clear(receipts) -- o Roblox só reenvia recibos recentes ainda pendentes
	end
end

local function processReceipt(info)
	local player = Players:GetPlayerByUserId(info.PlayerId)
	if not player or not Progress.isLoaded(player) then
		-- Sem o progresso carregado não dá para registrar; o Roblox tenta de novo depois.
		return Enum.ProductPurchaseDecision.NotYetGranted
	end
	local purchaseId = tostring(info.PurchaseId)
	if Progress.hasReceipt(player, purchaseId) then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	local product = Catalog.productById(info.ProductId)
	if not product then
		warn("[Fogkeeper] produto desconhecido: " .. tostring(info.ProductId))
		return Enum.ProductPurchaseDecision.NotYetGranted
	end
	local oil = product.oil or 0
	local revived = false
	if product.key == "revive" then
		revived = Monetization.onRevive ~= nil and Monetization.onRevive(player)
		if not revived then
			oil = Balance.REVIVE_LATE_OIL -- comprou depois que a janela fechou
		end
	end
	if oil > 0 then
		Progress.addOil(player, oil, true) -- comprado: não conta para oil_total
	end
	trimReceipts(player)
	if not Progress.saveNow(player, purchaseId) then
		if oil > 0 then
			Progress.get(player).oil -= oil
		end
		-- O reviver já aconteceu; numa nova tentativa ele vira óleo (janela fechada).
		return Enum.ProductPurchaseDecision.NotYetGranted
	end
	Progress.publish(player)
	if oil > 0 then
		Net.event("Fx"):FireClient(player, "purchase", { userId = player.UserId, key = product.key, oil = oil })
	end
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

-- Liga tudo; chamar uma vez no servidor.
function Monetization.start()
	MarketplaceService.ProcessReceipt = processReceipt
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		local pass = Catalog.passById(passId)
		if purchased and pass then
			-- UserOwnsGamePassAsync guarda o resultado em cache no servidor e pode
			-- ainda dizer "não" logo depois da compra: marca a posse direto.
			local set = owned[player.UserId] or {}
			set[pass.key] = true
			owned[player.UserId] = set
			publish(player)
			task.spawn(decorate, player, player.Character)
			task.spawn(badge, player, player.Character)
		end
	end)
	Progress.passUnlock = function(player: Player, id: string): boolean?
		local pass = Catalog.keeperPass(id)
		if not pass then
			return nil
		end
		return Monetization.owns(player, pass)
	end
	local function onPlayer(player: Player)
		task.spawn(refresh, player)
		player.CharacterAdded:Connect(function(character)
			task.spawn(decorate, player, character)
			task.spawn(badge, player, character)
		end)
	end
	Players.PlayerAdded:Connect(onPlayer)
	for _, player in Players:GetPlayers() do
		onPlayer(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		owned[player.UserId] = nil
	end)
end

return Monetization
