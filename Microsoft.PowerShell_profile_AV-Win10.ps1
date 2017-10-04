Import-Module PSReadline

Set-PSReadlineOption -EditMode Vi -HistoryNoDuplicates
Set-PSReadlineOption -ViModeIndicator Cursor

Set-PSReadlineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadlineKeyHandler -Key DownArrow -Function HistorySearchForward
Set-PSReadlineKeyHandler -Key Ctrl+Tab -Function PossibleCompletions

# This key handler shows the entire or filtered history using Out-GridView. The
# typed text is used as the substring pattern for filtering. A selected command
# is inserted to the command line without invoking. Multiple command selection
# is supported, e.g. selected by Ctrl + Click.
Set-PSReadlineKeyHandler -Key F7 `
  -BriefDescription History `
  -LongDescription 'Show command history' `
  -ScriptBlock {
  $pattern = $null
  [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$pattern, [ref]$null)
  if ($pattern) {
    $pattern = [regex]::Escape($pattern)
  }

  $history = [System.Collections.ArrayList]@(
    $last = ''
    $lines = ''
    foreach ($line in [System.IO.File]::ReadLines((Get-PSReadlineOption).HistorySavePath)) {
      if ($line.EndsWith('`')) {
        $line = $line.Substring(0, $line.Length - 1)
        $lines = if ($lines) {
          "$lines`n$line"
        } else {
          $line
        }
        continue
      }

      if ($lines) {
        $line = "$lines`n$line"
        $lines = ''
      }

      if (($line -cne $last) -and (!$pattern -or ($line -match $pattern))) {
        $last = $line
        $line
      }
    }
  )
  $history.Reverse()

  $command = $history | Out-GridView -Title History -PassThru
  if ($command) {
    [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
    [Microsoft.PowerShell.PSConsoleReadLine]::Insert(($command -join "`n"))
  }
}

# If module is installed in a default location ($env:PSModulePath),
# use this instead (see about_Modules for more information):
Import-Module posh-git

Import-Module PSColor

Import-Module pscx

Pop-Location

Invoke-BatchFile "C:\Program Files (x86)\Microsoft Visual Studio\2017\Enterprise\Common7\Tools\VsDevCmd.bat"

# Stolen from https://github.com/scottmuc/poshfiles/blob/master/Microsoft.PowerShell_profile.ps1
# inline functions, aliases and variables
function which($name) { Get-Command $name | Select-Object Definition }
function touch($file) { "" | Out-File $file -Encoding ASCII }

# FROM: https://github.com/tomasr/dotfiles/blob/master/.profile.ps1
#
# Set the $HOME variable for our use
# and make powershell recognize ~\ as $HOME
# in paths
#
set-variable -name HOME -value (resolve-path $env:USERPROFILE) -force
(get-psprovider FileSystem).Home = $HOME
Set-Location $HOME

# get the syntax of a cmdlet, even if we have no help for it
function Get-Syntax([string] $cmdlet) {
  get-command $cmdlet -syntax
}
function Get-DriveFreespace {
  Get-wmiObject -class "Win32_LogicalDisk" -namespace "root\CIMV2" -computername localhost `
    | Select  DeviceID, `
    VolumeName, `
    Description, `
    FileSystem, `
  @{Name = "SizeGB"; Expression = {($_.Size / 1GB).ToString("f3")}}, `
  @{Name = "FreeGB"; Expression = {($_.FreeSpace / 1GB).ToString("f3")}} `
    | Format-Table -AutoSize
}
Set-Alias df Get-DriveFreespace

# Pretty PATH variable
function Show-PathVariable {
    $env:path -split ';' | Sort-Object
}
Set-Alias spv Show-PathVariable
# Kill msbuilds
function killbld {
    taskkill /IM msbuild.exe /F
}
function Follow-Shortcut([string] $name) {
    $sh = New-Object -COM WScript.Shell
    cd $sh.CreateShortcut($("{0}\Links\{1}.lnk" -f $env:USERPROFILE, $name)).TargetPath
}

function Exterminate {
    [CmdletBinding(SupportsShouldProcess = $True)]
    Param($path = ".")
    Get-ChildItem -Path $path -Include bin, obj -Recurse | Remove-Item -Recurse -Force
}

Set-Alias -Name goto -Value Follow-Shortcut
function Invoke-WMSettingsChange() {
    if (-not ("win32.nativemethods" -as [type])) {
        # import sendmessagetimeout from win32
        add-type -Namespace Win32 -Name NativeMethods -MemberDefinition @"
[DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
public static extern IntPtr SendMessageTimeout(
    IntPtr hWnd, uint Msg, UIntPtr wParam, string lParam,
    uint fuFlags, uint uTimeout, out UIntPtr lpdwResult);
"@
    }
    $HWND_BROADCAST = [intptr]0xffff;
    $WM_SETTINGCHANGE = 0x1a;
    $result = [uintptr]::zero
    # notify all windows of environment block change
    [win32.nativemethods]::SendMessageTimeout($HWND_BROADCAST, $WM_SETTINGCHANGE,
        [uintptr]::Zero, "Environment", 2, 5000, [ref]$result);
}

# Chocolatey profile
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
    Import-Module "$ChocolateyProfile"
}

function ll {
  Get-ChildItem -Force @args
}

$env:BOS_DATABASE_SERVER="bunty,1401"
$env:BOS_DATABASE_USERNAME="sa"
$env:BOS_DATABASE_PASSWORD="Strong!P@ssword"
$env:BOS_DATABASE_NAME="bosdb-local"