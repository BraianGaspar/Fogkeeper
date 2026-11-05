# Lista os textos visiveis da versao Roblox que nao tem traducao: o que passa
# por Text.t(, Text.format(, announce( e os campos name/desc/story/tagline/
# title/text/label/hint/caption/body de qualquer tabela em src (exceto I18n),
# alem das listas marcadas com "-- i18n" no fim da linha, comparado com shared/I18n/en.luau
# (traducoes do Godot) e shared/I18n/extra.luau.
# Uso: powershell -ExecutionPolicy Bypass -File roblox/tools/i18n_check.ps1
# Sai com codigo 1 se faltar algum texto.
# So ASCII aqui: o PowerShell 5.1 le este arquivo como ANSI.

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$src = Join-Path (Split-Path $PSScriptRoot -Parent) "src"
$str = '"((?:[^"\\]|\\.)*)"'

function Read-Text([string]$path) {
	return [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)
}

$known = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::Ordinal)
foreach ($file in @("shared/I18n/en.luau", "shared/I18n/extra.luau")) {
	foreach ($m in [regex]::Matches((Read-Text (Join-Path $src $file)), "\[$str\]\s*=")) {
		[void]$known.Add($m.Groups[1].Value)
	}
}

$used = New-Object 'System.Collections.Generic.SortedSet[string]' ([System.StringComparer]::Ordinal)
$calls = "(?:Text\.t|Text\.format|announce|FireAllClients)\(\s*$str"
foreach ($file in Get-ChildItem -Path $src -Recurse -Filter *.luau) {
	if ($file.FullName -like "*\I18n\*") { continue }
	foreach ($m in [regex]::Matches((Read-Text $file.FullName), $calls)) {
		[void]$used.Add($m.Groups[1].Value)
	}
}
$fields = "\b(?:name|desc|story|tagline|title|text|label|hint|caption|body)\s*=\s*$str"
foreach ($file in Get-ChildItem -Path $src -Recurse -Filter *.luau) {
	# Artes e cenarios usam name= para nomes internos de pecas, nao para texto.
	if ($file.FullName -like "*\I18n\*" -or $file.FullName -like "*\Art\*" -or $file.FullName -like "*\Scenery\*" -or $file.Name -eq "ArtKit.luau") { continue }
	foreach ($m in [regex]::Matches((Read-Text $file.FullName), $fields)) {
		[void]$used.Add($m.Groups[1].Value)
	}
}

# Linhas terminadas em "-- i18n": todas as strings da linha sao textos visiveis.
foreach ($file in Get-ChildItem -Path $src -Recurse -Filter *.luau) {
	if ($file.FullName -like "*\I18n\*") { continue }
	foreach ($line in (Read-Text $file.FullName) -split "`n") {
		if ($line.TrimEnd() -match "-- i18n$") {
			foreach ($m in [regex]::Matches($line, $str)) {
				[void]$used.Add($m.Groups[1].Value)
			}
		}
	}
}

# Nomes de teclas e botoes (T, LB, View, 1-4...) sao iguais em todos os idiomas.
$keyLabel = '^([A-Z0-9?]{1,2}|[0-9]-[0-9]|LB|RB|Esc|View|Menu)$'
$missing = @($used | Where-Object { $_ -ne "" -and $_ -notmatch $keyLabel -and -not $known.Contains($_) })
foreach ($s in $missing) {
	Write-Output $s
}
Write-Output ("{0} textos usados, {1} sem traducao" -f $used.Count, $missing.Count)
if ($missing.Count -gt 0) { exit 1 }
