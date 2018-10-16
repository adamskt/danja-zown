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

# Stolen from https://github.com/scottmuc/poshfiles/blob/master/Microsoft.PowerShell_profile.ps1
# inline functions, aliases and variables
function which($name) { Get-Command $name | Select-Object Definition }
function touch($file) { "" | Out-File $file -Encoding ASCII }

# get the syntax of a cmdlet, even if we have no help for it
function Get-Syntax([string] $cmdlet) {
  get-command $cmdlet -syntax
}

function ll {
  Get-ChildItem -Force @args
}

