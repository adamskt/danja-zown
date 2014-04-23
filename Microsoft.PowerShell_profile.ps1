
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

function Get-DirSize
{
  param ($dir)
  $bytes = 0
  $count = 0

  Get-Childitem $dir | Foreach-Object {
    if ($_ -is [System.IO.FileInfo])
    {
      $bytes += $_.Length
      $count++
    }
  }

  Write-Host "`n    " -NoNewline

  if ($bytes -ge 1KB -and $bytes -lt 1MB)
  {
    Write-Host ("" + [Math]::Round(($bytes / 1KB), 2) + " KB") -ForegroundColor "White" -NoNewLine
  }
  elseif ($bytes -ge 1MB -and $bytes -lt 1GB)
  {
    Write-Host ("" + [Math]::Round(($bytes / 1MB), 2) + " MB") -ForegroundColor "White" -NoNewLine
  }
  elseif ($bytes -ge 1GB)
  {
    Write-Host ("" + [Math]::Round(($bytes / 1GB), 2) + " GB") -ForegroundColor "White" -NoNewLine
  }
  else
  {
    Write-Host ("" + $bytes + " bytes") -ForegroundColor "White" -NoNewLine
  }
  Write-Host " in " -NoNewline
  Write-Host $count -ForegroundColor "White" -NoNewline
  Write-Host " files"

}

function Get-DirWithSize
{
  param ($dir)
  Get-Childitem $dir
  Get-DirSize $dir
}

Remove-Item alias:dir
Remove-Item alias:ls
Set-Alias dir Get-DirWithSize
Set-Alias ls Get-DirWithSize



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


# Pretty PATH variable
function Show-PathVariable {
    $env:path -split ';' | Sort-Object
}

Set-Alias spv Show-PathVariable

# Kill msbuilds
function killbld {
    taskkill /IM msbuild.exe /F
}
