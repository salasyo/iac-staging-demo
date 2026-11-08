output "staging_network_id" {
  description = "ID of the isolated staging network"
  value       = docker_network.staging_network.id
}

output "app_server_url" {
  description = "Local URL for the provisioned staging app server"
  value       = "http://localhost:${var.app_port}"
}

output "database_container_name" {
  description = "Provisioned PostgreSQL database container name"
  value       = docker_container.staging_db.name
}
