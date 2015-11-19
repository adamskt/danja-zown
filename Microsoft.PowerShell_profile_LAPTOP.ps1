#Rename-Item Function:\Prompt PoshGitPrompt -Force
#function Prompt() {if(Test-Path Function:\PrePoshGitPrompt){++$global:poshScope; New-Item function:\script:Write-host -value "param([object] `$object, `$backgroundColor, `$foregroundColor, [switch] `$nonewline) " -Force | Out-Null;$private:p = PrePoshGitPrompt; if(--$global:poshScope -eq 0) {Remove-Item function:\Write-Host -Force}}PoshGitPrompt}
#if(Test-Path Function:\Prompt) {Rename-Item Function:\Prompt PrePoshGitPrompt -Force}


# From chat with Ian Davis
function Get-Batchfile ($file) {
    $cmd = "`"$file`" & set"
    cmd /c $cmd | Foreach-Object {
        $p, $v = $_.split('=')
        Set-Item -path env:$p -value $v
    }
}
function Import-VsCommandLine()
{
    # $vscomntools = (Get-ChildItem env:VS120COMNTOOLS).Value
    $vscomntools = (Get-ChildItem env:VS140COMNTOOLS).Value
    $batchFile = [System.IO.Path]::Combine($vscomntools, "vsvars32.bat")
    Write-Output "Adding Visual Studio environment variables found in: $batchFile"
    Get-Batchfile $BatchFile
}
Import-VsCommandLine
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
#set-variable -name HOME -value (resolve-path $env:Home) -force
#(get-psprovider FileSystem).Home = $HOME

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
                  @{Name="SizeGB";Expression={($_.Size / 1GB).ToString("f3")}}, `
                  @{Name="FreeGB";Expression={($_.FreeSpace / 1GB).ToString("f3")}} `
        | Format-Table -AutoSize
}
Set-Alias df Get-DriveFreespace
# Preserve history across sessions
Register-EngineEvent PowerShell.Exiting {
    Get-History -Count 32767 | Group CommandLine | Foreach {$_.Group[0]} | Export-CliXml (Join-Path -Path $env:userprofile -ChildPath "Documents\pshist.xml")
} -SupportEvent
Import-CliXml (Join-Path -Path $env:userprofile -ChildPath "Documents\pshist.xml") | Add-History
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
    Get-ChildItem -Path $path -Include bin,obj -Recurse | Remove-Item -Recurse -Force
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

# Using https://github.com/joonro/Get-ChildItem-Color
$ScriptPath = Split-Path -parent $PSCommandPath
. "$ScriptPath\Get-ChildItem-Color\Get-ChildItem-Color.ps1"

Set-Alias -Name ls -Value Get-ChildItem-Format-Wide -Option AllScope
Set-Alias -Name ll -Value Get-ChildItem-Color -Option AllScope

cd $HOME

# Load posh-git example profile
. 'C:\Dev\Github\posh-git\profile.example.ps1'
