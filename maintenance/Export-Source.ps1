[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$projectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$outputRoot = Join-Path $projectRoot 'dist'
[IO.Directory]::CreateDirectory($outputRoot) | Out-Null
[IO.File]::WriteAllText((Join-Path $outputRoot '.gdignore'), '')
$archivePath = Join-Path $outputRoot 'MarbleOverdrive-source.zip'
$temporaryPath = Join-Path $outputRoot 'MarbleOverdrive-source.zip.tmp'

# Deliberate allowlist: generated caches, profiles, engines and screenshots
# can never enter the archive just because they happen to be in the workspace.
$sourceDirectories = @('scenes', 'scripts', 'shaders', 'localization', 'tests', 'maintenance', 'docs', 'assets', 'addons', '.github')
$sourceFiles = [Collections.Generic.List[IO.FileInfo]]::new()
foreach ($directory in $sourceDirectories) {
    $sourcePath = Join-Path $projectRoot $directory
    if (Test-Path -LiteralPath $sourcePath -PathType Container) {
        foreach ($file in Get-ChildItem -LiteralPath $sourcePath -File -Recurse -Force) {
            $relative = $file.FullName.Substring($projectRoot.Length + 1).Replace('\', '/')
            if ($relative -notmatch '(^|/)(\.git|\.godot|__pycache__)(/|$)' -and $file.Extension -notin @('.tmp', '.log')) {
                $sourceFiles.Add($file)
            }
        }
    }
}
foreach ($name in @('project.godot', 'Play.cmd', 'icon.svg', 'icon.svg.import', '.gitignore', '.gitattributes', '.editorconfig', 'export_presets.cfg')) {
    $sourcePath = Join-Path $projectRoot $name
    if (Test-Path -LiteralPath $sourcePath -PathType Leaf) { $sourceFiles.Add((Get-Item -LiteralPath $sourcePath)) }
}
foreach ($file in Get-ChildItem -LiteralPath $projectRoot -File -Force) {
    if ($file.Extension -eq '.md' -or $file.Name -match '^(LICENSE|NOTICE)(\.|$)') { $sourceFiles.Add($file) }
}
$sourceFiles.Add((Get-Item -LiteralPath (Join-Path $projectRoot 'tools/.gdignore')))

$entries = @($sourceFiles | Sort-Object FullName -Unique | ForEach-Object {
    [pscustomobject]@{
        Path = $_.FullName.Substring($projectRoot.Length + 1).Replace('\', '/')
        Bytes = $_.Length
        SHA256 = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
    }
} | Sort-Object Path)
$stream = [IO.File]::Open($temporaryPath, [IO.FileMode]::Create)
try {
    $zip = [IO.Compression.ZipArchive]::new($stream, [IO.Compression.ZipArchiveMode]::Create, $true)
    try {
        foreach ($file in $entries) {
            $entry = $zip.CreateEntry('MarbleOverdrive/' + $file.Path, [IO.Compression.CompressionLevel]::Optimal)
            $entry.LastWriteTime = [DateTimeOffset]::new(2000, 1, 1, 0, 0, 0, [TimeSpan]::Zero)
            $entryStream = $entry.Open()
            $inputStream = [IO.File]::OpenRead((Join-Path $projectRoot $file.Path))
            try { $inputStream.CopyTo($entryStream) }
            finally { $inputStream.Dispose(); $entryStream.Dispose() }
        }
    }
    finally { $zip.Dispose() }
}
finally { $stream.Dispose() }
Move-Item -LiteralPath $temporaryPath -Destination $archivePath -Force
$sourceBytes = [long](($entries | Measure-Object Bytes -Sum).Sum)
$manifest = [ordered]@{
    Archive = 'MarbleOverdrive-source.zip'
    SHA256 = (Get-FileHash -LiteralPath $archivePath -Algorithm SHA256).Hash.ToLowerInvariant()
    SourceBytes = $sourceBytes
    ArchiveBytes = (Get-Item -LiteralPath $archivePath).Length
    FileCount = $entries.Count
    Files = $entries
}
$json = $manifest | ConvertTo-Json -Depth 6
[IO.File]::WriteAllText((Join-Path $outputRoot 'source-manifest.json'), $json, [Text.UTF8Encoding]::new($false))
Write-Output ('Source: {0:N1} KiB / {1} files' -f ($sourceBytes / 1KB), $entries.Count)
Write-Output ('GitHub ZIP: {0:N1} KiB' -f ($manifest.ArchiveBytes / 1KB))
Write-Output $archivePath
