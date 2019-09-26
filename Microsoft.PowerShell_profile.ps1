# PSReadline Options
Set-PSReadlineOption -EditMode Vi -HistoryNoDuplicates
Set-PSReadlineOption -ViModeIndicator Cursor
Set-PSReadlineOption -Colors @{
  "Operator" = "$([char]0x1b)[32m"
  "Parameter" = "$([char]0x1b)[92m"
}

Set-PSReadlineKeyHandler -Chord UpArrow -Function HistorySearchBackward
Set-PSReadlineKeyHandler -Chord DownArrow -Function HistorySearchForward
Set-PSReadlineKeyHandler -Chord Ctrl+spacebar -Function PossibleCompletions

#$env:NAME = $env:COMPUTERNAME # Stupid fix because $PSVersionTable.Platform returns "Win32NT" not "Windows"

# oh-my-posh Options
Set-Theme Paradox

# PSColor options
Import-Module PSColor
$global:PSColor.File.Hidden.Color = 'Gray'

# Borrowed from https://gist.github.com/jtucker/6886367fb58d5404032507576b43433f
$installPath = &"C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe" -version 16.0 -property installationpath
Import-Module (Join-Path $installPath "Common7\Tools\Microsoft.VisualStudio.DevShell.dll")
Enter-VsDevShell -VsInstallPath $installPath -SkipAutomaticLocation

# Stolen from https://github.com/scottmuc/poshfiles/blob/master/Microsoft.PowerShell_profile.ps1
# inline functions, aliases and variables
function which($name) { Get-Command $name | Select-Object Definition }
function touch($file) { "" | Out-File $file -Encoding ASCII }

# get the syntax of a cmdlet, even if we have no help for it
function Get-Syntax([string] $cmdlet) {
  get-command $cmdlet -syntax
}

# Add a timestamp to tf get
function tfg { 
  tf get
  "Completed: " + $(Get-Date) 
}


# Pretty PATH variable
function Show-PathVariable {
  $env:path -split ';' | Sort-Object
}
Set-Alias spv Show-PathVariable

# Kill msbuilds
function killbld {
  taskkill /IM msbuild.exe /F
}

function Exterminate {
  [CmdletBinding(SupportsShouldProcess = $True)]
  Param($path = ".")
  Get-ChildItem -Path $path -Include bin, obj -Recurse | Remove-Item -Recurse -Force
}

# Chocolatey profile
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}

function ll {
  Get-ChildItem -Force @args
}

function Show-AllColors {
  $colors = [enum]::GetValues([System.ConsoleColor])
  Foreach ($bgcolor in $colors) {
    Foreach ($fgcolor in $colors) { Write-Host "$fgcolor|"  -ForegroundColor $fgcolor -BackgroundColor $bgcolor -NoNewLine }
    Write-Host " on $bgcolor"
  }
}

. C:\Dev\GitHub\ok-ps\_ok.ps1
