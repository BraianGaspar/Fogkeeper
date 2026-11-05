-- Canais de rede e formato do Snapshot. O formato está descrito (e
-- congelado) em roblox/ARCHITECTURE.md; mudar aqui exige mudar lá.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Net = {}

local EVENTS = {
	Ability = "RemoteEvent", Pick = "RemoteEvent", Reroll = "RemoteEvent", Banish = "RemoteEvent", Lobby = "RemoteEvent",
	Snapshot = "RemoteEvent", Fx = "RemoteEvent", Announce = "RemoteEvent", Aim = "UnreliableRemoteEvent",
}

local folder: Folder

if RunService:IsServer() then
	folder = Instance.new("Folder")
	folder.Name = "FogkeeperNet"
	for name, class in EVENTS do
		local ev = Instance.new(class)
		ev.Name = name
		ev.Parent = folder
	end
	local state = Instance.new("Folder")
	state.Name = "State"
	state.Parent = folder
	folder.Parent = ReplicatedStorage
else
	folder = ReplicatedStorage:WaitForChild("FogkeeperNet") :: Folder
end

function Net.event(name: string): any
	return folder:WaitForChild(name)
end

function Net.state(): Folder
	return folder:WaitForChild("State") :: Folder
end

Net.FLAG_LIT = 1
Net.FLAG_STUNNED = 2
Net.FLAG_HIDDEN = 4
Net.FLAG_ELITE = 8
Net.FLAG_CHARMED = 16
Net.FLAG_REFLECTING = 32

local ENEMY_BYTES = 14
local EMBER_BYTES = 6
local DEATH_BYTES = 5
local TAU = 2 * math.pi

-- Índice de cada id de arte em Maps.ARTS (montado na primeira vez).
local artIndex: { [string]: number }? = nil
local arts: { string }? = nil

local function artTables()
	if not artIndex then
		local Maps = require(script.Parent:WaitForChild("Maps"))
		arts = Maps.ARTS
		artIndex = {}
		for i, id in Maps.ARTS do
			(artIndex :: any)[id] = i
		end
	end
	return artIndex :: { [string]: number }, arts :: { string }
end

local function clamp16(v: number): number
	if v ~= v then
		return 0 -- NaN não pode ir para o buffer
	end
	return math.clamp(math.round(v), -32768, 32767)
end

local function u8(v: number): number
	if v ~= v then
		return 0
	end
	return math.clamp(v, 0, 255)
end

local function flagsOf(e): number
	local f = 0
	if (e.lit or 0) > 0 then
		f += Net.FLAG_LIT
	end
	if (e.stun or 0) > 0 then
		f += Net.FLAG_STUNNED
	end
	if e.hidden then
		f += Net.FLAG_HIDDEN
	end
	if e.elite then
		f += Net.FLAG_ELITE
	end
	if e.charmed then
		f += Net.FLAG_CHARMED
	end
	if e.reflecting then
		f += Net.FLAG_REFLECTING
	end
	return f
end

function Net.encode(enemies: { any }, embers: { any }, deaths: { any }): buffer
	local index = artTables()
	local b = buffer.create(6 + #enemies * ENEMY_BYTES + #embers * EMBER_BYTES + #deaths * DEATH_BYTES)
	local o = 0
	buffer.writeu16(b, o, #enemies)
	o += 2
	for _, e in enemies do
		buffer.writeu16(b, o, e.id % 65536)
		buffer.writeu8(b, o + 2, index[e.art or e.kind] or 1)
		buffer.writei16(b, o + 3, clamp16(e.x))
		buffer.writei16(b, o + 5, clamp16(e.y))
		buffer.writeu8(b, o + 7, u8(math.round(e.hp / math.max(e.maxHp, 1e-6) * 255)))
		buffer.writeu8(b, o + 8, flagsOf(e))
		buffer.writeu8(b, o + 9, u8(math.floor(e.visual or 0)))
		buffer.writeu8(b, o + 10, u8(math.floor(e.aux or 0)))
		local facing = e.facing or math.atan2(-e.y, -e.x)
		if facing ~= facing or math.abs(facing) == math.huge then
			facing = 0
		end
		buffer.writeu16(b, o + 11, math.floor((facing % TAU) * 10000) % 65536)
		buffer.writeu8(b, o + 13, u8(math.round((e.scale or 1) * 50)))
		o += ENEMY_BYTES
	end
	buffer.writeu16(b, o, #embers)
	o += 2
	for _, m in embers do
		buffer.writeu16(b, o, m.id % 65536)
		buffer.writei16(b, o + 2, clamp16(m.x))
		buffer.writei16(b, o + 4, clamp16(m.y))
		o += EMBER_BYTES
	end
	buffer.writeu16(b, o, #deaths)
	o += 2
	for _, d in deaths do
		buffer.writei16(b, o, clamp16(d.x))
		buffer.writei16(b, o + 2, clamp16(d.y))
		buffer.writeu8(b, o + 4, if d.big then 1 else 0)
		o += DEATH_BYTES
	end
	return b
end

function Net.decode(b: buffer)
	local _, artList = artTables()
	local enemies, embers, deaths = {}, {}, {}
	local o = 0
	local n = buffer.readu16(b, o)
	o += 2
	for _ = 1, n do
		local flags = buffer.readu8(b, o + 8)
		table.insert(enemies, {
			id = buffer.readu16(b, o),
			art = artList[buffer.readu8(b, o + 2)] or "basic",
			x = buffer.readi16(b, o + 3),
			y = buffer.readi16(b, o + 5),
			hp = buffer.readu8(b, o + 7) / 255,
			lit = bit32.band(flags, Net.FLAG_LIT) ~= 0,
			stunned = bit32.band(flags, Net.FLAG_STUNNED) ~= 0,
			hidden = bit32.band(flags, Net.FLAG_HIDDEN) ~= 0,
			elite = bit32.band(flags, Net.FLAG_ELITE) ~= 0,
			charmed = bit32.band(flags, Net.FLAG_CHARMED) ~= 0,
			reflecting = bit32.band(flags, Net.FLAG_REFLECTING) ~= 0,
			visual = buffer.readu8(b, o + 9),
			aux = buffer.readu8(b, o + 10),
			facing = buffer.readu16(b, o + 11) / 10000,
			scale = buffer.readu8(b, o + 13) / 50,
		})
		o += ENEMY_BYTES
	end
	local m = buffer.readu16(b, o)
	o += 2
	for _ = 1, m do
		table.insert(embers, { id = buffer.readu16(b, o), x = buffer.readi16(b, o + 2), y = buffer.readi16(b, o + 4) })
		o += EMBER_BYTES
	end
	local k = buffer.readu16(b, o)
	o += 2
	for _ = 1, k do
		table.insert(deaths, { x = buffer.readi16(b, o), y = buffer.readi16(b, o + 2), big = buffer.readu8(b, o + 4) == 1 })
		o += DEATH_BYTES
	end
	return enemies, embers, deaths
end

return Net
