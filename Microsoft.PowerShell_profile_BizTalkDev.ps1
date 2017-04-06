Import-Module pscx

Import-VisualStudioVars -VisualStudioVersion 120   

# Stolen from https://github.com/scottmuc/poshfiles/blob/master/Microsoft.PowerShell_profile.ps1
# inline functions, aliases and variables
function which($name) { Get-Command $name | Select-Object Definition }
function touch($file) { "" | Out-File $file -Encoding ASCII }
function ll { Get-ChildItem -Force }

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

function Get-AllBuildFolders([string] $root) {

    $search = [uri]::EscapeDataString("path:$($root) folder:Build child:Framework.ps1")
    $uri = "http://localhost:8081/?s=$($search)&j=1&c=255&path_column=1"

    $result = Invoke-RestMethod -Uri $uri
    return $result.results | % { Join-Path -Path $_.path -ChildPath $_.name  }
}

function Get-Workspace {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, Position=0)]
        [ValidateSet("D:\Calls\4_7\Dev", "D:\Calls\4_8\Dev", "D:\Calls\Dev", "D:\Calls\DPLOY\Dev", "D:\Calls\DSNR\Dev", "D:\Calls\MDM\Dev", "D:\Calls\PHX\Dev")]
        [string]
        $branch
    )
    DynamicParam {
        $ParameterName = 'workspace'

        $attribute = new-object System.Management.Automation.ParameterAttribute
        $attribute.ParameterSetName = "__AllParameterSets"
        $attribute.Mandatory = $true
        $attribute.Position = 1

        $attributeCollection = new-object -Type System.Collections.ObjectModel.Collection[System.Attribute]
        $attributeCollection.Add($attribute)
        
        $values = Get-AllBuildFolders($branch)

        $ValidateSet = new-object System.Management.Automation.ValidateSetAttribute($values)
        $attributeCollection.Add($ValidateSet)

        $dynParam1 = new-object -Type System.Management.Automation.RuntimeDefinedParameter($ParameterName, [string], $attributeCollection)
        $paramDictionary = new-object -Type System.Management.Automation.RuntimeDefinedParameterDictionary
        $paramDictionary.Add($ParameterName, $dynParam1)

        return $paramDictionary 

    }
    begin {
        $ws = $PSBoundParameters[$ParameterName]
    }
    process {
        Set-Location $ws
    }

    end {}
}

Set-Alias goto Get-Workspace

function studio { ./Framework.ps1 -studio }
function build([switch]$propagate) { ./Framework.ps1 -build @PSBoundParameters }
function test([switch]$propagate) { ./Framework.ps1 -test @PSBoundParameters }
function deploy([switch]$propagate) { ./Framework.ps1 -deploy @PSBoundParameters }
function install([switch]$propagate) { ./Framework.ps1 -install @PSBoundParameters }
function undeploy([switch]$propagate) { ./Framework.ps1 -undeploy @PSBoundParameters }
function uninstall([switch]$propagate) { ./Framework.ps1 -uninstall @PSBoundParameters }

function setup { ./Framework.ps1 -setup }

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
    param (
        [Parameter(ValueFromPipeline = $true)]
        [string]$Path = ".",
        [switch]$Force        
            )

    begin {
        $PSBoundParameters.Remove('Force') | Out-Null
        $PSBoundParameters.Confirm = $false
    }
    
    process {
        if ($Force -or $PSCmdlet.ShouldProcess($Path, "Exterminate binaries")) {
            Get-ChildItem -Path $Path -Include bin,obj -Recurse | Remove-Item -Recurse
        }
    }
}

# Chocolatey profile
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}



[System.Net.WebRequest]::DefaultWebProxy.Credentials = [System.Net.CredentialCache]::DefaultCredentials


Import-Module posh-git

Import-Module D:\Calls\Tools\LogExplorer\Search-Log.psm1
