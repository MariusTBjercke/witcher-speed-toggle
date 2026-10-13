# Builds dist\WitcherSpeedToggle-<version>.zip, laid out to extract straight into the game folder
# (Data\, System\, Optional\, README.txt). Entries use "/" separators so the zip also
# extracts correctly outside Windows (PowerShell 5.1's ZipFile writes "\").
param([string]$Version = "")

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot

if (-not $Version) {
    $Version = (Select-String -Path (Join-Path $root "CHANGELOG.md") -Pattern '^## (\d+\.\d+\.\d+)' |
        Select-Object -First 1).Matches[0].Groups[1].Value
}

# Published path in the zip -> source path in the repo.
$sources = [ordered]@{
    "README.txt" = "docs\README.txt"
    "Data"       = "mod\Data"
    "System"     = "mod\System"
    "Optional"   = "optional"
}

$dist = Join-Path $root "dist"
New-Item -ItemType Directory -Force -Path $dist | Out-Null
$zipPath = Join-Path $dist "WitcherSpeedToggle-$Version.zip"
if (Test-Path $zipPath) { Remove-Item $zipPath }

Add-Type -AssemblyName System.IO.Compression, System.IO.Compression.FileSystem
$zip = [System.IO.Compression.ZipFile]::Open($zipPath, [System.IO.Compression.ZipArchiveMode]::Create)
try {
    foreach ($entry in $sources.GetEnumerator()) {
        $src = Join-Path $root $entry.Value
        $files = if (Test-Path $src -PathType Leaf) { @(Get-Item $src) } else { Get-ChildItem $src -Recurse -File }
        foreach ($file in $files) {
            $relative = if (Test-Path $src -PathType Leaf) { "" } else { $file.FullName.Substring($src.Length).TrimStart('\') }
            $name = if ($relative) { "$($entry.Key)/$($relative -replace '\\', '/')" } else { $entry.Key }
            [void][System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $file.FullName, $name)
        }
    }
}
finally { $zip.Dispose() }

Write-Output "Built $zipPath"
