output "id" {
  value = azapi_resource.container_app_job.id
}
output "name" {
  value       = azapi_resource.container_app_job.name
  description = "Specifies the name of the container app job."
}