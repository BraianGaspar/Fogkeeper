-- Jötunn: gigante de gelo. Para a certa distância e arremessa pedras de gelo,
-- que são criaturas: queime-as no ar antes que atinjam o farol. A cada
-- arremesso ele dá alguns passos à frente, até alcançar a ilha e esmagá-la.
-- visual: preparo do arremesso (0..255).

local B = require(game:GetService("ReplicatedStorage"):WaitForChild("Fogkeeper"):WaitForChild("BossData"))

local Boss = {}

function Boss.begin(sim, e, angle: number)
	B.place(e, angle, 430)
	e.stand = e.boss.stand
	e.throwCd = 2
	e.visual = 0
end

function Boss.step(sim, e, dt: number)
	local d = e.boss
	local r = e.rate()
	local reach = B.reach(e)
	local dist = B.dist(e)
	if dist > e.stand + 0.5 then
		B.approach(e, math.max(e.stand, reach), e.speed * r * e.litFactor() * dt)
	else
		e.throwCd -= dt * r
		if e.throwCd <= 0 then
			e.throwCd = d.throwEvery
			local fx, fy = -e.x / dist, -e.y / dist
			sim:spawnMinion("boulder", e.x + fx * e.radius * 1.3, e.y + fy * e.radius * 1.3)
			sim:fx("sfx", { id = "throw", x = e.x, y = e.y })
			e.stand = math.max(reach, e.stand - d.advance)
		end
	end
	e.visual = (1 - math.clamp(e.throwCd / d.throwEvery, 0, 1)) * 255
	B.melee(sim, e, dt)
end

return Boss
