variable "resourcegroup" {
  type        = string
  description = "The resource group where the cluster will be created"
}

variable "name" {
  type        = string
  description = "Name of the AKS cluster"
}

variable "authorized_ip_ranges" {
  type        = list(string)
  description = "Authorized IP ranges for the AKS cluster if AKS cluster is not publicly accessible."
  default     = null
}

variable "public_network_access_enabled" {
  type        = bool
  default     = true
  description = "Enable or disable public network access for the AKS cluster"
}

variable "use_managed_identity" {
  type        = bool
  description = "Toggles wether the AKS is built using a managed identity (true) or a Service Principal to authenticate within Azure Cloud (false); Managed Identity is the recommended approach."
  default     = true
}

variable "aks_subnet_id" {
  type        = string
  description = "The subnet ID to use for the AKS cluster"
}

variable "aks_vnet_id" {
  type        = string
  default     = null
  description = "Scope to provide Network Contributor access to the AKS cluster when deploying Ingress NGINX"
}

variable "environment_name" {
  type        = string
  description = "The name of the environment to deploy the AKS cluster in, commonly used names are dev, qa and prod."
}

variable "key_vault_id" {
  type        = string
  description = "The ID of the key vault where you want to store the AKS cluster secrets"
}

variable "key_vault_name" {
  type = string
}

variable "namespaces" {
  type        = list(string)
  description = "A list of namespaces to create in the cluster"
  default     = ["ns"]
}

variable "argo_config" {
  type = object({
    username = string
    password = string
    repo_url = string
    app_path = string
  })
}

variable "aks_configuration" {
  description = "Defines AKS performance and size parameters"
  type = object({
    vm_size                           = string
    os_disk_size_gb                   = number
    kubernetes_node_count             = number
    kubernetes_min_node_count         = number
    kubernetes_max_node_count         = number
    kubernetes_enable_auto_scaling    = bool
    network_plugin                    = string
    max_pods                          = number
    network_policy                    = string
    kubernetes_version                = string
    kubernetes_default_node_pool_name = string
    load_balancer_sku                 = string
  })
  default = {
    kubernetes_enable_auto_scaling    = false
    kubernetes_max_node_count         = null
    kubernetes_min_node_count         = null
    kubernetes_node_count             = 2
    kubernetes_version                = "1.25.5"
    max_pods                          = 50
    network_plugin                    = "azure"
    network_policy                    = "azure"
    os_disk_size_gb                   = 128
    vm_size                           = "Standard_D2s_v5"
    kubernetes_default_node_pool_name = "agentpool"
    load_balancer_sku                 = "basic"
  }
}

variable "aks_second_nodepool_configuration" {
  description = "Defines AKS user nodepool performance and size parameters"
  type = object({
    vm_size                        = string
    os_disk_size_gb                = number
    kubernetes_node_count          = number
    kubernetes_min_node_count      = number
    kubernetes_max_node_count      = number
    kubernetes_enable_auto_scaling = bool
    max_pods                       = number
    node_pool_name                 = string
  })
  default = {
    vm_size                        = "Standard_B2s"
    os_disk_size_gb                = 32
    kubernetes_node_count          = 1
    kubernetes_min_node_count      = 1
    kubernetes_max_node_count      = 1
    kubernetes_enable_auto_scaling = true
    max_pods                       = 30
    node_pool_name                 = "workerpool"
  }
}

variable "aks_second_nodepool" {
  type        = bool
  description = "Toggles wether the AKS is using an additional nodepool. Make sure that load_balancer_sku has to be set to 'standard'"
  default     = false
}

variable "aks_node_authentication" {
  description = "SSH Information to access node pool vms"
  type = object({
    node_admin_username   = string
    node_admin_ssh_public = string
  })
}

variable "aks_addons" {
  description = "Defines which addons will be activated."
  type = object({
    aks_log_analytics_workspace_id   = string
    aks_log_analytics_workspace_name = string
    enable_kubernetes_dashboard      = bool
    enable_azure_policy              = bool
  })
  default = {
    aks_log_analytics_workspace_id   = ""
    aks_log_analytics_workspace_name = ""
    enable_kubernetes_dashboard      = false
    enable_azure_policy              = false
  }
}
variable "ingress_controller" {
  type        = bool
  default     = false
  description = "Set this value to true if you want to use an ingress controller"
}

variable "metrics_enabled" {
  type        = bool
  description = "Allow exposing nginx-ingress metrics for prometheus-operator"
  default     = false
}

variable "argo_cd" {
  type        = bool
  default     = false
  description = "Set this value to true if you want to use Argo CD"
}

variable "ip_domain_name_label" {
  type        = string
  default     = null
  description = "The domain name label for the AKS cluster's public IP address"
}
