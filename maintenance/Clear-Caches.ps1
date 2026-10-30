[CmdletBinding(SupportsShouldProcess)]
param()

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$projectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$toolsRoot = [IO.Path]::GetFullPath((Join-Path $projectRoot 'tools'))
$toolsPrefix = $toolsRoot.TrimEnd([IO.Path]::DirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
$reclaimed = 0L

function Assert-LocalGeneratedPath([string]$Path) {
    $resolved = (Resolve-Path -LiteralPath $Path).Path
    if (-not $resolved.StartsWith($toolsPrefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw ('Refusing to modify a path outside tools: ' + $resolved)
    }
    # Do not follow junctions/symlinks out of the named workspace.
    $ancestor = if (Test-Path -LiteralPath $resolved -PathType Container) { $resolved } else { Split-Path -Parent $resolved }
    while ($ancestor.StartsWith($toolsRoot, [StringComparison]::OrdinalIgnoreCase)) {
        if (((Get-Item -LiteralPath $ancestor -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
            throw ('Refusing a generated path through a junction: ' + $ancestor)
        }
        if ($ancestor -eq $toolsRoot) { break }
        $ancestor = Split-Path -Parent $ancestor
    }
    return $resolved
}

if (Test-Path -LiteralPath $toolsRoot -PathType Container) {
    $caches = @(Get-ChildItem -LiteralPath $toolsRoot -Directory -Recurse -Filter shader_cache -Force)
    foreach ($cache in $caches) {
        $resolved = Assert-LocalGeneratedPath $cache.FullName
        $bytes = [long]((Get-ChildItem -LiteralPath $resolved -File -Recurse -Force | Measure-Object Length -Sum).Sum)
        if ($PSCmdlet.ShouldProcess($resolved, 'Remove regenerated test shader cache')) {
            Remove-Item -LiteralPath $resolved -Recurse -Force
            $reclaimed += $bytes
        }
    }
}

# Discard the download only if BOTH extracted executables match it byte-for-byte.
$download = Join-Path $toolsRoot 'godot.zip'
if (Test-Path -LiteralPath $download -PathType Leaf) {
    $resolved = Assert-LocalGeneratedPath $download
    $zip = [IO.Compression.ZipFile]::OpenRead($resolved)
    $redundant = $zip.Entries.Count -eq 2
    try {
        foreach ($entry in $zip.Entries) {
            if ($entry.FullName -notin @('Godot_v4.4.1-stable_win64.exe', 'Godot_v4.4.1-stable_win64_console.exe')) { $redundant = $false; break }
            $extracted = Join-Path (Join-Path $toolsRoot 'godot') $entry.FullName
            if (-not (Test-Path -LiteralPath $extracted -PathType Leaf)) { $redundant = $false; break }
            $entryStream = $entry.Open()
            $algorithm = [Security.Cryptography.SHA256]::Create()
            try { $entryHash = [BitConverter]::ToString($algorithm.ComputeHash($entryStream)).Replace('-', '') }
            finally { $entryStream.Dispose(); $algorithm.Dispose() }
            if ($entryHash -ne (Get-FileHash -LiteralPath $extracted -Algorithm SHA256).Hash) { $redundant = $false; break }
        }
    }
    finally { $zip.Dispose() }
    if ($redundant -and $PSCmdlet.ShouldProcess($resolved, 'Remove verified duplicate engine download')) {
        $bytes = (Get-Item -LiteralPath $resolved).Length
        Remove-Item -LiteralPath $resolved -Force
        $reclaimed += $bytes
    }
}
Write-Output ('Reclaimed {0:N2} MiB. Engine executables, profiles and screenshots were preserved.' -f ($reclaimed / 1MB))
