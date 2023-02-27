# Skaylink Terraform module: Azure Kubernetes Service

This module deploy a standardized AKS setup, with the posibility to deploy [Ingress NGINX](https://kubernetes.github.io/ingress-nginx/) and [Argo CD](https://argoproj.github.io/cd).

When deploying Ingress NGINX, you will need to supply a virtual network Id to add the `Network Contributor` role to the cluster managed identity. You can choose to not supply anything for the `aks_vnet_id` variable, but you will then have to add the required role to the virtual network manually.

## Example AKS configuration block

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
