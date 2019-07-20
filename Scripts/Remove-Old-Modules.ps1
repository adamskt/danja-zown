# From http://sharepointjack.com/2017/powershell-script-to-remove-duplicate-old-modules/

Write-Host "this will remove all old versions of installed modules"
write-host "be sure to run this as an admin" -foregroundcolor yellow
write-host "(You can update all your Azure RM modules with update-module Azurerm -force)"
 
$mods = Get-InstalledModule
 
foreach ($Mod in $mods) {
  write-host "Checking $($mod.name)"
  $latest = get-installedmodule $mod.name
  $specificmods = get-installedmodule $mod.name -allversions
  write-host "$($specificmods.count) versions of this module found [ $($mod.name) ]"
  
  foreach ($sm in $specificmods) {
    if ($sm.version -ne $latest.version) {
      write-host "uninstalling $($sm.name) - $($sm.version) [latest is $($latest.version)]"
      $sm | uninstall-module -force
      write-host "done uninstalling $($sm.name) - $($sm.version)"
      write-host "    --------"
    }
	
  }
  write-host "------------------------"
}
write-host "done"