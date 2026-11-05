-- Kraken: fica na borda do mar sem se aproximar, lança tentáculos que rastejam
-- até o farol e cospe tinta que encurta os feixes por alguns segundos. Para
-- vencê-lo é preciso alcançar o corpo com a luz enquanto se defende.
-- visual: força do jato de tinta (255 logo após cuspir, decai).

local B = require(game:GetService("ReplicatedStorage"):WaitForChild("Fogkeeper"):WaitForChild("BossData"))

local Boss = {}

function Boss.begin(sim, e, angle: number)
	local d = e.boss
	B.place(e, angle, d.stand + 170)
	e.spawnCd = 1.5
	e.inkCd = d.inkEvery * 0.6
	e.inkFlash = 0
	e.visual = 0
end

function Boss.step(sim, e, dt: number)
	local d = e.boss
	e.inkFlash = math.max(0, e.inkFlash - dt * 1.5)
	e.visual = e.inkFlash * 255
	local dist = B.dist(e)
	if dist > d.stand + 0.5 then
		B.approach(e, d.stand, e.speed * dt)
		return
	end
	local r = e.rate()
	local fx, fy = -e.x / dist, -e.y / dist -- para o farol
	e.spawnCd -= dt * r
	if e.spawnCd <= 0 then
		e.spawnCd = d.spawnEvery
		local side = (sim.rng:NextNumber() * 2 - 1) * e.radius
		sim:spawnMinion("tentacle", e.x + fx * e.radius - fy * side, e.y + fy * e.radius + fx * side)
	end
	e.inkCd -= dt * r
	if e.inkCd <= 0 then
		e.inkCd = d.inkEvery
		e.inkFlash = 1
		sim:ink(d.inkTime, d.inkRange)
		sim:fx("ink", { x = e.x, y = e.y })
	end
end

return Boss
