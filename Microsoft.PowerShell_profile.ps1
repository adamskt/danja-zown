
# Load posh-git example profile
. 'C:\tools\poshgit\dahlbyk-posh-git-22f4e77\profile.example.ps1'


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
    $vs120comntools = (Get-ChildItem env:VS120COMNTOOLS).Value
    $batchFile = [System.IO.Path]::Combine($vs120comntools, "vsvars32.bat")
    Write-Output "Adding Visual Studio environment variables found in: $batchFile"
    Get-Batchfile $BatchFile
}

Import-VsCommandLine


### FROM: http://avinmathew.com/coloured-directory-listings-in-powershell/
$env:Path += ";$(Split-Path $profile)\Scripts"

New-CommandWrapper Out-Default -Process {
  $regex_opts = ([System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
  $compressed = New-Object System.Text.RegularExpressions.Regex(
    '\.(zip|tar|gz|rar|jar|war)$', $regex_opts)
  $executable = New-Object System.Text.RegularExpressions.Regex(
    '\.(exe|bat|cmd|msi|ps1|psm1|vbs|reg)$', $regex_opts)

  if(($_ -is [System.IO.DirectoryInfo]) -or ($_ -is [System.IO.FileInfo]))
  {
    if(-not ($notfirst))
    {
      Write-Host "`n    Directory: " -noNewLine
      Write-Host "$(pwd)`n" -foregroundcolor "Cyan"
      Write-Host "Mode        Last Write Time       Length   Name"
      Write-Host "----        ---------------       ------   ----"
      $notfirst=$true
    }

    if ($_ -is [System.IO.DirectoryInfo])
    {
      Write-Host ("{0}   {1}                {2}" -f $_.mode, ([String]::Format("{0,10} {1,8}", $_.LastWriteTime.ToString("d"), $_.LastWriteTime.ToString("t"))), $_.name) -ForegroundColor "Cyan"
    }
    else
    {
      if ($compressed.IsMatch($_.Name))
      {
        $color = "DarkGreen"
      }
      elseif ($executable.IsMatch($_.Name))
      {
        $color =  "Red"
      }
      else
      {
        $color = "White"
      }
      Write-Host ("{0}   {1}   {2,10}   {3}" -f $_.mode, ([String]::Format("{0,10} {1,8}", $_.LastWriteTime.ToString("d"), $_.LastWriteTime.ToString("t"))), $_.length, $_.name) -ForegroundColor $color
    }

    $_ = $null
  }
} -end {
  Write-Host
}

# Using https://github.com/joonro/Get-ChildItem-Color
$ScriptPath = Split-Path -parent $PSCommandPath
. "$ScriptPath\Get-ChildItem-Color\Get-ChildItem-Color.ps1"

Set-Alias -Name ls -Value Get-ChildItem-Format-Wide -Option AllScope
Set-Alias -Name ll -Value Get-ChildItem-Color -Option AllScope


# FROM: https://github.com/tomasr/dotfiles/blob/master/.profile.ps1
#
# Set the $HOME variable for our use
# and make powershell recognize ~\ as $HOME
# in paths
#
set-variable -name HOME -value (resolve-path $env:Home) -force
(get-psprovider FileSystem).Home = $HOME

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

# Stolen from https://github.com/scottmuc/poshfiles/blob/master/Microsoft.PowerShell_profile.ps1
# inline functions, aliases and variables
function which($name) { Get-Command $name | Select-Object Definition }
function touch($file) { "" | Out-File $file -Encoding ASCII }

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

Set-Alias goto Follow-Shortcut

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