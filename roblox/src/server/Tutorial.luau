-- Tutorial guiado (scripts/core/tutorial.gd): uma partida de treino na Baía,
-- só com um jogador, sem relógio nem chefes marcados. Cada passo avança
-- quando o jogador faz o que foi pedido. A simulação chama os ganchos
-- (onKill, onEmber, onUpgrade, onAbility, onEscape) e tick(dt); o texto vai
-- para o atributo TutorialJson em português (o cliente traduz), com as teclas
-- do teclado em `args` e as do controle em `padArgs`.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Balance = require(ReplicatedStorage:WaitForChild("Fogkeeper"):WaitForChild("Balance"))

local Tutorial = {}
Tutorial.__index = Tutorial

local Step = { AIM = 1, BURN = 2, EMBERS = 3, LEVEL_UP = 4, ABILITIES = 5, THIEF = 6, MIRROR = 7, BOSS = 8, DONE = 9 }
Tutorial.Step = Step

local TURN_GOAL = math.pi * 1.5 -- quanto girar o feixe no primeiro passo
local RESPAWN_DELAY = 1 -- segundos sem criaturas antes de trazer outras para praticar

-- Teclas mostradas nos textos (as mesmas de client/Input.luau).
local KEYS = { left = "A", right = "D", left2 = "←", right2 = "→", a1 = "Q", a2 = "E", a3 = "R" }
local PAD = { a1 = "LB", a2 = "RB", a3 = "Y", confirm = "A", reroll = "X", banish = "View" }

function Tutorial.new(sim)
	local self = setmetatable({}, Tutorial)
	self.sim = sim
	self.step = Step.AIM
	self.count = 0
	self.turned = 0
	self.lastAim = nil
	self.used = {}
	self.timer = 0
	self.spawned = {}
	self.text = nil -- {title, body, args, padBody, padArgs, progress}
	return self
end

function Tutorial:begin()
	self:_enter(Step.AIM)
end

function Tutorial:allowsLevelUp(): boolean
	return self.step == Step.LEVEL_UP
end

function Tutorial:done(): boolean
	return self.step == Step.DONE and self.timer >= Balance.TUTORIAL_DONE_TIME
end

function Tutorial:_spawnRing(role: string, n: number, distance: number)
	for _ = 1, n do
		table.insert(self.spawned, self.sim:spawnRing(role, distance))
	end
end

-- Brasas soltas longe do farol, para a ladra ter o que roubar.
function Tutorial:_dropEmbers(n: number)
	local sim = self.sim
	for _ = 1, n do
		local a = sim.rng:NextNumber() * 2 * math.pi
		local r = sim.rng:NextNumber(200, 300)
		table.insert(sim.embers, { id = sim._nextId, x = math.cos(a) * r, y = math.sin(a) * r, value = 1,
			life = 60, pulled = false, vx = 0, vy = 0 })
		sim._nextId += 1
	end
end

function Tutorial:_alive(): number
	local n = 0
	for _, e in self.spawned do
		if e.hp > 0 and table.find(self.sim.enemies, e) then
			n += 1
		end
	end
	return n
end

function Tutorial:_enter(s: number)
	local sim = self.sim
	self.step = s
	self.count = 0
	self.timer = 0
	self.spawned = {}
	if s == Step.BURN then
		self:_spawnRing("basic", 3, 420)
	elseif s == Step.EMBERS then
		self:_spawnRing("basic", 4, 470)
	elseif s == Step.LEVEL_UP then
		sim.xp = 0
		sim:levelUp()
	elseif s == Step.ABILITIES then
		self.used = {}
		self:_spawnRing("basic", 8, 300)
	elseif s == Step.THIEF then
		self:_spawnRing("thief", 1, 520)
		self:_dropEmbers(5)
	elseif s == Step.MIRROR then
		self:_spawnRing("mirror", 1, 430)
	elseif s == Step.BOSS then
		sim:spawnBoss("leviathan")
	elseif s == Step.DONE then
		sim:fx("victory", {})
	end
	self:refresh()
end

function Tutorial:refresh()
	local t, body, padBody, progress = "", "", nil, ""
	local args, padArgs = {}, nil
	local s = self.step
	if s == Step.AIM then
		t = "1. Ande e aponte a luz"
		body = "Ande pela ilha com WASD ou as setas e aponte a lanterna com o mouse (ou tocando na tela): o seu feixe sai da sua mão e segue o ponto escolhido."
		args = {}
		padBody = "Ande com o analógico esquerdo e gire a câmera com o direito: o feixe da sua lanterna aponta para onde a câmera olha."
		padArgs = {}
		progress = string.format("%d%%", math.min(100, math.floor(self.turned / TURN_GOAL * 100)))
	elseif s == Step.BURN then
		t = "2. Queime as criaturas"
		body = "Criaturas saem da névoa e vêm atacar o farol. Mantenha a luz sobre elas até que queimem."
		progress = string.format("%d / 3", self.count)
	elseif s == Step.EMBERS then
		t = "3. Recolha as brasas"
		body = "Cada criatura queimada deixa uma brasa. Passe a luz sobre ela para trazê-la ao farol: é a sua experiência. Brasas esquecidas se apagam."
		progress = string.format("%d / 4", self.count)
	elseif s == Step.LEVEL_UP then
		t = "4. Suba de nível"
		body = "Com brasas suficientes, você escolhe uma melhoria. As cartas aparecem no canto da tela e a partida não pausa: aperte 1 a 4 ou clique na carta. T troca as cartas e B bane uma."
		args = {}
		padBody = "Com brasas suficientes, você escolhe uma melhoria. As cartas aparecem no canto da tela e a partida não pausa: cada direção do direcional escolhe uma carta. %s troca as cartas e %s bane uma."
		padArgs = { PAD.reroll, PAD.banish }
	elseif s == Step.ABILITIES then
		t = "5. Use as habilidades"
		-- O botão direito gira a câmera no Roblox: a Sobrecarga fica só na tecla.
		body = "%s: Clarão (fere e atordoa em volta)   •   %s: Sobrecarga (feixe concentrado)   •   %s: Sino da Névoa (puxa as brasas e cura). Use as três."
		args = { KEYS.a1, KEYS.a2, KEYS.a3 }
		padBody = "%s: Clarão (fere e atordoa em volta)   •   %s: Sobrecarga (feixe concentrado)   •   %s: Sino da Névoa (puxa as brasas e cura). Use as três."
		padArgs = { PAD.a1, PAD.a2, PAD.a3 }
		local n = 0
		for _ in self.used do
			n += 1
		end
		progress = string.format("%d / 3", n)
	elseif s == Step.THIEF then
		t = "6. Cuidado com a ladra"
		body = "A gaivota-fantasma não ataca o farol: ela rouba brasas soltas e foge para a névoa. Queime-a antes, e o roubo volta para você."
	elseif s == Step.MIRROR then
		t = "7. Luz refletida"
		body = "A ostra abissal fechada reflete a luz e fere o farol. Desvie o feixe e ataque quando ela abrir. O Clarão a abre na hora."
	elseif s == Step.BOSS then
		t = "8. Chefes"
		body = "À meia-noite e às 3h surgem chefes, sempre com um aviso vermelho antes. Cada um tem uma mecânica própria. Derrote este Leviatã enfraquecido: só a cabeça recebe dano, e ele mergulha de vez em quando."
	elseif s == Step.DONE then
		t = "Pronto!"
		body = "Na partida de verdade, resista até o amanhecer (06:00). Boa sorte, faroleiro."
	end
	self.text = { title = t, body = body, args = args, padBody = padBody, padArgs = padArgs, progress = progress, step = s }
	self.dirty = true
end

function Tutorial:tick(dt: number)
	local sim = self.sim
	self.timer += dt
	local s = self.step
	if s == Step.AIM then
		for _, b in sim.beams do
			if self.lastAim then
				self.turned += math.abs((b.angle - self.lastAim + math.pi) % (2 * math.pi) - math.pi)
			end
			self.lastAim = b.angle
			break
		end
		self:refresh()
		if self.turned >= TURN_GOAL then
			self:_enter(Step.BURN)
		end
	elseif s == Step.BURN or s == Step.EMBERS or s == Step.ABILITIES then
		-- Sempre há criaturas para praticar.
		if self:_alive() == 0 and self.timer > RESPAWN_DELAY then
			self.timer = 0
			self:_spawnRing("basic", if s == Step.ABILITIES then 6 else 3, 420)
		end
	elseif s == Step.MIRROR then
		if self:_alive() == 0 and self.timer > RESPAWN_DELAY then
			self.timer = 0
			self:_spawnRing("mirror", 1, 430)
		end
	elseif s == Step.DONE then
		if self.timer >= Balance.TUTORIAL_DONE_TIME then
			sim.finished = "tutorial"
		end
	end
end

function Tutorial:onKill(e)
	local s = self.step
	if s == Step.BURN then
		self.count += 1
		self:refresh()
		if self.count >= 3 then
			self:_enter(Step.EMBERS)
		end
	elseif s == Step.THIEF and e.kind == "thief" then
		self:_enter(Step.MIRROR)
	elseif s == Step.MIRROR and e.kind == "mirror" then
		self:_enter(Step.BOSS)
	elseif s == Step.BOSS and e.boss then
		self:_enter(Step.DONE)
	end
end

function Tutorial:onEmber()
	if self.step == Step.EMBERS then
		self.count += 1
		self:refresh()
		if self.count >= 4 then
			self:_enter(Step.LEVEL_UP)
		end
	end
end

function Tutorial:onUpgrade()
	if self.step == Step.LEVEL_UP then
		self:_enter(Step.ABILITIES)
	end
end

function Tutorial:onAbility(i: number)
	if self.step == Step.ABILITIES then
		self.used[i] = true
		self:refresh()
		local n = 0
		for _ in self.used do
			n += 1
		end
		if n >= 3 then
			self:_enter(Step.THIEF)
		end
	end
end

function Tutorial:onEscape(e)
	if self.step == Step.THIEF and e.kind == "thief" then
		self.sim:announce("Ela fugiu! Outra vem aí.", nil, nil, false)
		self:_spawnRing("thief", 1, 520)
		self:_dropEmbers(4)
	end
end

return Tutorial
