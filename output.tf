output "cluster" {
  value = azurerm_kubernetes_cluster.kubernetes
  # Output is sensitive it might potentially print the AKS' Service Principal Credentials, if used
  sensitive = true
}
