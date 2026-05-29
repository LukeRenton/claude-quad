[CmdletBinding()]
param()

$ErrorActionPreference = 'Continue'

# --- 1. Remove HKCU registry entries ---
foreach ($key in @(
    'HKCU:\Software\Classes\Directory\shell\ClaudeQuad',
    'HKCU:\Software\Classes\Directory\Background\shell\ClaudeQuad'
)) {
    if (Test-Path -LiteralPath $key) {
        Remove-Item -LiteralPath $key -Recurse -Force
        Write-Host "Removed $key"
    } else {
        Write-Host "Not present: $key"
    }
}

# --- 2. Strip schemes + profiles from settings.json ---
$packagedPath   = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'
$unpackagedPath = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows Terminal\settings.json'
$previewPath    = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json'

$settingsPath = $null
foreach ($p in @($packagedPath, $previewPath, $unpackagedPath)) {
    if (Test-Path -LiteralPath $p) { $settingsPath = $p; break }
}

if ($null -eq $settingsPath) {
    Write-Warning "Windows Terminal settings.json not found. Nothing to clean up there."
} else {
    Write-Host "Cleaning wt settings: $settingsPath"
    $raw = Get-Content -LiteralPath $settingsPath -Raw
    $jsonText = ($raw -split "`r?`n" | ForEach-Object { $_ -replace '^\s*//.*$', '' }) -join "`n"
    $settings = $jsonText | ConvertFrom-Json

    if ($null -ne $settings.schemes) {
        $settings.schemes = @($settings.schemes | Where-Object { $_.name -notlike 'ClaudeQuad*' })
    }
    if ($null -ne $settings.profiles -and $null -ne $settings.profiles.list) {
        $settings.profiles.list = @($settings.profiles.list | Where-Object { $_.name -notmatch '^claude-(general|ui|backend|research)$' })
    }

    $out = $settings | ConvertTo-Json -Depth 64
    Set-Content -LiteralPath $settingsPath -Value $out -Encoding UTF8
    Write-Host "Removed ClaudeQuad schemes and profiles. Backup at: $settingsPath.claude-quad.bak (left in place)."
}

Write-Host ""
Write-Host "Uninstall complete."
