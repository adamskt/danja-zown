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

Import-Module posh-git

# oh-my-posh Options
Import-Module oh-my-posh
Set-PoshPrompt -Theme PowerLine

Import-Module PSColor

$global:PSColor.File.Hidden.Color = 'Gray'

# Borrowed from https://gist.github.com/jtucker/6886367fb58d5404032507576b43433f
$installPath = &"C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe" -prerelease -latest -property installationpath
$devShell = &"C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe" -prerelease -latest -find **\Microsoft.VisualStudio.DevShell.dll
Import-Module $devShell
Enter-VsDevShell -VsInstallPath $installPath -SkipAutomaticLocation -DevCmdArguments "-arch=amd64"

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

function Exterminate {
    [CmdletBinding(SupportsShouldProcess = $True)]
    Param($path = ".")
    Get-ChildItem -Path $path -Include bin,obj -Recurse | Remove-Item -Recurse -Force
}

function Show-AllColors {
  $colors = [enum]::GetValues([System.ConsoleColor])
  Foreach ($bgcolor in $colors) {
    Foreach ($fgcolor in $colors) { Write-Host "$fgcolor|"  -ForegroundColor $fgcolor -BackgroundColor $bgcolor -NoNewLine }
    Write-Host " on $bgcolor"
  }
}

function Show-FileInfo {
    Get-Item @args | Format-List
}

Set-Alias fi Show-FileInfo

function ll {
    Get-ChildItem -Force @args
  }

$global:CurrentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent()
if ($(New-Object Security.Principal.WindowsPrincipal( $global:CurrentUser )).IsInRole( [Security.Principal.WindowsBuiltInRole]::Administrator )) {
    $host.ui.rawui.WindowTitle = "* ADMINISTRATOR * " + $global:CurrentUser.Name + " @ " + [System.Net.Dns]::GetHostName() + " v" + $Host.Version + " - " + $env:PROCESSOR_ARCHITECTURE
} else {
    $host.ui.rawui.WindowTitle = $global:CurrentUser.Name + " @ " + [System.Net.Dns]::GetHostName() + " v" + $Host.Version + " - " + $env:PROCESSOR_ARCHITECTURE
}

# dotnet suggest script start
$availableToComplete = (dotnet-suggest list) | Out-String
$availableToCompleteArray = $availableToComplete.Split([Environment]::NewLine, [System.StringSplitOptions]::RemoveEmptyEntries)


    Register-ArgumentCompleter -Native -CommandName $availableToCompleteArray -ScriptBlock {
        param($wordToComplete, $commandAst, $cursorPosition)
        $fullpath = (Get-Command $commandAst.CommandElements[0]).Source

        $arguments = $commandAst.Extent.ToString().Replace('"', '\"')
        dotnet-suggest get -e $fullpath --position $cursorPosition -- "$arguments" | ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
        }
    }
$env:DOTNET_SUGGEST_SCRIPT_VERSION = "1.0.1"
# dotnet suggest script end

. D:\Dev\GitHub\ok-ps\Invoke-OKCommand.ps1