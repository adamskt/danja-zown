Write-Host "Updating all Powershell modules at: $([DateTime]::Now)"
Update-Module
Exit $LASTEXITCODE