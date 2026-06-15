# CloudAndDevOps  <!-- FIXME: has to be reworked for Part II of the project  -->
Cloud and DevOps Project Work @ HS Aalen Masters in Business Informatics (Summersemester 2026)

## Prerequisites

You should have a working azure account, terraform, as well as azure cli installed. 
Terraform should be set up (installed & inside your PATH variable). 
You should be logged in via azure cli. 


## How to run 

1. navigate to the project folder within your Terminal (i use zsh on mac, powershell should hopefully work as well on Windows).
2. Take a look at the naming_convention.md file - if you intent to run the Code, please change the ID-Part of the naming convention for every resource in the terraform.tfvars file. 
3. if you have met the prerequisites, you should be able to run `terraform init` succesfully.
4. run `terraform plan` to see which resources will be created (if you've never ran this code before, resources should only be created, not changed or destroyed)
5. run `terraform apply` to execute the IaC & create the resources. Approve the enquiry. (This approach will be changed later, as there is no way to query user input within the pipeline)

## Approach / Description

### Main.tf
The main.tf file ensures that the Azure provider is used with the correct version. Also i could enable the purge on soft delete attribute for the key vault if i need to destroy my key vault again, since it would be safed for 90 days otherwise. 

### variables.tf 
The variables.tf file creates ‘dummy’ variables that do not yet contain any values (mostly names for referencing in the other files which are described below).


### terraform.tfvars 
is a (in my case) local file that populates the variables from variables.tf with content (most of the variables are names that follow my naming convention). The following files are all populated with the variables created here. the .tfvars as well as the .tfstate are in the .gitignore file since they are local and contain sensitive info. (It would be possible to put the .tfstate file in a container to create a remote backend, but since I'm the only one working on the project, this isn't needed. - it would be a smart thing to do it in a "real" environment with a team working on the project though)

### resource_group.tf
The file creates a resource group that will later contain the other resources (or maybe to be more exact - the resources will belong to the resource group that i create here). Variables are used for future referencing.


### storage_account.tf
Creates the storage account as well as the storage container inside of it. (I chose to put storage account and storage container inside of this one file, different from the lecture, because the blob-rules are stated within the account-creation and i thought it would be easier to understand, if these three objects were created/manipulated in the same script).  
The **blob_properties** set the rules for account sharing (The Browser checks, if the inquiry came from the web app, and if yes, it will be allowed access for reading and uploading files)    
The **container** can only be accessed privately, via the web app. 


### Key Vault
also belongs to the resource group and has several functions. In addition to the access policies (one for the admin – who authenticates using the current tenant_id of the Terraform user and thus has multiple permissions) and one for the web app, which is only permitted to retrieve data. Through the access policy with the object_id of the web app, the key vault knows whom to grant access. Furthermore, the Key Vault contains the connection string to the storage account, which then grants the web app access to the data within the storage account


### App service plan
Then there is the App Service plan, which contains the organisational details for the subsequent App Service or web app (atm set as free tier, maybe needs to be changed to a basic tier later on).


### App Service 
is part of the App Service plan and specifies further details for the web app. Among other things, it ensures that the web app is assigned its own Azure identity, which can access the information in the key vault with the permissions mentioned above. It also specifies which Python version is used to code the web app and which global variables from Terraform or Azure can be passed to the Python environment. 

### outputs.tf
Last but not least, there is outputs.tf, which simply returns the outputs I have entered there when `terraform apply` is executed (e.g. the URL of my web app so that I can access it).

## Authentification / Identity Context 

The authentification logic works as follows:
The Web App gets a managed identity by azure - this identity is used as authentification. The Key Vault has an access policy that states, that the web app is allowed to read secrets from the Key Vault. Inside of the Key Vault is the connection string for the storage account which contains the container which in itself contains the images later on. Thus the web app can access the storage account via the connection string and can authenticate itself against the key vault via the managed identity. 

Terraform uses az-login to authenticate itself against azure - so the user needs to interact with it. in a later stage this could be changed to a Service principal because user interaction isn't possible via the pipeline. 

At the moment, everyone with access to the url of the web app can access the images inside of the container - in a later stage or a real production environment i would create an active directory login for every user who wants to access the web page. 

## Out of Scope / Design Decisions

**Remote Backend:**
The Terraform state is stored locally instead of in a remote backend (e.g. an Azure Storage Account container). Since this is a single-person project, there is no need for shared state or state locking. 
In a team environment or a real-life scenario a remote backend would be essential to avoid state conflicts & to ensure the company is able to use the setup which I created, even if I leave the project or something similar. 

**PowerShell Scripts:**
The infrastructure is defined entirely via Terraform (IaC) without additional PowerShell scripts. Since Terraform already handles provisioning and configuration declaratively, 
PowerShell scripts would introduce redundancy. In a scenario where Terraform is not available, a remote backend or manual provisioning steps are required, PowerShell scripts would be the appropriate alternative.
Also - I work on Mac & isntalled terraform using an installer (homebrew). Terraform is automatically added to my PATH variable that way, so I don't need to do that via Powershell. 

**FIXMEs in the code:**
There are some parts marked as "FIXME" in the code. These will most likely be changed later on (Part II) in the project. I added them on purpose for future me. 

**Service Principal:**
At the moment, I do not use service principals. I prepared everything to use Service Principals for Part II of the project, 
but I will add the logic after we've learnt to do that within the Pipeline in a clean manner. 

## Naming Convention

adapted from the official naming convention best practices from microsoft (https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-naming)  

The Naming Convention and some examples are shown in naming_convention.md which is also inside of the gitignore file to mitigate risc.

