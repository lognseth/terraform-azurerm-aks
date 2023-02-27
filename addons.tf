##############
# Namespaces #
##############

resource "kubernetes_namespace" "ns" {
  for_each = toset(var.namespaces)
  metadata {
    name = each.value
  }
}

###########
# ARGO CD #
###########

resource "kubernetes_namespace" "argo_ns" {
  count = var.argo_cd == true ? 1 : 0
  metadata {
    name = "argocd"
  }
}

resource "helm_release" "argocd" {
  count      = var.argo_cd == true ? 1 : 0
  depends_on = [kubernetes_namespace.ns]
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "5.16.2"
  namespace  = kubernetes_namespace.argo_ns.metadata[0].name
}

resource "helm_release" "gitops_app" {
  count      = var.argo_cd == true ? 1 : 0
  depends_on = [helm_release.argocd, kubernetes_namespace.ns]
  name       = "argo-applications"
  chart      = "charts/argo-applications"
  namespace  = "argocd"

  set_sensitive {
    name  = "apps.password"
    value = base64encode(var.argo_config.password)
  }

  set {
    name  = "apps.username"
    value = base64encode(var.argo_config.username)
  }
  set {
    name  = "apps.url"
    value = base64encode(var.argo_config.repo_url)
  }
  set {
    name  = "apps.path"
    value = base64encode(var.argo_config.app_path)
  }
}

#############################
# Key Vault Secret Provider #
#############################

# Creating the SecretProviderClasses in argo namespace
resource "helm_release" "csi_key_vault_argo" {
  for_each   = toset(var.namespaces)
  depends_on = [kubernetes_namespace.ns]
  name       = "csi-key-vault"
  chart      = "charts/csi-key-vault"
  namespace  = each.value

  set_sensitive {
    name  = "tenant_id"
    value = data.azurerm_client_config.current.tenant_id
  }

  set {
    name  = "kv_name"
    value = var.key_vault_name
  }

  set_sensitive {
    name  = "managed_identity_id"
    value = azurerm_kubernetes_cluster.kubernetes.kubelet_identity[0].client_id
  }

  # This makes the underlaying driver to be installed (required just once!)
  set {
    name  = "csi-secrets-store-provider-azure.install"
    value = "true"
  }
}

###########
# Ingress #
###########

resource "kubernetes_namespace" "ingress_ns" {
  count = var.ingress_controller == true ? 1 : 0
  metadata {
    name = "ingress-nginx"
  }
}

resource "helm_release" "nginx_ingress_controller" {
  count = var.ingress_controller == true ? 1 : 0

  name       = "nginx-ingress-controller"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  namespace  = kubernetes_namespace.ingress_ns.metadata[0].name

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

  set {
    name  = "controller.metrics.serviceMonitor.enabled"
    value = "true"
  }

  set {
    name  = "controller.metrics.serviceMonitor.additionalLabels.release"
    value = "kube-prometheus-stack"
  }
}
