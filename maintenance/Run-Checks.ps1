[CmdletBinding()]
param([string]$Godot = $env:GODOT_BIN)

$ErrorActionPreference = 'Stop'
$projectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
if ([string]::IsNullOrWhiteSpace($Godot)) {
    $portable = Join-Path $projectRoot 'tools/godot/Godot_v4.4.1-stable_win64_console.exe'
    if (Test-Path -LiteralPath $portable -PathType Leaf) { $Godot = $portable }
    else {
        $installed = Get-Command godot, godot4 -ErrorAction SilentlyContinue | Select-Object -First 1
        if (-not $installed) { throw 'Install Godot 4.4+ or pass -Godot with its executable path.' }
        $Godot = $installed.Source
    }
}
$testData = Join-Path $projectRoot 'tools/check-data'
[IO.Directory]::CreateDirectory($testData) | Out-Null
$previousAppData = $env:APPDATA
$previousXdgData = $env:XDG_DATA_HOME
try {
    $env:APPDATA = $testData
    $env:XDG_DATA_HOME = $testData
    & $Godot --headless --editor --path $projectRoot --quit
    if ($LASTEXITCODE -ne 0) { throw 'Godot import failed.' }
    foreach ($scene in @('optimization', 'smoke', 'expansion', 'ui_expansion', 'art_contract')) {
        & $Godot --headless --path $projectRoot --fixed-fps 120 ('res://tests/' + $scene + '.tscn')
        if ($LASTEXITCODE -ne 0) { throw ('Checks failed: ' + $scene) }
    }
}
finally { $env:APPDATA = $previousAppData; $env:XDG_DATA_HOME = $previousXdgData }
