# Gera roblox/src/shared/I18n/{en,es,fr,de,ru,zh_CN,ja,ko}.luau a partir das
# traduções do Fogkeeper em Godot:
#   scripts/core/i18n.gd     I18n.TEXTS = {"pt": ["en", "es"], ...}
#   scripts/i18n/<lang>.gd   const T := {"pt": "tradução", ...}
# As strings são copiadas como estão (os escapes do GDScript usados ali, como
# \" e \n, valem igual em Luau). Saída ordenada, UTF-8 sem BOM.
# Uso: powershell -ExecutionPolicy Bypass -File roblox/tools/i18n.ps1

$ErrorActionPreference = "Stop"
$repo = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$out = Join-Path $repo "roblox/src/shared/I18n"
$utf8 = New-Object System.Text.UTF8Encoding $false
$str = '"((?:[^"\\]|\\.)*)"'

function Read-Text([string]$path) {
	return [System.IO.File]::ReadAllText((Join-Path $repo $path), [System.Text.Encoding]::UTF8)
}

function Write-Lang([string]$code, [hashtable]$table) {
	$lines = New-Object System.Collections.Generic.List[string]
	# Só ASCII aqui: o PowerShell 5.1 lê este arquivo como ANSI.
	$lines.Add("-- Gerado por roblox/tools/i18n.ps1 a partir das traducoes do Godot; edite la e rode de novo.")
	$lines.Add("return {")
	foreach ($key in ($table.Keys | Sort-Object -CaseSensitive)) {
		$lines.Add("`t[`"$key`"] = `"$($table[$key])`",")
	}
	$lines.Add("}")
	[System.IO.File]::WriteAllText((Join-Path $out "$code.luau"), ($lines -join "`n") + "`n", $utf8)
	Write-Output ("{0}: {1} textos" -f $code, $table.Count)
}

New-Item -ItemType Directory -Force -Path $out | Out-Null

# Inglês e espanhol: entradas "pt": ["en", "es"] dentro de TEXTS (podem quebrar linha).
$core = Read-Text "scripts/core/i18n.gd"
$start = $core.IndexOf("const TEXTS := {")
$body = $core.Substring($start)
$body = $body.Substring(0, [regex]::Match($body, "(?m)^}").Index)
$en = New-Object System.Collections.Hashtable ([System.StringComparer]::Ordinal)
$es = New-Object System.Collections.Hashtable ([System.StringComparer]::Ordinal)
$pattern = "$str\s*:\s*\[\s*$str\s*,\s*$str\s*,?\s*\]"
foreach ($m in [regex]::Matches($body, $pattern)) {
	$en[$m.Groups[1].Value] = $m.Groups[2].Value
	$es[$m.Groups[1].Value] = $m.Groups[3].Value
}
Write-Lang "en" $en
Write-Lang "es" $es

# Demais idiomas: const T := {"pt": "tradução"}.
foreach ($code in @("fr", "de", "ru", "zh_CN", "ja", "ko")) {
	$text = Read-Text "scripts/i18n/$code.gd"
	$table = New-Object System.Collections.Hashtable ([System.StringComparer]::Ordinal)
	foreach ($m in [regex]::Matches($text, "$str\s*:\s*$str")) {
		$table[$m.Groups[1].Value] = $m.Groups[2].Value
	}
	Write-Lang $code $table
}
