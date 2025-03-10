# This block sets the required provides that this terraform configuration will use and their versions. 
# The azurerm provider is used to interact with Azure resources, and the kubernetes provider is used to interact with Kubernetes resources.
# The version constraints are set to ensure compatibility with the configuration.
# You can adjust the version constraints as needed.
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

# This block sets the Azure provider configuration.
# The values for client_id, client_secret, subscription_id, and tenant_id are placeholders.
# You should replace them with your own values.
provider "azurerm" {
  features {}
  client_id       = var.client_id
  client_secret   = var.client_secret
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
}
variable "client_id" {
  type    = string
  default = env("ARM_CLIENT_ID")
}

variable "client_secret" {
  type    = string
  default = env("ARM_CLIENT_SECRET")
}

variable "subscription_id" {
  type    = string
  default = env("ARM_SUBSCRIPTION_ID")
}

variable "tenant_id" {
  type    = string
  default = env("ARM_TENANT_ID")
}

# This block creates an Azure resource group that will contain the AKS cluster.
# The name and location of the resource group are set to "aks-resource-group" and "eastus" respectively.
resource "azurerm_resource_group" "aks_rg" {
  name     = "aks-resource-group"
  location = "eastus" # Choose your desired Azure region
}

# This block creates an AKS cluster in the specified resource group.
# The name of the cluster is set to "myakscluster" and the DNS prefix is set to "myaksdns".
# The default node pool configuration specifies the number of nodes and the VM size.
# The identity block specifies that the AKS cluster should have a system-assigned identity.
resource "azurerm_kubernetes_cluster" "aks_cluster" {
  name                = "myakscluster"
  location            = azurerm_resource_group.aks_rg.location
  resource_group_name = azurerm_resource_group.aks_rg.name
  dns_prefix          = "myaksdns"

  default_node_pool {
    name       = "default"
    node_count = 2 # Adjust the number of nodes as needed
    vm_size    = "Standard_DS2_v2" # Choose an appropriate VM size
  }

  identity {
    type = "SystemAssigned"
  }
}

# This block retrieves the kubeconfig for the AKS cluster.
# The kubeconfig is used to authenticate with the AKS cluster and interact with Kubernetes resources.
# The depends_on argument ensures that the AKS cluster is created before retrieving the kubeconfig.
data "azurerm_kubernetes_cluster" "aks" {
  name                = azurerm_kubernetes_cluster.aks_cluster.name
  resource_group_name = azurerm_resource_group.aks_rg.name
  depends_on = [
    azurerm_kubernetes_cluster.aks_cluster
  ]
}

# This block configures the Kubernetes provider with the kubeconfig retrieved from the AKS cluster.
# The kubeconfig contains the necessary information to authenticate with the AKS cluster.
# The provider block specifies the host, client_certificate, client_key, and cluster_ca_certificate.
# These values are extracted from the kubeconfig data source.
# The provider block can be used to interact with Kubernetes resources in the AKS cluster.
provider "kubernetes" {
  host                   = data.azurerm_kubernetes_cluster.aks.kube_config.0.host
  client_certificate     = base64decode(data.azurerm_kubernetes_cluster.aks.kube_config.0.client_certificate)
  client_key             = base64decode(data.azurerm_kubernetes_cluster.aks.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.aks.kube_config.0.cluster_ca_certificate)
}

# This block outputs the kubeconfig, client_certificate, client_key, cluster_ca_certificate, host, AKS cluster name, and resource group name.
# The values are sensitive, meaning they will not be displayed in plain text in the Terraform output.
# The kubeconfig can be used to authenticate with the AKS cluster and interact with Kubernetes resources.
# The other outputs provide additional information about the AKS cluster.
output "kube_config" {
  value     = data.azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive = true
}

# The client_certificate, client_key, cluster_ca_certificate, and host values are extracted from the kubeconfig and outputted.
# These values can be used to authenticate with the AKS cluster and interact with Kubernetes resources.
output "client_certificate" {
  value = data.azurerm_kubernetes_cluster.aks.kube_config.0.client_certificate
  sensitive = true
}

output "client_key" {
  value = data.azurerm_kubernetes_cluster.aks.kube_config.0.client_key
  sensitive = true
}

output "cluster_ca_certificate" {
  value = data.azurerm_kubernetes_cluster.aks.kube_config.0.cluster_ca_certificate
  sensitive = true
}

# The host value is extracted from the kubeconfig and outputted.
# The host value is the API server endpoint for the AKS cluster.
output "host" {
  value = data.azurerm_kubernetes_cluster.aks.kube_config.0.host
  sensitive = true
}

# The AKS cluster name and resource group name are outputted.
# These values provide additional information about the AKS cluster.
# The AKS cluster name can be used to reference the AKS cluster in other configurations.
output "aks_cluster_name" {
  value = azurerm_kubernetes_cluster.aks_cluster.name
}

# The resource group name is outputted.
# This value provides additional information about the resource group containing the AKS cluster.
# The resource group name can be used to reference the resource group in other configurations.
output "aks_resource_group_name" {
  value = azurerm_resource_group.aks_rg.name
}