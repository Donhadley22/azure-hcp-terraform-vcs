# azure-hcp-terraform-vcs

Deploy Azure infrastructure with Terraform using a GitHub VCS-backed HCP Terraform workspace.

This repository provisions a small Azure lab environment made up of a resource group, virtual network, subnet, public IP address, network interface, network security group, and Ubuntu Linux virtual machine. The screenshots in this guide were captured during the project setup on June 4, 2026 and show the full flow from GitHub repository creation to HCP Terraform runs and cleanup.

## Architecture

```mermaid
flowchart LR
    github["GitHub repository"] --> hcp["HCP Terraform workspace"]
    hcp --> azurerm["AzureRM provider"]
    azurerm --> rg["Azure resource group"]
    rg --> vnet["Virtual network"]
    vnet --> subnet["Subnet"]
    subnet --> nic["Network interface"]
    nic --> vm["Linux virtual machine"]
    rg --> nsg["Network security group"]
    nsg --> nic
    rg --> pip["Static public IP"]
    pip --> nic
```

## What Gets Created

| Terraform resource | Purpose |
| --- | --- |
| `azurerm_resource_group.rg` | Container for all demo resources |
| `azurerm_virtual_network.vnet` | Azure virtual network |
| `azurerm_subnet.subnet` | Subnet inside the virtual network |
| `azurerm_network_security_group.nsg` | Allows inbound SSH traffic on port 22 |
| `azurerm_public_ip.public_ip` | Static public IP for the VM |
| `azurerm_network_interface.nic` | VM network interface |
| `azurerm_network_interface_security_group_association.nsg_association` | Attaches the NSG to the NIC |
| `azurerm_linux_virtual_machine.vm` | Ubuntu 24.04 LTS virtual machine |

The HCP Terraform plan captured in the screenshots shows 8 resources planned and created.

![HCP Terraform plan showing 8 Azure resources](docs/images/16-hcp-plan-eight-resources.png)

## Repository Structure

```text
.
|-- main.tf              # Azure resources
|-- providers.tf         # Terraform and AzureRM provider requirements
|-- variables.tf         # Input variable declarations
|-- outputs.tf           # Resource group, VM name, and public IP outputs
|-- .gitignore           # Ignores state, .terraform, tfvars, and local files
|-- docs/images/         # Screenshots used by this README
|-- LICENSE
`-- README.md
```

## Prerequisites

- GitHub account and repository access.
- HCP Terraform account and organization.
- Azure subscription.
- Azure identity or app registration with permission to create the resources in this configuration.
- Terraform CLI `>= 1.6.0` for local validation.
- SSH public key for VM login.

The project was validated locally with Terraform `1.15.5` and AzureRM provider `4.75.0`.

## GitHub Setup

Create a GitHub repository named `azure-hcp-terraform-vcs`. The original setup used a public repository, added a Terraform `.gitignore`, added a README, and selected the MIT license.

![Create the GitHub repository](docs/images/01-github-create-repository.png)

Clone the repository locally, add the Terraform files, commit them, and push to GitHub.

![Clone and push Terraform code](docs/images/02-git-clone-and-push.png)

The pushed repository should contain the Terraform configuration files.

![Terraform project files in GitHub](docs/images/04-github-repository-files.png)

## Terraform Configuration

The provider block in `providers.tf` pins the AzureRM provider to the `4.x` major version:

```hcl
terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
}
```

The main configuration creates a public Ubuntu VM:

- VM size: `Standard_D2s_v3`
- OS image: Canonical Ubuntu 24.04 LTS
- OS disk: `Standard_LRS`
- Public IP: static, Standard SKU
- SSH: allowed inbound on TCP port `22`

> Security note: this lab currently allows SSH from any source address. For production or long-running environments, restrict `source_address_prefix` to a trusted IP range, use Azure Bastion, or remove the public IP path.

## Input Variables

| Variable | Type | Example value | Description |
| --- | --- | --- | --- |
| `resource_group_name` | `string` | `rg-hcp-terraform-demo` | Azure resource group name |
| `location` | `string` | `westeurope` | Azure region |
| `vnet_name` | `string` | `vnet-hcp-demo` | Virtual network name |
| `vnet_address_space` | `list(string)` | `["10.0.0.0/16"]` | VNet CIDR range |
| `subnet_name` | `string` | `subnet-hcp-demo` | Subnet name |
| `subnet_address_prefixes` | `list(string)` | `["10.0.1.0/24"]` | Subnet CIDR range |
| `vm_name` | `string` | `vm-hcp-demo` | Linux VM name |
| `admin_username` | `string` | `azureuser` | VM admin username |
| `public_key` | `string` | `ssh-rsa ...` | SSH public key content |

For local runs, create a `terraform.tfvars` file. This file is ignored by Git because it can contain environment-specific values and sensitive material.

```hcl
resource_group_name     = "rg-hcp-terraform-demo"
location                = "westeurope"
vnet_name               = "vnet-hcp-demo"
vnet_address_space      = ["10.0.0.0/16"]
subnet_name             = "subnet-hcp-demo"
subnet_address_prefixes = ["10.0.1.0/24"]
vm_name                 = "vm-hcp-demo"
admin_username          = "azureuser"
public_key              = "ssh-rsa REPLACE_WITH_YOUR_PUBLIC_KEY"
```

## HCP Terraform Project

In HCP Terraform, create a project for the training resources. The captured project name was `Azure-Training-Projects`.

![Create an HCP Terraform project](docs/images/06-hcp-create-project.png)

Optionally add tags to describe the project or environment.

![Add project metadata](docs/images/07-hcp-project-tags.png)

After creation, the project appears in the HCP Terraform project list.

![HCP Terraform project created](docs/images/08-hcp-project-created.png)

## HCP Terraform Workspace

Create a workspace connected to the GitHub repository. The captured workspace was named `azure-hcp-terraform-vcs`.

![Create a VCS-backed HCP Terraform workspace](docs/images/09-hcp-create-workspace-vcs.png)

Configure the workspace settings and select the repository branch HCP Terraform should track.

![Configure the workspace](docs/images/10-hcp-workspace-configuration.png)

When HCP Terraform reads the repository, it detects the required Terraform input variables from `variables.tf`.

![Detected Terraform input variables](docs/images/11-hcp-terraform-input-variables.png)

## Workspace Variables

Add the Terraform input variables in the workspace. For list values, enable HCL so values such as `["10.0.0.0/16"]` and `["10.0.1.0/24"]` are interpreted correctly.

Recommended Terraform variable settings:

| Key | Category | HCL | Sensitive |
| --- | --- | --- | --- |
| `admin_username` | Terraform variable | Yes | No |
| `location` | Terraform variable | Yes | No |
| `resource_group_name` | Terraform variable | Yes | No |
| `subnet_address_prefixes` | Terraform variable | Yes | No |
| `subnet_name` | Terraform variable | Yes | No |
| `vm_name` | Terraform variable | Yes | No |
| `vnet_address_space` | Terraform variable | Yes | No |
| `vnet_name` | Terraform variable | Yes | No |
| `public_key` | Terraform variable | No | Yes |

Add Azure authentication values as environment variables and mark them sensitive.

| Key | Category | Sensitive |
| --- | --- | --- |
| `ARM_CLIENT_ID` | Environment variable | Yes |
| `ARM_CLIENT_SECRET` | Environment variable | Yes |
| `ARM_SUBSCRIPTION_ID` | Environment variable | Yes |
| `ARM_TENANT_ID` | Environment variable | Yes |

![Add an Azure authentication variable](docs/images/12-hcp-add-azure-variable.png)

The final workspace variables page should include both Terraform input variables and Azure authentication environment variables.

![Workspace variables list](docs/images/13-hcp-workspace-variables.png)

The captured setup also shows the Azure credentials listed as environment variables and marked sensitive.

![Azure provider credentials as environment variables](docs/images/14-hcp-dynamic-provider-credentials.png)

## Run Workflow

After the workspace is connected and variables are configured, HCP Terraform uploads the configuration from GitHub and starts a run.

![Configuration uploaded successfully](docs/images/15-hcp-configuration-uploaded.png)

Review the plan carefully before applying. The captured plan showed 8 resources to create and 3 outputs.

![Plan with 8 resources to create](docs/images/16-hcp-plan-eight-resources.png)

Confirm and apply the run only after checking the resource list and expected outputs.

![Confirm and apply the run](docs/images/17-hcp-confirm-apply.png)

Once the apply completes, HCP Terraform shows all 8 resources as created. The outputs include:

- `public_ip_address`
- `resource_group_name`
- `vm_name`

![Apply completed with created resources](docs/images/18-hcp-apply-created-resources.png)

The run confirmation records the approval comment and confirms the desired state was applied.

![Run confirmed](docs/images/19-hcp-run-confirmed.png)

## Verify in Azure

Open the Azure Portal and navigate to the resource group. The captured deployment created the following visible resources:

- `vm-hcp-demo`
- `vm-hcp-demo-nic`
- `vm-hcp-demo-nsg`
- `vm-hcp-demo-osdisk`
- `vm-hcp-demo-public-ip`
- `vnet-hcp-demo`

![Azure resource group with deployed resources](docs/images/20-azure-portal-resource-group.png)

## Local Terraform Commands

You can also validate the configuration locally:

```powershell
terraform init
terraform fmt -check
terraform validate
terraform plan
```

For local Azure authentication, sign in with Azure CLI or set the required Azure environment variables before running `terraform plan` or `terraform apply`.

```powershell
az login
az account set --subscription "<subscription-id>"
```

## Destroy Workflow

To remove the infrastructure from HCP Terraform, open the workspace settings and go to **Destruction and deletion**. Enable destroy plans if needed, then queue a destroy plan.

![HCP Terraform destruction settings](docs/images/21-hcp-destruction-settings.png)

HCP Terraform asks for confirmation before queuing the destroy plan. Type `delete` to continue.

![Queue destroy plan confirmation](docs/images/22-hcp-queue-destroy-plan.png)

Review the destroy plan. The captured destroy plan showed 8 resources planned for destruction.

![Destroy plan waiting for confirmation](docs/images/23-hcp-destroy-confirm-apply.png)

After confirmation, HCP Terraform destroys the managed Azure resources and records a new state version.

![Destroyed resources in HCP Terraform](docs/images/24-hcp-destroyed-resources.png)

## Outputs

| Output | Description |
| --- | --- |
| `resource_group_name` | Name of the created Azure resource group |
| `public_ip_address` | Public IP address assigned to the virtual machine |
| `vm_name` | Name of the Linux virtual machine |

## Good Practices for This Project

- Commit `.terraform.lock.hcl` after running `terraform init` so provider selections are reproducible.
- Keep `terraform.tfvars`, state files, secrets, and private keys out of Git.
- Add a `terraform.tfvars.example` file for non-sensitive sample values.
- Restrict SSH access instead of allowing `source_address_prefix = "*"`.
- Pin the Ubuntu image version instead of using `version = "latest"` if reproducibility is important.
- Add variable validation for Azure regions, CIDR ranges, usernames, and SSH public key format.

## Screenshot Index

| Step | Screenshot |
| --- | --- |
| GitHub repository creation | ![GitHub repository creation](docs/images/01-github-create-repository.png) |
| Git clone and push | ![Git clone and push](docs/images/02-git-clone-and-push.png) |
| Terraform files in terminal | ![Terraform files in terminal](docs/images/03-terraform-files-terminal.png) |
| GitHub repository files | ![GitHub repository files](docs/images/04-github-repository-files.png) |
| Azure app registration | ![Azure app registration](docs/images/05-azure-app-registration.png) |
| HCP project creation | ![HCP project creation](docs/images/06-hcp-create-project.png) |
| HCP project tags | ![HCP project tags](docs/images/07-hcp-project-tags.png) |
| HCP project created | ![HCP project created](docs/images/08-hcp-project-created.png) |
| HCP VCS workspace | ![HCP VCS workspace](docs/images/09-hcp-create-workspace-vcs.png) |
| Workspace configuration | ![Workspace configuration](docs/images/10-hcp-workspace-configuration.png) |
| Terraform input variables | ![Terraform input variables](docs/images/11-hcp-terraform-input-variables.png) |
| Azure variable entry | ![Azure variable entry](docs/images/12-hcp-add-azure-variable.png) |
| Workspace variables | ![Workspace variables](docs/images/13-hcp-workspace-variables.png) |
| Azure environment variables | ![Azure environment variables](docs/images/14-hcp-dynamic-provider-credentials.png) |
| Configuration upload | ![Configuration upload](docs/images/15-hcp-configuration-uploaded.png) |
| Plan result | ![Plan result](docs/images/16-hcp-plan-eight-resources.png) |
| Apply confirmation | ![Apply confirmation](docs/images/17-hcp-confirm-apply.png) |
| Apply completed | ![Apply completed](docs/images/18-hcp-apply-created-resources.png) |
| Run confirmed | ![Run confirmed](docs/images/19-hcp-run-confirmed.png) |
| Azure Portal resources | ![Azure Portal resources](docs/images/20-azure-portal-resource-group.png) |
| Destruction settings | ![Destruction settings](docs/images/21-hcp-destruction-settings.png) |
| Queue destroy plan | ![Queue destroy plan](docs/images/22-hcp-queue-destroy-plan.png) |
| Destroy confirmation | ![Destroy confirmation](docs/images/23-hcp-destroy-confirm-apply.png) |
| Destroy completed | ![Destroy completed](docs/images/24-hcp-destroyed-resources.png) |
