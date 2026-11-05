# Sends every roblox/audio/*.ogg to Roblox through the Open Cloud Assets API
# and writes the resulting asset ids into roblox/src/shared/SoundIds.luau.
# Sounds that already have an id (not 0) in SoundIds.luau are skipped, so the
# script can be run again after a failure or when the monthly quota resets.
#
# Usage (from the repository root):
#   powershell -ExecutionPolicy Bypass -File roblox\tools\upload_audio.ps1 -ApiKey KEY -UserId 123
#   powershell -ExecutionPolicy Bypass -File roblox\tools\upload_audio.ps1 -ApiKey KEY -GroupId 456
# The key comes from Creator Dashboard > Open Cloud > API Keys, with the
# Assets API (read and write) for the same user or group that owns the game.
# ASCII only here: PowerShell 5.1 reads this file as ANSI.

param(
	[Parameter(Mandatory = $true)][string]$ApiKey,
	[long]$UserId = 0,
	[long]$GroupId = 0,
	[int]$PollSeconds = 2,
	[int]$PollTries = 60
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Add-Type -AssemblyName System.Net.Http

if (($UserId -le 0) -eq ($GroupId -le 0)) {
	Write-Error "Pass exactly one of -UserId or -GroupId (the owner of the experience)."
}

$root = Split-Path $PSScriptRoot -Parent
$audioDir = Join-Path $root "audio"
$idsPath = Join-Path $root "src\shared\SoundIds.luau"
$utf8 = New-Object System.Text.UTF8Encoding($false)
$base = "https://apis.roblox.com/assets/v1/"

if ($UserId -gt 0) {
	$creator = @{ userId = "$UserId" }
} else {
	$creator = @{ groupId = "$GroupId" }
}

$client = New-Object System.Net.Http.HttpClient
$client.Timeout = [TimeSpan]::FromMinutes(5)
$client.DefaultRequestHeaders.Add("x-api-key", $ApiKey)

function Read-Ids {
	return [System.IO.File]::ReadAllText($idsPath, [System.Text.Encoding]::UTF8)
}

# Current id of a sound in SoundIds.luau (0 if missing).
function Get-Id([string]$text, [string]$name) {
	$m = [regex]::Match($text, "(?m)^\s*" + [regex]::Escape($name) + "\s*=\s*(\d+)\s*,")
	if ($m.Success) { return [long]$m.Groups[1].Value }
	return -1
}

# Writes the id into its line ("name = 0," -> "name = 123,") and saves at once.
function Set-Id([string]$name, [string]$assetId) {
	$text = Read-Ids
	$pattern = "(?m)^(\s*" + [regex]::Escape($name) + "\s*=\s*)\d+(\s*,)"
	$new = [regex]::Replace($text, $pattern, "`${1}" + $assetId + "`${2}")
	[System.IO.File]::WriteAllText($idsPath, $new, $utf8)
}

# Sends the request and retries on 429/5xx. Returns the parsed JSON body.
function Send-Json([scriptblock]$makeRequest) {
	for ($try = 1; $try -le 5; $try++) {
		$req = & $makeRequest
		$res = $client.SendAsync($req).GetAwaiter().GetResult()
		$body = $res.Content.ReadAsStringAsync().GetAwaiter().GetResult()
		$code = [int]$res.StatusCode
		if ($res.IsSuccessStatusCode) {
			return ($body | ConvertFrom-Json)
		}
		if ($code -eq 429 -or $code -ge 500) {
			$wait = 5 * $try
			Write-Host "  HTTP $code, waiting $wait s and trying again..."
			Start-Sleep -Seconds $wait
			continue
		}
		throw "HTTP $code : $body"
	}
	throw "Gave up after several retries."
}

function Send-Audio([string]$path, [string]$name) {
	$meta = @{
		assetType = "Audio"
		displayName = "Fogkeeper $name"
		description = "Fogkeeper sound: $name"
		creationContext = @{ creator = $creator }
	} | ConvertTo-Json -Depth 5 -Compress
	$bytes = [System.IO.File]::ReadAllBytes($path)
	$op = Send-Json {
		$form = New-Object System.Net.Http.MultipartFormDataContent
		$form.Add((New-Object System.Net.Http.StringContent($meta, [System.Text.Encoding]::UTF8, "application/json")), "request")
		$file = New-Object System.Net.Http.ByteArrayContent(, $bytes)
		$file.Headers.ContentType = [System.Net.Http.Headers.MediaTypeHeaderValue]::Parse("audio/ogg")
		$form.Add($file, "fileContent", [System.IO.Path]::GetFileName($path))
		$req = New-Object System.Net.Http.HttpRequestMessage([System.Net.Http.HttpMethod]::Post, $base + "assets")
		$req.Content = $form
		$req
	}
	# The upload returns a long running operation; poll it until it is done.
	for ($i = 0; $i -lt $PollTries; $i++) {
		if ($op.done -and $op.response -and $op.response.assetId) {
			return [string]$op.response.assetId
		}
		if ($op.done -and $op.error) {
			throw ("Operation failed: " + ($op.error | ConvertTo-Json -Compress))
		}
		if (-not $op.path) {
			throw ("Unexpected answer: " + ($op | ConvertTo-Json -Compress))
		}
		Start-Sleep -Seconds $PollSeconds
		$opPath = $op.path
		$op = Send-Json {
			New-Object System.Net.Http.HttpRequestMessage([System.Net.Http.HttpMethod]::Get, $base + $opPath)
		}
	}
	throw "Operation $($op.path) did not finish in time; run the script again later."
}

$files = Get-ChildItem -Path $audioDir -Filter *.ogg | Sort-Object Name
$sent = 0
$skipped = 0
$failed = 0
foreach ($f in $files) {
	$name = [System.IO.Path]::GetFileNameWithoutExtension($f.Name)
	$id = Get-Id (Read-Ids) $name
	if ($id -lt 0) {
		Write-Host "$name : no line in SoundIds.luau, skipped (add '$name = 0,' first)."
		$skipped++
		continue
	}
	if ($id -gt 0) {
		$skipped++
		continue
	}
	Write-Host "$name : uploading..."
	try {
		$assetId = Send-Audio $f.FullName $name
		Set-Id $name $assetId
		Write-Host "$name : $assetId"
		$sent++
	} catch {
		Write-Host "$name : FAILED - $($_.Exception.Message)"
		$failed++
		if ("$($_.Exception.Message)" -match "quota|limit|exceed") {
			Write-Host "Upload quota reached; run again when it resets."
			break
		}
	}
}
$client.Dispose()
Write-Host ""
Write-Host "Sent: $sent  Already had id: $skipped  Failed: $failed"
Write-Host "Ids saved in $idsPath. Rebuild with roblox\build.ps1."
if ($failed -gt 0) { exit 1 }
