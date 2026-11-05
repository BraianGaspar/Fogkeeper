-- Entrada do jogador: avatar em terceira pessoa (câmera do Roblox), comandos,
-- desenho do mundo, ciclo do dia, sons e a interface. Cada jogador é um
-- faroleiro que anda pela ilha com uma lanterna, de onde sai o seu feixe.

local Lighting = game:GetService("Lighting")
local LocalizationService = game:GetService("LocalizationService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")

local Shared = ReplicatedStorage:WaitForChild("Fogkeeper")
local Balance = require(Shared:WaitForChild("Balance"))
local Net = require(Shared:WaitForChild("Net"))
local Text = require(Shared:WaitForChild("Text"))
local Input = require(script.Parent:WaitForChild("Input"))
local Renderer = require(script.Parent:WaitForChild("Renderer"))
local Sounds = require(script.Parent:WaitForChild("Sounds"))
local App = require(script.Parent:WaitForChild("Ui"):WaitForChild("App"))

local DayCycle: any = nil
do
	local mod = script.Parent:FindFirstChild("DayCycle") or script.Parent:WaitForChild("DayCycle", 3)
	if mod then
		local ok, result = pcall(require, mod)
		if ok then
			DayCycle = result
		else
			warn("[Fogkeeper] DayCycle: " .. tostring(result))
		end
	end
end

local player = Players.LocalPlayer
local state = Net.state()
local camera = workspace.CurrentCamera
local RUN = Balance.RUN_DURATION or 600

pcall(function()
	Text.setLocale(LocalizationService.RobloxLocaleId)
end)
pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
end)

-- Avatar em terceira pessoa ------------------------------------------------------
-- Câmera padrão do Roblox; o tremor dos golpes fortes mexe só o deslocamento
-- da câmera (Humanoid.CameraOffset). Na partida o corpo vira para onde o
-- feixe aponta; com um menu aberto o avatar fica parado.

local function myHumanoid(): (Humanoid?, BasePart?)
	local character = player.Character
	if not character then
		return nil, nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	return humanoid, if rootPart and rootPart:IsA("BasePart") then rootPart else nil
end

local function onCharacter(character: Model)
	local humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?
	if humanoid then
		-- Ninguém nada nem morre: a ilha tem mureta e a vida que importa é a do farol.
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming, false)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
	end
	camera.CameraType = Enum.CameraType.Custom
end
player.CharacterAdded:Connect(onCharacter)
if player.Character then
	task.spawn(onCharacter, player.Character)
end

local function updateAvatar(dt: number, phase: string)
	local humanoid, rootPart = myHumanoid()
	if not humanoid or not rootPart then
		return
	end
	-- Origem do feixe: a altura da mão, sobre o avatar.
	Input.origin = Vector3.new(rootPart.Position.X, rootPart.Position.Y - 1.4, rootPart.Position.Z)
	-- No saguão os avatares andam livres mesmo com as telas abertas; na partida,
	-- um menu aberto (pausa, configurações) segura o avatar.
	local menuOpen = phase == "playing" and App.top() ~= nil
	humanoid.WalkSpeed = if menuOpen then 0 else Balance.AVATAR_WALK_SPEED
	humanoid.JumpHeight = if menuOpen then 0 else 7.2
	humanoid.JumpPower = if menuOpen then 0 else 50
	local aiming = phase == "playing" and not menuOpen
	humanoid.AutoRotate = not aiming
	if aiming then
		local a = Input.angle
		local pos = rootPart.Position
		rootPart.CFrame = CFrame.lookAt(pos, pos + Vector3.new(math.cos(a), 0, math.sin(a)))
	end
	local shake = if App.settings.shake == false then 0 else Renderer.shake
	Renderer.shake = math.max(0, Renderer.shake - dt * 2.5)
	humanoid.CameraOffset = Vector3.new(math.random() - 0.5, math.random() - 0.5, 0) * shake * 1.5
end

-- Canais -------------------------------------------------------------------------

local lobbyEvent = Net.event("Lobby")
local abilityEvent = Net.event("Ability")
local pickEvent = Net.event("Pick")
local rerollEvent = Net.event("Reroll")
local banishEvent = Net.event("Banish")

local function playing(): boolean
	return state:GetAttribute("Phase") == "playing"
end

local function useAbility(i: number)
	if playing() then
		abilityEvent:FireServer(i)
	end
end

local ctx = {
	state = state,
	input = Input,
	renderer = Renderer,
	sounds = Sounds,
	useAbility = useAbility,
	send = function(action: string, value: any?, extra: any?)
		lobbyEvent:FireServer(action, value, extra)
	end,
	net = {
		pick = function(id: string)
			pickEvent:FireServer(id)
		end,
		reroll = function()
			rerollEvent:FireServer()
		end,
		banish = function(id: string)
			banishEvent:FireServer(id)
		end,
	},
}

App.build(ctx)
Renderer.app = App

Input.onAbility = useAbility
Input.onPick = function(i)
	App.hud.pick(i)
end
Input.onReroll = function()
	App.hud.reroll()
end
Input.onBanish = function()
	App.hud.toggleBanish()
end
Input.onBack = function()
	App.backPressed()
end
Input.onMenu = function()
	if playing() and not App.top() then
		App.open("PlayerMenu")
	else
		App.backPressed()
	end
end
Input.start(Net.event("Aim"))

Net.event("Snapshot").OnClientEvent:Connect(function(data)
	local ok, enemies, embers, deaths = pcall(Net.decode, data)
	if ok then
		Renderer.snapshot(enemies, embers, deaths)
	end
end)

Net.event("Announce").OnClientEvent:Connect(function(text, args, color, big)
	App.announce(text, args, color, big)
end)

Net.event("Fx").OnClientEvent:Connect(function(name, data)
	Renderer.fx(name, data)
end)

-- Fases: saguão, história, partida, fim.
local function onPhase()
	local phase = state:GetAttribute("Phase") or "lobby"
	App.onPhase(phase)
	if phase == "playing" then
		task.delay(0.3, function()
			Input.reset(player:GetAttribute("AimAngle") or 0)
		end)
	elseif phase == "lobby" then
		Renderer.clear()
	end
end
state:GetAttributeChangedSignal("Phase"):Connect(onPhase)
onPhase()

-- Quadro a quadro ------------------------------------------------------------------

local t = 0
RunService.RenderStepped:Connect(function(dt)
	t += dt
	local phase = state:GetAttribute("Phase") or "lobby"
	updateAvatar(dt, phase)
	local map = state:GetAttribute("Map") or "bay"
	local cycle = state:GetAttribute("CycleSeconds")
	local progress
	if phase == "lobby" or phase == "story" then
		progress = 0.12 -- entardecer bonito no saguão
	elseif type(cycle) == "number" then
		progress = cycle / RUN
	else
		progress = math.clamp((workspace:GetServerTimeNow() - (state:GetAttribute("RunStart") or 0)) / RUN, 0, 1.1)
	end
	Renderer.reduceFlashes = App.settings.reduce_flashes == true
	if DayCycle then
		DayCycle.reduceFlashes = Renderer.reduceFlashes
		local ok, err = pcall(DayCycle.update, map, progress, state:GetAttribute("Endless") == true, dt)
		if not ok then
			warn("[Fogkeeper] DayCycle: " .. tostring(err))
			DayCycle = nil
		end
	else
		Lighting.ClockTime = (18 + math.min(progress, 1) * 12) % 24
	end
	-- Música: saguão, mapa ou chefe.
	if phase == "lobby" then
		Sounds.music("lobby")
	elseif (state:GetAttribute("BossName") or "") ~= "" then
		Sounds.music("boss")
	else
		Sounds.music(map)
	end
	Input.update(dt, phase == "playing")
	Renderer.update(dt, t)
	Renderer.updateBeams(dt, phase == "playing", Input.angle, state:GetAttribute("Ink") == true)
	App.update(dt)
end)
