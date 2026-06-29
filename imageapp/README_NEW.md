# CloudAndDevOps
Cloud and DevOps Project Work @ HS Aalen — Masters in Business Informatics (Summer Semester 2026)

---

## Prerequisites

Before running any scripts, ensure the following tools are installed and accessible via your system PATH:

- [Terraform](https://developer.hashicorp.com/terraform/install) 
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
- [PowerShell Core](https://github.com/PowerShell/PowerShell) if using linux/mac

You will also need:

- An active Azure subscription
- A **Service Principal** created in the Azure Portal (Microsoft Entra ID → App registrations → New registration), with a Client Secret generated under "Certificates & secrets". Note down the `appId`, `password`, `tenant` and your `subscriptionId`.
- A **`set-env.ps1`** file in the project root (based on `set-env.ps1.example`) with your Service Principal credentials filled in:

```powershell
$env:ARM_CLIENT_ID       = "your-app-id"
$env:ARM_CLIENT_SECRET   = "your-client-secret-value"
$env:ARM_TENANT_ID       = "your-tenant-id"
$env:ARM_SUBSCRIPTION_ID = "your-subscription-id"
```

This file is excluded from Git via `.gitignore` and must never be committed.

---

## How to Run with Powershell Scripts

All scripts are executed from the **project root** (`CloudAndDevOps/`).

### First-Time Setup (run once as admin)

```powershell
./setup.ps1
```

This script logs in as an admin via `az login`, creates a custom Azure role (`Key Vault RBAC Configurator`) and assigns it along with the `Contributor` role to the Service Principal. It then logs out and hands over to `init.ps1`.

### Infrastructure Initialisation

(should start automatically if you ran setup.ps1)
```powershell
./init.ps1 
```

Initialises the Bootstrap project (which creates the remote state backend), then initialises the imageapp Terraform project with the correct backend configuration. If ypu're using the Pipelines, you can stop here, Create the Infrastructure and Deployment Pipeline in Azure DevOps with the .yml files included in the root folder. If you use the pipeline, read the CI/CD PIpeline part of the README for further information 


After running this, execute `terraform apply` manually from the `imageapp/` folder:

```powershell
terraform apply -var-file="pipeline.tfvars"
```

### Application Deployment

```powershell
./deploy.ps1
```

Packages the app folder into a zip file and deploys it to Azure App Service. This script is intended as a **local fallback for development and testing**. The recommended and intended deployment method is the Azure DevOps Deployment Pipeline (`app-pipeline.yml`), which handles build and deployment automatically on every push to `main` that affects the `app/` folder.

**important:** If you want to run deploy.ps1 - make sure to change the resource group and name of the web-app based on your naming convention

### Changing the naming convention

If you intend to run this code yourself, replace the ID suffix (`wger-mfis`) in `imageapp/pipeline.tfvars` and `bootstrap/pipeline.tfvars` with your own initials to ensure globally unique resource names. See `naming_convention.md` for details.

---

## Project Structure

```
CloudAndDevOps/
├── bootstrap/          # Remote state backend infrastructure
├── imageapp/           # Main infrastructure (Terraform)
├── app/                # Python Flask web application
├── setup.ps1           # One-time admin setup script
├── init.ps1            # Infrastructure initialisation script
├── deploy.ps1          # Application deployment script
├── set-env.ps1         # Service Principal credentials (in .gitignore)
└── set-env.ps1.example # Template for set-env.ps1
```

---

## Infrastructure Description (Part I)

### Bootstrap

The `bootstrap/` folder contains a minimal Terraform project that creates the remote state backend — a Storage Account and Blob Container where the main project's `terraform.tfstate` is stored. This project itself uses local state (unavoidable, since the backend it creates does not yet exist at the time of execution). The Bootstrap project is initialised and applied automatically by `init.ps1`.

### providers.tf

Configures the `azurerm` provider with the required version (`~> 3.0`) and defines the remote backend (`azurerm`). Backend configuration values (resource group name, storage account name, container name, key) are injected at runtime via `-backend-config` parameters in `init.ps1`, so the backend block intentionally remains empty in the file.

### variables.tf / terraform.tfvars

`variables.tf` declares all input variables without default values, keeping it environment-agnostic. `pipeline.tfvars` provides the concrete values following the project naming convention. The `.tfvars` file is excluded from Git (`.gitignore`) as it contains environment-specific configuration. Anyone running this code must create their own `.tfvars` file — see the naming convention section.

### locals.tf

Defines constant values that do not change across environments (e.g. `os_type`, `account_replication_type`, `sku_name`, role names). Using `locals` avoids hardcoding these values directly in resource blocks and keeps them maintainable in a single place.

### resource_group.tf

Creates the main resource group. All other resources belong to this group. Using a dedicated resource group simplifies cost tracking, access management, and cleanup (`terraform destroy -var-file="pipeline.tfvars"` removes everything at once).

### storage_account.tf

Creates the Storage Account and the Blob Container inside it. Both are placed in the same file because the CORS rules (defined in `blob_properties`) and the container are tightly related to the storage account and are easier to understand together.

The `blob_properties` CORS rule restricts access to the Web App's domain (`allowed_origins`), so only browser requests originating from the App Service are permitted. The `allowed_origins` value references the App Service name variable directly, so no hardcoding is needed.

The container uses `container_access_type = "private"` — blobs are not publicly accessible. Downloads are served via time-limited SAS tokens generated by the application at runtime.

### key_vault.tf

Creates the Key Vault with RBAC authorization enabled (`enable_rbac_authorization = true`). Two role assignments are configured:

The `Admin` role assignment grants `Key Vault Administrator` permissions to the identity currently running Terraform (`data.azurerm_client_config.current.object_id`). This is dynamic — it resolves to whichever identity is authenticated at the time of `terraform apply`, whether a personal account or a Service Principal.

The `User` role assignment grants `Key Vault Secrets User` permissions to the Web App's System Assigned Managed Identity, so it can read the storage connection string at runtime.

The storage connection string is stored as a secret in the Key Vault and referenced in the App Service settings via a Key Vault Reference (`@Microsoft.KeyVault(...)`), so it is never exposed in code or configuration.

### app_service_plan.tf

Creates the App Service Plan (Linux, B1 tier). B1 is a paid Basic tier, chosen because the Free tier (F1) does not support Always-On, which causes Python apps to stop responding after inactivity.

### app_service.tf

Creates the Linux Web App. Key configuration:

- `identity { type = "SystemAssigned" }` — Azure automatically creates and manages an identity for the Web App, used to authenticate against the Key Vault.
- `python_version` is set via a local variable for maintainability.
- `app_settings` injects environment variables into the Python runtime, including the Key Vault Reference for the storage connection string and `SCM_DO_BUILD_DURING_DEPLOYMENT = true` to trigger Oryx to install Python dependencies on the server during deployment.

### outputs.tf

Returns the App Service URL after `terraform apply` so the web application is immediately accessible without navigating the Azure Portal.

---

## Authentication / Identity Context

Authentication in this project works on three levels:

**Terraform against Azure:** Terraform authenticates using a Service Principal via environment variables (`ARM_CLIENT_ID`, `ARM_CLIENT_SECRET`, `ARM_TENANT_ID`, `ARM_SUBSCRIPTION_ID`), set by `set-env.ps1`. This replaces the interactive `az login` approach used in the early development phase. The Service Principal holds the `Contributor` role (for resource creation) and a custom `Key Vault RBAC Configurator` role (for creating role assignments on the Key Vault) on the subscription.

**Web App against Key Vault:** The Web App authenticates using its System Assigned Managed Identity — an identity automatically created and managed by Azure, with no credentials to store or rotate. The Key Vault Access Policy grants this identity `Key Vault Secrets User` permissions (read-only). The Web App uses the Key Vault Reference in its `app_settings` to resolve the storage connection string at startup, so the secret never appears in code or configuration.

**Web App against Storage Account:** The Web App connects to the Storage Account using the connection string retrieved from the Key Vault. Download links are generated as time-limited SAS tokens (2 hours, read-only), so the Storage Account itself remains private at all times.

At the moment, the web application is publicly accessible to anyone with the URL. In a production environment, Azure App Service Authentication (Easy Auth) with Azure Active Directory login would be added to restrict access.

---

## CI/CD Pipelines (Part II)

### Infrastructure Pipeline (`infrastructure-pipeline.yml`)

Triggers on pushes to `main` that affect `imageapp/` or `bootstrap/`. Runs on a self-hosted Linux agent (Azure VM). Stages:

- **Init:** Runs Bootstrap (creates/verifies remote state backend), then initialises the imageapp Terraform project with backend configuration values from Azure DevOps Pipeline Variables.
- **Plan:** Runs `terraform plan` and publishes the plan file as a pipeline artifact.
- **Apply:** Downloads the plan artifact and runs `terraform apply` with the exact plan — no surprises.

Authentication against Azure is handled via an Azure DevOps Service Connection (`sc-imageapp-azure`) using the Service Principal credentials. The `AzureCLI@2` task with `addSpnToEnvironment: true` injects the `ARM_*` environment variables automatically.

### Deployment Pipeline (`deployment-pipeline.yml`)

Triggers on pushes to `main` that affect `app/`. Runs on the same self-hosted Linux agent. Stages:

- **Build:** Packages the `app/` folder into a zip file and publishes it as a pipeline artifact.
- **Deploy:** Downloads the artifact and deploys it to Azure App Service via the `AzureWebApp@1` task. Azure's Oryx build system installs Python dependencies server-side using `requirements.txt`.

### Self-Hosted Agent

Both pipelines run on a self-hosted Azure VM (`vm-imageapp-01-swec-mfis`, Ubuntu 22.04, B2ts_v2). A Microsoft-hosted agent was not used because free parallel jobs are not available for new Azure DevOps organisations.

The following tools must be installed manually on the agent VM before the pipelines can run:

```bash
# Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Terraform
sudo apt-get install -y gnupg software-properties-common
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt-get update && sudo apt-get install -y terraform

# pip and zip
sudo apt-get install -y python3-pip zip
```

These installations are performed manually rather than as pipeline steps because they are one-time setup tasks for the agent environment itself, not part of the build or deployment logic. Installing them on every pipeline run would add unnecessary overhead to each execution. On Microsoft-hosted agents, these tools would already be pre-installed; the manual setup is a direct consequence of using a self-hosted agent.

### Required Pipeline Variables

The following variables must be configured manually in Azure DevOps under **Pipelines → Edit → Variables** before running the pipelines:

| Variable | Used in | Description |
|---|---|---|
| `TF_BACKEND_RG` | Infrastructure Pipeline | Resource group of the Bootstrap Storage Account |
| `TF_BACKEND_SA` | Infrastructure Pipeline | Name of the Bootstrap Storage Account |
| `TF_BACKEND_CONTAINER` | Infrastructure Pipeline | Name of the tfstate container |
| `TF_BACKEND_KEY` | Infrastructure Pipeline | Name of the state file (e.g. `imageapp.tfstate`) |
| `APP_SERVICE_NAME` | Deployment Pipeline | Name of the Azure App Service |

The Service Principal credentials (`ARM_CLIENT_ID`, `ARM_CLIENT_SECRET`, `ARM_TENANT_ID`, `ARM_SUBSCRIPTION_ID`) are handled automatically via the Azure DevOps Service Connection (`sc-imageapp-azure`) and do not need to be added as pipeline variables.

---

## Application Description (Part II)

A Python Flask web application with two pages:

**Page 1 (`/`):** Lists all blobs in the Storage Account container with image thumbnails (with fallback icon for non-image files) and individual download links. Links are time-limited SAS tokens (2-hour expiry, read-only). A link to the upload page is displayed at the bottom.

**Page 2 (`/upload`):** Upload form supporting both click-to-select and drag-and-drop. Validates that the uploaded file is a genuine image using Pillow (`Image.verify()` + `Image.load()`). Returns an error message for invalid file types and for duplicate filenames (caught via `ResourceExistsError`). On success, displays a confirmation message.

---

## Out of Scope / Design Decisions

**Remote Backend:** The Terraform state for Bootstrap uses local state (unavoidable — it creates the backend itself). The imageapp state is stored remotely in the Bootstrap Storage Account. In a team environment, state locking and shared remote state are essential to avoid conflicts; for this single-person project, this setup is sufficient.

**Random Suffix:** Resource names use personal initials as a suffix (e.g. `kv-imageapp-01-wger-mfis`) instead of a `random_integer` or `random_string`. Random suffixes cause naming instability — each `terraform destroy` + `terraform apply` cycle could produce a different name, making resources harder to identify in the Portal and potentially causing conflicts. Initials are predictable, reproducible, and globally unique enough for this use case. Anyone running this code should replace the suffix with their own initials as described in the naming convention.

**Windows Agent:** The self-hosted pipeline agent runs Ubuntu 22.04 instead of Windows. A Windows agent would have allowed the PowerShell scripts (`init.ps1`, `deploy.ps1`) to be called directly from the pipeline YAML via `task: PowerShell@2`. On Linux, the equivalent logic was re-implemented as inline Bash in the YAML. Linux agents are the standard for CI/CD pipelines in production environments and are generally faster and more resource-efficient than Windows agents.

**PowerShell Scripts for Infrastructure:** The infrastructure pipeline (`infrastructure-pipeline.yml`) re-implements the logic of `init.ps1` directly in Bash rather than calling the PowerShell script. This is because the pipeline runs on a Linux agent and the scripts serve different purposes: the PowerShell scripts are intended for local/manual execution by a developer, while the pipeline YAML is the automated equivalent. Both approaches are valid; in a Windows-agent setup, the scripts could have been called directly.

**User Assigned Managed Identity:** The Web App uses a System Assigned Managed Identity rather than a User Assigned one. A User Assigned Identity was evaluated — it offers advantages in team scenarios (survives resource recreation, can be shared across multiple resources, enables group-based RBAC). However, the implementation introduced a dependency on manually creating an Azure AD Security Group (the `azuread` Terraform provider requires Entra ID directory role permissions not easily assignable to a Service Principal via standard CLI) and a Chicken-and-Egg problem: the group membership must be set manually after each `terraform apply`, since the identity only exists after the apply. For a single-resource, single-person project, the added complexity outweighs the benefit. In a production environment with multiple services needing Key Vault access, User Assigned Identity with group-based RBAC would be the correct approach.

**End-User Authentication:** The web application is publicly accessible to anyone with the URL. Azure App Service Authentication (Easy Auth) with Azure Active Directory was not implemented as it is not required by the project specification. In a production environment, this would be enabled to restrict access to authenticated users only.

**Azure AD Group for Managed Identity (manual step):** In a production setup, the Managed Identity would be added to a Security Group, and the Key Vault role assignment would target the group rather than the identity directly. This allows new services to be onboarded by adding them to the group without modifying role assignments. Automating group creation via Terraform requires the `azuread` provider and assigning Entra ID directory roles to the Service Principal via the Microsoft Graph API — a significantly more complex setup than standard Azure RBAC. For this project, the System Assigned Identity is assigned the Key Vault role directly.

---

## Naming Convention

Adapted from the official Microsoft naming convention best practices:
`https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-naming`

The naming pattern is:

```
{resource-type}-{project}-{number}-{region-initials}-{personal-id}
```

Storage Accounts follow a modified pattern (no hyphens allowed, max 24 characters, lowercase only):

```
st{project}{number}{region-initials}{personal-id}
```

Detailed examples are in `naming_convention.md` (excluded from Git via `.gitignore`).