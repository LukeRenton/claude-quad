[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Definition

$schemesToAdd = Get-Content -LiteralPath (Join-Path $here 'schemes.json') -Raw | ConvertFrom-Json
$profilesToAdd = Get-Content -LiteralPath (Join-Path $here 'profiles.json') -Raw | ConvertFrom-Json

# --- 1. Patch Windows Terminal settings.json ---
$packagedPath   = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'
$unpackagedPath = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows Terminal\settings.json'
$previewPath    = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json'

$settingsPath = $null
foreach ($p in @($packagedPath, $previewPath, $unpackagedPath)) {
    if (Test-Path -LiteralPath $p) { $settingsPath = $p; break }
}

if ($null -eq $settingsPath) {
    Write-Warning "Windows Terminal settings.json not found. Skipping wt config. Tried:"
    Write-Warning "  $packagedPath"
    Write-Warning "  $previewPath"
    Write-Warning "  $unpackagedPath"
} else {
    Write-Host "Using wt settings: $settingsPath"

    # Back up once
    $backupPath = "$settingsPath.claude-quad.bak"
    if (-not (Test-Path -LiteralPath $backupPath)) {
        Copy-Item -LiteralPath $settingsPath -Destination $backupPath -Force
        Write-Host "Created backup: $backupPath"
    } else {
        Write-Host "Backup already exists: $backupPath"
    }

    # Read + strip line comments (wt allows // comments which break ConvertFrom-Json)
    $raw = Get-Content -LiteralPath $settingsPath -Raw
    $jsonText = ($raw -split "`r?`n" | ForEach-Object { $_ -replace '^\s*//.*$', '' }) -join "`n"
    $settings = $jsonText | ConvertFrom-Json

    # Ensure schemes array
    if ($null -eq $settings.schemes) {
        Add-Member -InputObject $settings -NotePropertyName 'schemes' -NotePropertyValue @() -Force
    }
    $keepSchemes = @($settings.schemes | Where-Object { $_.name -notlike 'ClaudeQuad*' })
    $settings.schemes = @($keepSchemes) + @($schemesToAdd)

    # Ensure profiles + profiles.list
    if ($null -eq $settings.profiles) {
        Add-Member -InputObject $settings -NotePropertyName 'profiles' -NotePropertyValue ([pscustomobject]@{ list = @() }) -Force
    }
    if ($null -eq $settings.profiles.list) {
        Add-Member -InputObject $settings.profiles -NotePropertyName 'list' -NotePropertyValue @() -Force
    }
    $keepProfiles = @($settings.profiles.list | Where-Object { $_.name -notmatch '^claude-(general|ui|backend|research)$' })
    $settings.profiles.list = @($keepProfiles) + @($profilesToAdd)

    $out = $settings | ConvertTo-Json -Depth 64
    Set-Content -LiteralPath $settingsPath -Value $out -Encoding UTF8
    Write-Host "Patched $settingsPath with 4 schemes + 4 profiles."
}

# --- 2. Write HKCU registry entries ---
$scriptPath = (Join-Path $here 'claude-quad.ps1')
$icon = '%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe'

$cmdFolder     = "powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$scriptPath`" -FolderPath `"%1`""
$cmdBackground = "powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$scriptPath`" -FolderPath `"%V`""

function Set-ContextMenu {
    param([string]$BasePath, [string]$Command, [string]$DisplayName, [string]$IconValue)
    if (-not (Test-Path -LiteralPath $BasePath)) {
        New-Item -Path $BasePath -Force | Out-Null
    }
    Set-Item -LiteralPath $BasePath -Value $DisplayName
    New-ItemProperty -LiteralPath $BasePath -Name 'Icon' -Value $IconValue -PropertyType ExpandString -Force | Out-Null

    $cmdKey = Join-Path $BasePath 'command'
    if (-not (Test-Path -LiteralPath $cmdKey)) {
        New-Item -Path $cmdKey -Force | Out-Null
    }
    Set-Item -LiteralPath $cmdKey -Value $Command
}

Set-ContextMenu `
    -BasePath 'HKCU:\Software\Classes\Directory\shell\ClaudeQuad' `
    -Command  $cmdFolder `
    -DisplayName 'CLAUDE QUAD' `
    -IconValue $icon

Set-ContextMenu `
    -BasePath 'HKCU:\Software\Classes\Directory\Background\shell\ClaudeQuad' `
    -Command  $cmdBackground `
    -DisplayName 'CLAUDE QUAD' `
    -IconValue $icon

Write-Host ""
Write-Host "Installed. Right-click a folder (or empty space inside one) => Show more options => CLAUDE QUAD."
Write-Host "Restart Windows Terminal if it was already open before this install."
