# Skaylink Terraform module: Azure Kubernetes Service

This module deploy a standardized AKS setup, with the posibility to deploy [Ingress NGINX](https://kubernetes.github.io/ingress-nginx/) and [Argo CD](https://argoproj.github.io/cd).

When deploying Ingress NGINX, you will need to supply a virtual network Id to add the `Network Contributor` role to the cluster managed identity. You can choose to not supply anything for the `aks_vnet_id` variable, but you will then have to add the required role to the virtual network manually. 

### Example AKS configuration block

```hcl
  aks_configuration = {
    vm_size                           = "standard_b2ms"
    os_disk_size_gb                   = 128
    kubernetes_node_count             = 2
    kubernetes_min_node_count         = 1
    kubernetes_max_node_count         = 3
    kubernetes_enable_auto_scaling    = true
    network_plugin                    = "azure"
    network_policy                    = "azure"
    max_pods                          = 30
    kubernetes_version                = "1.23.8"
    kubernetes_default_node_pool_name = "agentpool"
    load_balancer_sku                 = "basic"
  }
```
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | 2.5.1 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~>2.11.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | n/a |
| <a name="provider_helm"></a> [helm](#provider\_helm) | 2.5.1 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | ~>2.11.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_kubernetes_cluster.kubernetes](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster) | resource |
| [azurerm_kubernetes_cluster_node_pool.worker_node_pool](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster_node_pool) | resource |
| [azurerm_public_ip.nginx_ingress](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) | resource |
| [azurerm_role_assignment.aks_network_role](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [helm_release.argo_cd](https://registry.terraform.io/providers/hashicorp/helm/2.5.1/docs/resources/release) | resource |
| [helm_release.nginx_ingress_controller](https://registry.terraform.io/providers/hashicorp/helm/2.5.1/docs/resources/release) | resource |
| [kubernetes_namespace.argo_cd_namespace](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [azurerm_key_vault_secret.aksspid](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/key_vault_secret) | data source |
| [azurerm_key_vault_secret.aksspsecret](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/key_vault_secret) | data source |
| [azurerm_resource_group.resourcegroup](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aks_addons"></a> [aks\_addons](#input\_aks\_addons) | Defines which addons will be activated. | <pre>object({<br>    aks_log_analytics_workspace_id   = string<br>    aks_log_analytics_workspace_name = string<br>    enable_kubernetes_dashboard      = bool<br>    enable_azure_policy              = bool<br>  })</pre> | <pre>{<br>  "aks_log_analytics_workspace_id": "",<br>  "aks_log_analytics_workspace_name": "",<br>  "enable_azure_policy": false,<br>  "enable_kubernetes_dashboard": false<br>}</pre> | no |
| <a name="input_aks_configuration"></a> [aks\_configuration](#input\_aks\_configuration) | Defines AKS performance and size parameters | <pre>object({<br>    vm_size                           = string<br>    os_disk_size_gb                   = number<br>    kubernetes_node_count             = number<br>    kubernetes_min_node_count         = number<br>    kubernetes_max_node_count         = number<br>    kubernetes_enable_auto_scaling    = bool<br>    network_plugin                    = string<br>    max_pods                          = number<br>    network_policy                    = string<br>    kubernetes_version                = string<br>    kubernetes_default_node_pool_name = string<br>    load_balancer_sku                 = string<br>  })</pre> | <pre>{<br>  "kubernetes_default_node_pool_name": "agentpool",<br>  "kubernetes_enable_auto_scaling": false,<br>  "kubernetes_max_node_count": null,<br>  "kubernetes_min_node_count": null,<br>  "kubernetes_node_count": 2,<br>  "kubernetes_version": "1.23.8",<br>  "load_balancer_sku": "basic",<br>  "max_pods": 50,<br>  "network_plugin": "azure",<br>  "network_policy": "azure",<br>  "os_disk_size_gb": 128,<br>  "vm_size": "Standard_D2s_v5"<br>}</pre> | no |
| <a name="input_aks_node_authentication"></a> [aks\_node\_authentication](#input\_aks\_node\_authentication) | SSH Information to access node pool vms | <pre>object({<br>    node_admin_username   = string<br>    node_admin_ssh_public = string<br>  })</pre> | n/a | yes |
| <a name="input_aks_second_nodepool"></a> [aks\_second\_nodepool](#input\_aks\_second\_nodepool) | Toggles wether the AKS is using an additional nodepool. Make sure that load\_balancer\_sku has to be set to 'standard' | `bool` | `false` | no |
| <a name="input_aks_second_nodepool_configuration"></a> [aks\_second\_nodepool\_configuration](#input\_aks\_second\_nodepool\_configuration) | Defines AKS user nodepool performance and size parameters | <pre>object({<br>    vm_size                        = string<br>    os_disk_size_gb                = number<br>    kubernetes_node_count          = number<br>    kubernetes_min_node_count      = number<br>    kubernetes_max_node_count      = number<br>    kubernetes_enable_auto_scaling = bool<br>    max_pods                       = number<br>    node_pool_name                 = string<br>  })</pre> | <pre>{<br>  "kubernetes_enable_auto_scaling": true,<br>  "kubernetes_max_node_count": 1,<br>  "kubernetes_min_node_count": 1,<br>  "kubernetes_node_count": 1,<br>  "max_pods": 30,<br>  "node_pool_name": "workerpool",<br>  "os_disk_size_gb": 32,<br>  "vm_size": "Standard_B2s"<br>}</pre> | no |
| <a name="input_aks_subnet_id"></a> [aks\_subnet\_id](#input\_aks\_subnet\_id) | The subnet ID to use for the AKS cluster | `string` | n/a | yes |
| <a name="input_aks_vnet_id"></a> [aks\_vnet\_id](#input\_aks\_vnet\_id) | Scope to provide Network Contributor access to the AKS cluster when deploying Ingress NGINX | `string` | `null` | no |
| <a name="input_argo_cd"></a> [argo\_cd](#input\_argo\_cd) | Set this value to true if you want to use Argo CD | `bool` | `false` | no |
| <a name="input_authorized_ip_ranges"></a> [authorized\_ip\_ranges](#input\_authorized\_ip\_ranges) | Authorized IP ranges for the AKS cluster if AKS cluster is not publicly accessible. | `list(string)` | `null` | no |
| <a name="input_environment_name"></a> [environment\_name](#input\_environment\_name) | The name of the environment to deploy the AKS cluster in, commonly used names are dev, qa and prod. | `string` | n/a | yes |
| <a name="input_ingress_controller"></a> [ingress\_controller](#input\_ingress\_controller) | Set this value to true if you want to use an ingress controller | `bool` | `false` | no |
| <a name="input_ip_domain_name_label"></a> [ip\_domain\_name\_label](#input\_ip\_domain\_name\_label) | The domain name label for the AKS cluster's public IP address | `string` | `null` | no |
| <a name="input_key_vault_id"></a> [key\_vault\_id](#input\_key\_vault\_id) | The ID of the key vault where you want to store the AKS cluster secrets | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | Name of the AKS cluster | `string` | n/a | yes |
| <a name="input_public_network_access_enabled"></a> [public\_network\_access\_enabled](#input\_public\_network\_access\_enabled) | Enable or disable public network access for the AKS cluster | `bool` | `true` | no |
| <a name="input_resourcegroup"></a> [resourcegroup](#input\_resourcegroup) | The resource group where the cluster will be created | `string` | n/a | yes |
| <a name="input_use_managed_identity"></a> [use\_managed\_identity](#input\_use\_managed\_identity) | Toggles wether the AKS is built using a managed identity (true) or a Service Principal to authenticate within Azure Cloud (false); Managed Identity is the recommended approach. | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cluster"></a> [cluster](#output\_cluster) | n/a |
<!-- END_TF_DOCS -->