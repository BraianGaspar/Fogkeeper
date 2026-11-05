-- Traduções em 9 idiomas. A chave é o texto em português (como no Fogkeeper
-- em Godot). Os idiomas ficam em shared/I18n/<código>.luau, gerados por
-- roblox/tools/i18n.ps1 a partir do Godot; textos só da versão Roblox ficam
-- em shared/I18n/extra.luau. O que faltar num idioma cai no inglês e, por
-- último, no português.

local Text = {}

-- Idiomas na ordem da tela de configurações: {código, nome nativo}.
Text.LANGUAGES = {
	{ "pt_BR", "Português" }, { "en", "English" }, { "es", "Español" }, { "fr", "Français" }, { "de", "Deutsch" },
	{ "ru", "Русский" }, { "zh_CN", "简体中文" }, { "ja", "日本語" }, { "ko", "한국어" },
}

-- Códigos do Roblox (LocalizationService.RobloxLocaleId) e do Godot -> código interno.
local ALIASES = {
	pt = "pt_BR", pt_br = "pt_BR", en = "en", es = "es", fr = "fr", de = "de", ru = "ru",
	zh = "zh_CN", zh_cn = "zh_CN", zh_hans = "zh_CN", ja = "ja", ko = "ko",
}

local folder = script.Parent:WaitForChild("I18n")
local extra = require(folder:WaitForChild("extra"))
local tables: { [string]: { [string]: string } } = {}
local current = "pt_BR"

-- Tabela de um idioma, carregada na primeira vez que for usada.
local function tableOf(code: string): { [string]: string }
	local t = tables[code]
	if not t then
		t = {}
		local module = folder:FindFirstChild(code)
		if module then
			local ok, loaded = pcall(require, module)
			if ok and type(loaded) == "table" then
				t = loaded
			end
		end
		tables[code] = t
	end
	return t
end

-- Aceita "pt-br", "en-us", "zh-hans", "pt_BR", "zh_CN"... Desconhecido = inglês.
function Text.setLocale(code: string)
	local key = string.gsub(string.lower(code or ""), "-", "_")
	current = ALIASES[key] or ALIASES[string.sub(key, 1, 2)] or "en"
	if key == "zh_tw" or key == "zh_hant" then
		current = "zh_CN" -- não há chinês tradicional; o simplificado é o mais próximo
	end
end

function Text.locale(): string
	return current
end

local function lookup(code: string, pt: string): string?
	local s = tableOf(code)[pt]
	if s then
		return s
	end
	local e = extra[pt]
	return if e then e[code] else nil
end

function Text.t(pt: string): string
	if current == "pt_BR" or type(pt) ~= "string" then
		return pt
	end
	return lookup(current, pt) or lookup("en", pt) or pt
end

-- Traduz o texto e os argumentos que também forem textos conhecidos.
function Text.format(pt: string, args: { any }?): string
	local out = {}
	local n = 0
	for i, a in args or {} do
		out[i] = if type(a) == "string" then Text.t(a) else a
		n = math.max(n, i)
	end
	return string.format(Text.t(pt), table.unpack(out, 1, n))
end

return Text
