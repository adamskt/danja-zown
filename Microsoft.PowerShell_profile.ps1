#Import-Module PSConsoleTheme
#Set-ConsoleTheme "Solarized Dark"

# Powershell 6 config
Import-Module PSReadline

Set-PSReadlineOption -EditMode Vi -HistoryNoDuplicates
Set-PSReadlineOption -ViModeIndicator Cursor

Set-PSReadlineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadlineKeyHandler -Key DownArrow -Function HistorySearchForward
Set-PSReadlineKeyHandler -Key Ctrl+Tab -Function PossibleCompletions

# If module is installed in a default location ($env:PSModulePath),
# use this instead (see about_Modules for more information):
Import-Module posh-git

$env:NAME = $env:COMPUTERNAME # Stupid fix because $PSVersionTable.Platform returns "Win32NT" not "Windows"
Import-Module oh-my-posh
Set-Theme Agnoster

Import-Module PSColor

$global:PSColor.File.Hidden.Color = 'Gray'

Import-Module pscx

Pop-Location

Invoke-BatchFile "C:\Program Files (x86)\Microsoft Visual Studio\2017\Enterprise\Common7\Tools\VsDevCmd.bat"

# Stolen from https://github.com/scottmuc/poshfiles/blob/master/Microsoft.PowerShell_profile.ps1
# inline functions, aliases and variables
function which($name) { Get-Command $name | Select-Object Definition }
function touch($file) { "" | Out-File $file -Encoding ASCII }

# get the syntax of a cmdlet, even if we have no help for it
function Get-Syntax([string] $cmdlet) {
  get-command $cmdlet -syntax
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

Set-Location C:\Dev