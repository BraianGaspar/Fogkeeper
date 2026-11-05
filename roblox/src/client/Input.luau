-- Comandos do jogador. O avatar anda com os controles padrão do Roblox
-- (WASD/setas, analógico esquerdo, polegar no celular) e a câmera é a de
-- terceira pessoa do Roblox. O feixe sai da lanterna do avatar e gira aqui na
-- hora (sem esperar a rede); o ângulo vai para o servidor 20 vezes por
-- segundo e o servidor só aceita giros dentro da velocidade do feixe.
--   Mouse: o feixe aponta para o ponto do mar sob o cursor
--   Toque: tocar ou arrastar fora dos botões aponta para aquele ponto
--   Controle (ou só teclado): o feixe aponta para onde a câmera olha
--   Q, LB: habilidade 1   •   E, RB: habilidade 2   •   R ou F, Y: habilidade 3
--   1-4 ou direcional (←, ↑, →, ↓): escolhe a carta de melhoria
--   T, X do controle: troca as cartas   •   B, View do controle: bane uma carta
--   Esc, P, B do controle: volta / abre o menu   •   Menu do controle: menu do jogador
-- Espaço (pular), Shift e o botão direito (câmera) ficam com o Roblox.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Balance = require(ReplicatedStorage:WaitForChild("Fogkeeper"):WaitForChild("Balance"))
local Text = require(ReplicatedStorage:WaitForChild("Fogkeeper"):WaitForChild("Text"))

local Input = {}

Input.angle = 0
Input.usingPad = false
Input.onAbility = nil :: ((number) -> ())?
Input.onPick = nil :: ((number) -> ())?
Input.onReroll = nil :: (() -> ())?
Input.onBanish = nil :: (() -> ())?
Input.onBack = nil :: (() -> ())?
Input.onMenu = nil :: (() -> ())?
Input.playing = false
-- Origem do feixe (lanterna do avatar), em studs; o Client atualiza a cada quadro.
Input.origin = Vector3.new(0, 2.4, 0)

-- De onde vem a mira: "mouse" (cursor), "touch" (ponto tocado) ou "camera".
local aimMode = "mouse"
local touchPoint: Vector3? = nil
local sendTimer = 0
local aimEvent: any = nil

local function angleDiff(a: number, b: number): number
	return (b - a + math.pi) % (2 * math.pi) - math.pi
end

-- Ponto do plano do feixe sob um raio da câmera.
local function planePoint(ray: Ray): Vector3?
	if math.abs(ray.Direction.Y) < 1e-4 then
		return nil
	end
	local t = (Input.origin.Y - ray.Origin.Y) / ray.Direction.Y
	if t <= 0 then
		return nil -- o cursor está no céu
	end
	return ray.Origin + ray.Direction * t
end

-- Ângulo do avatar até um ponto do mundo (nil se for perto demais).
local function angleTo(p: Vector3?): number?
	if not p then
		return nil
	end
	local dx, dz = p.X - Input.origin.X, p.Z - Input.origin.Z
	if dx * dx + dz * dz < 1 then
		return nil
	end
	return math.atan2(dz, dx)
end

local ABILITY_KEYS = {
	[Enum.KeyCode.Q] = 1, [Enum.KeyCode.ButtonL1] = 1,
	[Enum.KeyCode.E] = 2, [Enum.KeyCode.ButtonR1] = 2,
	[Enum.KeyCode.R] = 3, [Enum.KeyCode.F] = 3, [Enum.KeyCode.ButtonY] = 3,
}
local PICK_KEYS = {
	[Enum.KeyCode.One] = 1, [Enum.KeyCode.Two] = 2, [Enum.KeyCode.Three] = 3, [Enum.KeyCode.Four] = 4,
	[Enum.KeyCode.KeypadOne] = 1, [Enum.KeyCode.KeypadTwo] = 2, [Enum.KeyCode.KeypadThree] = 3, [Enum.KeyCode.KeypadFour] = 4,
	[Enum.KeyCode.DPadLeft] = 1, [Enum.KeyCode.DPadUp] = 2, [Enum.KeyCode.DPadRight] = 3, [Enum.KeyCode.DPadDown] = 4,
}

-- Nome da tecla ou do botão de cada ação, conforme o aparelho em uso.
local PAD_LABELS = {
	ability_1 = "LB", ability_2 = "RB", ability_3 = "Y", pick = "A", reroll = "X", banish = "View", back = "B", menu = "Menu",
}
local KEY_LABELS = {
	ability_1 = "Q", ability_2 = "E", ability_3 = "R", pick = "Enter", reroll = "T", banish = "B", back = "Esc", menu = "Esc",
}

function Input.label(action: string): string
	if Input.usingPad then
		return PAD_LABELS[action] or ""
	end
	return Text.t(KEY_LABELS[action] or "")
end

local function fire(fn: any, ...)
	if fn then
		fn(...)
	end
end

function Input.start(aim: any)
	aimEvent = aim
	UserInputService.InputBegan:Connect(function(input, processed)
		local kind = input.UserInputType
		if kind == Enum.UserInputType.Gamepad1 then
			Input.usingPad = true
			aimMode = "camera"
		elseif kind == Enum.UserInputType.Keyboard or kind == Enum.UserInputType.MouseButton1 or kind == Enum.UserInputType.Touch then
			Input.usingPad = false
		end
		local key = input.KeyCode
		-- Voltar e menu valem até com um botão de interface selecionado.
		-- (P digitado no chat ou numa caixa de texto não conta.)
		if key == Enum.KeyCode.Escape or (key == Enum.KeyCode.P and not processed) or key == Enum.KeyCode.ButtonB then
			fire(Input.onBack)
			return
		end
		if key == Enum.KeyCode.ButtonStart then
			fire(Input.onMenu)
			return
		end
		if processed then
			return -- o polegar de andar e os botões da interface não miram
		end
		if kind == Enum.UserInputType.Touch then
			aimMode = "touch"
			touchPoint = planePoint(workspace.CurrentCamera:ScreenPointToRay(input.Position.X, input.Position.Y))
		end
		if not Input.playing then
			return
		end
		local ability = ABILITY_KEYS[key]
		if ability then
			fire(Input.onAbility, ability)
		end
		local pick = PICK_KEYS[key]
		if pick then
			fire(Input.onPick, pick)
		end
		if key == Enum.KeyCode.T or key == Enum.KeyCode.ButtonX then
			fire(Input.onReroll)
		elseif key == Enum.KeyCode.B or key == Enum.KeyCode.ButtonSelect then
			fire(Input.onBanish)
		end
	end)
	UserInputService.InputChanged:Connect(function(input, processed)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			if input.Delta.Magnitude > 2 then
				Input.usingPad = false
				aimMode = "mouse"
			end
		elseif input.UserInputType == Enum.UserInputType.Touch and not processed then
			aimMode = "touch"
			touchPoint = planePoint(workspace.CurrentCamera:ScreenPointToRay(input.Position.X, input.Position.Y))
		elseif input.KeyCode == Enum.KeyCode.Thumbstick2 or input.KeyCode == Enum.KeyCode.Thumbstick1 then
			if Vector2.new(input.Position.X, input.Position.Y).Magnitude > 0.3 then
				Input.usingPad = true
				aimMode = "camera"
			end
		end
	end)
end

-- Ângulo que a mira pede agora.
local function wantedAngle(): number?
	local camera = workspace.CurrentCamera
	if aimMode == "mouse" and not Input.usingPad then
		local m = UserInputService:GetMouseLocation()
		return angleTo(planePoint(camera:ViewportPointToRay(m.X, m.Y)))
	elseif aimMode == "touch" then
		return angleTo(touchPoint)
	end
	local look = camera.CFrame.LookVector
	if math.abs(look.X) + math.abs(look.Z) < 1e-3 then
		return nil
	end
	return math.atan2(look.Z, look.X)
end

function Input.update(dt: number, playing: boolean)
	Input.playing = playing
	-- Farol petrificado (Medusa): o servidor manda o giro reduzido em TurnSpeed.
	local turn = Players.LocalPlayer:GetAttribute("TurnSpeed") or Balance.TURN_SPEED or 2.8
	local target = wantedAngle()
	if target then
		local step = turn * dt
		Input.angle += math.clamp(angleDiff(Input.angle, target), -step, step)
	end
	Input.angle %= 2 * math.pi
	sendTimer -= dt
	if playing and sendTimer <= 0 and aimEvent then
		sendTimer = 1 / 20
		aimEvent:FireServer(Input.angle)
	end
end

-- Volta ao ângulo do servidor (início de partida).
function Input.reset(angle: number)
	Input.angle = angle
end

return Input
