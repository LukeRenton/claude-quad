[CmdletBinding()]
param(
    [string]$FolderPath = $env:USERPROFILE
)

if ([string]::IsNullOrWhiteSpace($FolderPath) -or -not (Test-Path -LiteralPath $FolderPath)) {
    $FolderPath = $env:USERPROFILE
}
$FolderPath = (Resolve-Path -LiteralPath $FolderPath).Path

$qPath = '"' + $FolderPath + '"'

# Unique window name so subsequent wt invocations can target this exact window.
$windowName = "claude-quad-$([guid]::NewGuid().ToString('N').Substring(0,8))"

# Step 1: open the window already maximized with just pane 1 (general).
# -M maximizes at creation, so we never resize a half-constructed window
# mid-split. Each subsequent split is its own wt invocation, spaced out, so
# wt's UI thread isn't trying to lay out 4 panes while 4 `claude` processes
# all boot at the same moment.
[void][System.Diagnostics.Process]::Start('wt.exe', "-w $windowName -M new-tab -d $qPath -p claude-general --title CLAUDE-general powershell.exe -NoExit -Command claude")
Start-Sleep -Seconds 2

# Step 2: pane 2 (UI) on the right.
[void][System.Diagnostics.Process]::Start('wt.exe', "-w $windowName split-pane -V --size 0.5 -d $qPath -p claude-ui --title CLAUDE-UI powershell.exe -NoExit -Command claude")
Start-Sleep -Milliseconds 1500

# Step 3: pane 3 (backend) below general.
[void][System.Diagnostics.Process]::Start('wt.exe', "-w $windowName move-focus left ; split-pane -H --size 0.5 -d $qPath -p claude-backend --title CLAUDE-backend powershell.exe -NoExit -Command claude")
Start-Sleep -Milliseconds 1500

# Step 4: pane 4 (research) below UI.
[void][System.Diagnostics.Process]::Start('wt.exe', "-w $windowName move-focus right ; split-pane -H --size 0.5 -d $qPath -p claude-research --title CLAUDE-research powershell.exe -NoExit -Command claude")
