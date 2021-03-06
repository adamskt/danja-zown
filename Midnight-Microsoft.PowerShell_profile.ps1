#Set-Alias git 'C:\Program Files\Git\bin\git.exe' 

# If module is installed in a default location ($env:PSModulePath),
# use this instead (see about_Modules for more information):
Import-Module posh-git

Import-Module PSColor

$global:PSColor.File.Hidden.Color = 'Gray'

# Borrowed from https://gist.github.com/jtucker/6886367fb58d5404032507576b43433f
$installPath = &"C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe" -version 16.0 -property installationpath
Import-Module (Join-Path $installPath "Common7\Tools\vsdevshell\Microsoft.VisualStudio.DevShell.dll")
Enter-VsDevShell -VsInstallPath $installPath -SkipAutomaticLocation

# Stolen from https://github.com/scottmuc/poshfiles/blob/master/Microsoft.PowerShell_profile.ps1
# inline functions, aliases and variables
function which($name) { Get-Command $name | Select-Object Definition }
function touch($file) { "" | Out-File $file -Encoding ASCII }


# get the syntax of a cmdlet, even if we have no help for it
function Get-Syntax([string] $cmdlet) {
   get-command $cmdlet -syntax
}
function Get-DriveFreespace {
    Get-wmiObject -class "Win32_LogicalDisk" -namespace "root\CIMV2" -computername localhost `
        | Select-Object  DeviceID, `
                  VolumeName, `
                  Description, `
                  FileSystem, `
                  @{Name="SizeGB";Expression={($_.Size / 1GB).ToString("f3")}}, `
                  @{Name="FreeGB";Expression={($_.FreeSpace / 1GB).ToString("f3")}} `
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
# function Follow-Shortcut([string] $name) {
#     $sh = New-Object -COM WScript.Shell
#     cd $sh.CreateShortcut($("{0}\Links\{1}.lnk" -f $env:USERPROFILE, $name)).TargetPath
# }

function Exterminate {
    [CmdletBinding(SupportsShouldProcess = $True)]
    Param($path = ".")
    Get-ChildItem -Path $path -Include bin,obj -Recurse | Remove-Item -Recurse -Force
}

function ll {
    Get-ChildItem -Force @args
  }

# Set-Alias -Name goto -Value Follow-Shortcut
# function Invoke-WMSettingsChange() {
#     if (-not ("win32.nativemethods" -as [type])) {
#         # import sendmessagetimeout from win32
#         add-type -Namespace Win32 -Name NativeMethods -MemberDefinition @"
# [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
# public static extern IntPtr SendMessageTimeout(
#     IntPtr hWnd, uint Msg, UIntPtr wParam, string lParam,
#     uint fuFlags, uint uTimeout, out UIntPtr lpdwResult);
# "@
#     }
#     $HWND_BROADCAST = [intptr]0xffff;
#     $WM_SETTINGCHANGE = 0x1a;
#     $result = [uintptr]::zero
#     # notify all windows of environment block change
#     [win32.nativemethods]::SendMessageTimeout($HWND_BROADCAST, $WM_SETTINGCHANGE,
#     [uintptr]::Zero, "Environment", 2, 5000, [ref]$result);
# }


$global:CurrentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent()
if ($(New-Object Security.Principal.WindowsPrincipal( $global:CurrentUser )).IsInRole( [Security.Principal.WindowsBuiltInRole]::Administrator )) {
    $host.ui.rawui.WindowTitle = "* ADMINISTRATOR * " + $global:CurrentUser.Name + " @ " + [System.Net.Dns]::GetHostName() + " v" + $Host.Version + " - " + $env:PROCESSOR_ARCHITECTURE
} else {
    $host.ui.rawui.WindowTitle = $global:CurrentUser.Name + " @ " + [System.Net.Dns]::GetHostName() + " v" + $Host.Version + " - " + $env:PROCESSOR_ARCHITECTURE
}

# Chocolatey profile
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}
. D:\Dev\GitHub\ok-ps\_ok.ps1