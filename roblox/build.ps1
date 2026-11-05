# Monta roblox/build/Fogkeeper.rbxlx a partir de roblox/src, no mesmo formato
# do Rojo (default.project.json), sem precisar instalar nada:
#   src/shared -> ReplicatedStorage.Fogkeeper
#   src/server -> ServerScriptService.Fogkeeper
#   src/client -> StarterPlayer.StarterPlayerScripts.Fogkeeper
#   Nome.server.luau = Script, Nome.client.luau = LocalScript, Nome.luau = ModuleScript
# Uso (PowerShell): powershell -ExecutionPolicy Bypass -File roblox/build.ps1
# Depois abra o arquivo gerado no Roblox Studio (File > Open from File).

$ErrorActionPreference = "Stop"
$root = $PSScriptRoot
$src = Join-Path $root "src"
$out = Join-Path $root "build"
$script:ref = 0

function New-Ref {
	$script:ref += 1
	return "RBX{0:X8}" -f $script:ref
}

function Escape-Xml([string]$s) {
	return [System.Security.SecurityElement]::Escape($s)
}

function Script-Item([System.IO.FileInfo]$file) {
	$name = $file.Name
	if ($name.EndsWith(".server.luau")) { $class = "Script"; $name = $name.Substring(0, $name.Length - 12) }
	elseif ($name.EndsWith(".client.luau")) { $class = "LocalScript"; $name = $name.Substring(0, $name.Length - 12) }
	else { $class = "ModuleScript"; $name = $name.Substring(0, $name.Length - 5) }
	$source = [System.IO.File]::ReadAllText($file.FullName, [System.Text.Encoding]::UTF8)
	$source = $source.Replace("]]>", "]]]]><![CDATA[>")
	return "<Item class=`"$class`" referent=`"$(New-Ref)`"><Properties><string name=`"Name`">$(Escape-Xml $name)</string>" +
		"<ProtectedString name=`"Source`"><![CDATA[$source]]></ProtectedString></Properties></Item>"
}

function Folder-Item([string]$dir, [string]$name) {
	$items = @()
	foreach ($sub in Get-ChildItem -Path $dir -Directory | Sort-Object Name) {
		$items += Folder-Item $sub.FullName $sub.Name
	}
	foreach ($file in Get-ChildItem -Path $dir -File -Filter *.luau | Sort-Object Name) {
		$items += Script-Item $file
	}
	return "<Item class=`"Folder`" referent=`"$(New-Ref)`"><Properties><string name=`"Name`">$(Escape-Xml $name)</string></Properties>" +
		($items -join "") + "</Item>"
}

function Service([string]$class, [string]$inner, [string]$props = "") {
	return "<Item class=`"$class`" referent=`"$(New-Ref)`"><Properties><string name=`"Name`">$class</string>$props</Properties>$inner</Item>"
}

$shared = Folder-Item (Join-Path $src "shared") "Fogkeeper"
$server = Folder-Item (Join-Path $src "server") "Fogkeeper"
$client = Folder-Item (Join-Path $src "client") "Fogkeeper"
$playerScripts = "<Item class=`"StarterPlayerScripts`" referent=`"$(New-Ref)`"><Properties><string name=`"Name`">StarterPlayerScripts</string></Properties>$client</Item>"

# Lighting.Technology nao e scriptavel: fica gravada aqui. Enum.Technology:
# Legacy = 0, Voxel = 1, Compatibility = 2, ShadowMap = 3, Future = 4.
# O resto da luz (sombras, ceu, efeitos) e ligado por server/World.luau.
$lightingProps = '<token name="Technology">4</token><bool name="GlobalShadows">true</bool>'

$xml = '<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" ' +
	'xsi:noNamespaceSchemaLocation="http://www.roblox.com/roblox.xsd" version="4">' +
	(Service "Workspace" "") +
	(Service "Lighting" "" $lightingProps) +
	(Service "Players" "" '<bool name="CharacterAutoLoads">true</bool>') +
	(Service "ReplicatedStorage" $shared) +
	(Service "ServerScriptService" $server) +
	(Service "StarterPlayer" $playerScripts) +
	'</roblox>'

New-Item -ItemType Directory -Force -Path $out | Out-Null
$target = Join-Path $out "Fogkeeper.rbxlx"
[System.IO.File]::WriteAllText($target, $xml, (New-Object System.Text.UTF8Encoding $false))
Write-Output "Gerado: $target"
