

# We strongly recommend using the required_providers block to set the


# Create a resource group
resource "azurerm_resource_group" "devoprg" {
  name     = "devoprg-resources"
  location = "West Europe"
}

# Create a virtual network within the resource group
resource "azurerm_virtual_network" "devoprg" {
  name                = "devoprg-network"
  resource_group_name = azurerm_resource_group.devoprg.name
  location            = azurerm_resource_group.devoprg.location
  address_space       = ["10.0.0.0/16"]

}
# Subnet
resource "azurerm_subnet" "devoprg" {
  name                 = "mySubnet"
  resource_group_name  = azurerm_resource_group.devoprg.name
  virtual_network_name = azurerm_virtual_network.devoprg.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Azure Kubernetes Service (AKS)
resource "azurerm_kubernetes_cluster" "devoprg" {
  name                = "myAKSCluster"
  location            = azurerm_resource_group.devoprg.location
  resource_group_name = azurerm_resource_group.devoprg.name
  dns_prefix          = "myaksdns"

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_DS2_v2"
  }
  identity {
    type = "SystemAssigned"
  }
}

resource "local_file" "kube_config"{
    content = azurerm_kubernetes_cluster.devoprg.kube_config_raw
    filename = ".kube/config"
}

# Helm Chart - Nginx Ingress Controller
resource "helm_release" "nginx-ingress" {
  name       = "nginx-ingress"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "nginx-ingress-controller"
  namespace  = "default"

  set {
    name  = "controller.service.type"
    value = "LoadBalancer"
  }
}

# Helm Chart - Redis
resource "helm_release" "redis" {
  name       = "my-redis"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "redis"
  namespace  = "default"

  set {
    name  = "usePassword"
    value = "false"
  }
}





