# deploy.ps1
# Deploys the app code to Azure App Service
# Run from the root of the project (CloudAndDevOps/)

. ./set-env.ps1

Write-Host "Logging in as Service Principal..."
az login --service-principal `
  --username $env:ARM_CLIENT_ID `
  --password $env:ARM_CLIENT_SECRET `
  --tenant $env:ARM_TENANT_ID

Write-Host "Installing dependencies..."
pip install -r app/requirements.txt --target app/.python_packages/lib/site-packages

Write-Host "Zipping app folder..."
Compress-Archive -Path "app/*" -DestinationPath "app.zip" -Force

Write-Host "Triggering remote build during deployment..."
az webapp deploy `
  --resource-group "rg-imageapp-01-wger-mfis" `
  --name "app-imageapp-01-wger-mfis" `
  --src-path "app.zip" `
  --type zip `
  --async true

# Restart to trigger Oryx build
az webapp restart `
  --resource-group "rg-imageapp-01-wger-mfis" `
  --name "app-imageapp-01-wger-mfis"