Write-Host "Updating all Chocolatey packages at: $([DateTime]::Now)"
choco upgrade all --svc -y
Exit $LASTEXITCODE