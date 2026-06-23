output "deployment_name" {
  value = kubernetes_deployment_v1.this.metadata[0].name
}

output "app_label" {
  value = var.name
}