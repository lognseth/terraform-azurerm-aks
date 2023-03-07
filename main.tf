#tfsec:ignore:azure-container-logging
resource "azurerm_kubernetes_cluster" "kubernetes" {
  lifecycle {
    ignore_changes = [
      default_node_pool[0].node_count
    ]
  }

  name                              = var.name
  location                          = data.azurerm_resource_group.resourcegroup.location
  resource_group_name               = data.azurerm_resource_group.resourcegroup.name
  dns_prefix                        = var.name
  kubernetes_version                = var.aks_configuration.kubernetes_version
  azure_policy_enabled              = var.aks_addons.enable_azure_policy
  public_network_access_enabled     = var.public_network_access_enabled
  api_server_authorized_ip_ranges   = var.public_network_access_enabled == true ? null : var.authorized_ip_ranges
  role_based_access_control_enabled = true

  linux_profile {
    admin_username = var.aks_node_authentication.node_admin_username

    ssh_key {
      # remove any new lines using the replace interpolation function
      key_data = replace(var.aks_node_authentication.node_admin_ssh_public, "\n", "")
    }
  }

  default_node_pool {
    name                 = var.aks_configuration.kubernetes_default_node_pool_name
    type                 = "VirtualMachineScaleSets"
    node_count           = var.aks_configuration.kubernetes_node_count
    enable_auto_scaling  = var.aks_configuration.kubernetes_enable_auto_scaling
    min_count            = var.aks_configuration.kubernetes_min_node_count
    max_count            = var.aks_configuration.kubernetes_max_node_count
    vm_size              = var.aks_configuration.vm_size
    os_disk_size_gb      = var.aks_configuration.os_disk_size_gb
    vnet_subnet_id       = var.aks_subnet_id
    max_pods             = var.aks_configuration.max_pods
    orchestrator_version = var.aks_configuration.kubernetes_version
  }

  network_profile {
    network_plugin    = var.aks_configuration.network_plugin
    network_policy    = var.aks_configuration.network_policy
    load_balancer_sku = var.aks_configuration.load_balancer_sku
  }

  dynamic "service_principal" {
    for_each = var.use_managed_identity ? [] : ["SP"]
    content {
      client_id     = data.azurerm_key_vault_secret.aksspid[0].value
      client_secret = data.azurerm_key_vault_secret.aksspsecret[0].value
    }
  }

  dynamic "identity" {
    for_each = var.use_managed_identity ? ["SystemAssigned"] : []
    content {
      type = "SystemAssigned"
    }
  }
  dynamic "oms_agent" {
    for_each = var.aks_addons.aks_log_analytics_workspace_id == "" ? [] : ["create"]
    content {
      log_analytics_workspace_id = var.aks_addons.aks_log_analytics_workspace_id
    }
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "worker_node_pool" {
  count = var.aks_second_nodepool == true ? 1 : 0

  name                  = var.aks_second_nodepool_configuration.node_pool_name
  kubernetes_cluster_id = azurerm_kubernetes_cluster.kubernetes.id
  vm_size               = var.aks_second_nodepool_configuration.vm_size
  os_disk_size_gb       = var.aks_second_nodepool_configuration.os_disk_size_gb
  node_count            = var.aks_second_nodepool_configuration.kubernetes_node_count
  enable_auto_scaling   = var.aks_second_nodepool_configuration.kubernetes_enable_auto_scaling
  min_count             = var.aks_second_nodepool_configuration.kubernetes_min_node_count
  max_count             = var.aks_second_nodepool_configuration.kubernetes_max_node_count
  vnet_subnet_id        = var.aks_subnet_id
  max_pods              = var.aks_second_nodepool_configuration.max_pods
  orchestrator_version  = var.aks_configuration.kubernetes_version
}

resource "azurerm_role_assignment" "aks_network_role" {
  count = var.ingress_controller == true ? 1 : 0

  scope                = var.aks_vnet_id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_kubernetes_cluster.kubernetes.identity[0].principal_id
}

# Create Static Public IP Address to be used by Nginx Ingress
resource "azurerm_public_ip" "nginx_ingress" {
  count               = var.ingress_controller == true ? 1 : 0
  depends_on          = [azurerm_role_assignment.aks_network_role]
  name                = "${var.name}-public-IP"
  location            = azurerm_kubernetes_cluster.kubernetes.location
  resource_group_name = azurerm_kubernetes_cluster.kubernetes.node_resource_group
  allocation_method   = "Static"
  domain_name_label   = var.ip_domain_name_label
  sku                 = var.aks_configuration.load_balancer_sku == "standard" ? "Standard" : "Basic"
}

resource "helm_release" "nginx_ingress_controller" {
  count      = var.ingress_controller == true ? 1 : 0
  depends_on = [azurerm_role_assignment.aks_network_role]
  name       = "nginx-ingress-controller"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"

  set {
    name  = "controller.replicaCount"
    value = 2
  }

  set {
    name  = "controller.service.loadBalancerIP"
    value = azurerm_public_ip.nginx_ingress[0].ip_address
  }

  set {
    name  = "controller.service.externalTrafficPolicy"
    value = "Local"
  }

  set {
    name  = "controller.metrics.enabled"
    value = "true"
  }

  /* set {
    name  = "controller.metrics.serviceMonitor.enabled"
    value = "true"
  }

  set {
    name  = "controller.metrics.serviceMonitor.additionalLabels.release"
    value = "kube-prometheus-stack"
  } */
}

resource "kubernetes_namespace" "argo_cd_namespace" {
  count = var.argo_cd == true ? 1 : 0
  metadata {
    name = "argocd"
  }
}

resource "helm_release" "argo_cd" {
  count      = var.argo_cd == true ? 1 : 0
  depends_on = [kubernetes_namespace.argo_cd_namespace[0]]

  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "4.5.0"
  namespace  = kubernetes_namespace.argo_cd_namespace[0].metadata[0].name

  # Documentation on possible values can be found here: https://github.com/argoproj/argo-helm/blob/main/charts/argo-cd/README.md
  set {
    name  = "controller.metrics.enabled"
    value = "true"
  }
  /* 
  set {
    name  = "controller.metrics.serviceMonitor.enabled"
    value = "true"
  }

  set {
    name  = "controller.metrics.serviceMonitor.additionalLabels.release"
    value = "kube-prometheus-stack"
  } */
}
