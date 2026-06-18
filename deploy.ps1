# Manual Deployment Script for the Image App Web App
# Packages the app folder, then deploys it to the Azure App Service via Azure CLI.
#
# Prerequisites:
#   - Azure CLI installed and logged in (az login)
#   - Zip is available (e.g. via winget, brew, or preinstalled on Linux/Mac)
#
# Required parameters:
#   -AppServiceName   Name of the target Azure App Service
#   -ResourceGroup    Name of the resource group containing the App Service
#
# Usage example:
#   ./deploy.ps1 -AppServiceName "app-imageapp-01-wger-mfis" -ResourceGroup "rg-imageapp-01-wger-mfis"

param (
    [Parameter(Mandatory = $true)]
    [string]$AppServiceName,

    [Parameter(Mandatory = $true)]
    [string]$ResourceGroup
)

$zip_path = "./app.zip"
$app_folder = "./app"

# Package the app folder into a zip file
Write-Host "Packaging app folder..."
Compress-Archive -Path "$app_folder/*" -DestinationPath $zip_path -Force

# Deploy the zip package to the Azure App Service
Write-Host "Deploying to App Service: $AppServiceName..."
az webapp deploy `
    --resource-group $ResourceGroup `
    --name $AppServiceName `
    --src-path $zip_path `
    --type zip

# Clean up the zip file
Remove-Item $zip_path
Write-Host "Deployment complete."