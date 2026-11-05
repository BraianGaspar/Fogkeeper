-- Melhorias oferecidas a cada nível e evoluções (scripts/core/upgrades.gd).
-- "own" = vale só para o feixe de quem escolheu; "shared" = vale para o
-- farol e para o time. Os níveis das compartilhadas somam as escolhas de todos.

local Upgrades = {}

Upgrades.LIST = {
	{ id = "wide_lens", scope = "own", max = 5, name = "Lente ampla", desc = "Feixe 20% mais largo." },
	{ id = "long_lens", scope = "own", max = 5, name = "Lente de longo alcance", desc = "Feixe alcança 15% mais longe." },
	{ id = "intense_flame", scope = "own", max = 6, name = "Chama intensa", desc = "Toda a luz causa 25% mais dano." },
	{ id = "gears", scope = "own", max = 4, name = "Engrenagens lubrificadas", desc = "O feixe gira 25% mais rápido." },
	{ id = "twin_lens", scope = "own", max = 3, name = "Lente extra", desc = "Adiciona mais um feixe, distribuído ao redor do farol." },
	{ id = "pulse", scope = "shared", max = 5, name = "Pulso de luz", desc = "Uma onda de luz periódica queima tudo ao redor." },
	{ id = "sweeper", scope = "own", max = 3, name = "Farolete giratório", desc = "Um feixe menor que gira sozinho." },
	{ id = "walls", scope = "shared", max = 4, name = "Paredes reforçadas", desc = "+25 de vida máxima e recupera 25." },
	{ id = "repairs", scope = "shared", max = 5, name = "Faroleiro dedicado", desc = "Regenera 0,6 de vida por segundo." },
	{ id = "magnet", scope = "shared", max = 3, name = "Correntes quentes", desc = "Brasas são puxadas de 40% mais longe." },
	{ id = "combustion", scope = "shared", max = 3, name = "Combustão", desc = "Criaturas queimadas explodem e ferem as vizinhas." },
	{ id = "vital_embers", scope = "shared", max = 3, name = "Brasas vitais", desc = "Cada brasa recolhida recupera 0,4 de vida." },
}

-- Evoluções: aparecem quando as duas melhorias de "needs" estão no máximo.
Upgrades.EVOLUTIONS = {
	{ id = "fresnel", scope = "own", max = 1, name = "Lente de Fresnel",
		desc = "O feixe principal arde em branco: +30% de dano e +25% de alcance.", needs = { "long_lens", "intense_flame" } },
	{ id = "crown", scope = "own", max = 1, name = "Coroa de Luz",
		desc = "Lentes extras causam dano total e o farolete ganha um segundo braço.", needs = { "twin_lens", "sweeper" } },
	{ id = "ember_tide", scope = "shared", max = 1, name = "Maré de Brasas",
		desc = "Cada pulso de luz puxa todas as brasas para o farol.", needs = { "pulse", "magnet" } },
	{ id = "bastion", scope = "shared", max = 1, name = "Bastião",
		desc = "+50 de vida máxima, cura total e regeneração dobrada.", needs = { "walls", "repairs" } },
	{ id = "fan", scope = "own", max = 1, name = "Leque de Luz",
		desc = "Feixe principal 50% mais largo e criaturas iluminadas ainda mais lentas.", needs = { "wide_lens", "gears" } },
}

Upgrades.FALLBACK = { id = "fresh_oil", scope = "shared", max = math.huge, name = "Óleo fresco", desc = "Recupera 30 de vida." }

local byId = {}
for _, u in Upgrades.LIST do
	byId[u.id] = u
end
for _, u in Upgrades.EVOLUTIONS do
	byId[u.id] = u
end
byId[Upgrades.FALLBACK.id] = Upgrades.FALLBACK

function Upgrades.find(id: string)
	return byId[id]
end

function Upgrades.isEvolution(id: string): boolean
	local u = byId[id]
	return u ~= nil and u.needs ~= nil
end

-- Nível atual de uma melhoria para um jogador (as compartilhadas são do time).
function Upgrades.level(id: string, own: { [string]: number }, shared: { [string]: number }): number
	local u = byId[id]
	if u and u.scope == "shared" then
		return shared[id] or 0
	end
	return own[id] or 0
end

-- Evoluções prontas para este jogador e ainda não escolhidas.
function Upgrades.readyEvolutions(own: { [string]: number }, shared: { [string]: number }): { string }
	local out = {}
	for _, e in Upgrades.EVOLUTIONS do
		if Upgrades.level(e.id, own, shared) == 0 then
			local ok = true
			for _, need in e.needs do
				if Upgrades.level(need, own, shared) < byId[need].max then
					ok = false
				end
			end
			if ok then
				table.insert(out, e.id)
			end
		end
	end
	return out
end

-- Sorteia `count` cartas: evoluções prontas primeiro; banidas e as ainda
-- bloqueadas (`unlocked(id)` falso) ficam de fora.
function Upgrades.roll(own: { [string]: number }, shared: { [string]: number }, rng: Random, count: number,
	banished: { [string]: boolean }?, unlocked: ((string) -> boolean)?): { string }
	local pool = {}
	for _, u in Upgrades.LIST do
		local allowed = (banished == nil or not banished[u.id]) and (unlocked == nil or unlocked(u.id))
		if allowed and Upgrades.level(u.id, own, shared) < u.max then
			table.insert(pool, u.id)
		end
	end
	for i = #pool, 2, -1 do
		local j = rng:NextInteger(1, i)
		pool[i], pool[j] = pool[j], pool[i]
	end
	local out = Upgrades.readyEvolutions(own, shared)
	for _, id in pool do
		table.insert(out, id)
	end
	while #out > count do
		table.remove(out)
	end
	if #out == 0 then
		out[1] = Upgrades.FALLBACK.id
	end
	return out
end

return Upgrades
