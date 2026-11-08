variable "environment" {
  description = "Deployment environment name"
  type        = string
  default     = "staging"
}

variable "network_name" {
  description = "Isolated Docker bridge network for staging"
  type        = string
  default     = "staging_vpc_net"
}

variable "app_port" {
  description = "External port exposed for the application server"
  type        = number
  default     = 8080
}

variable "db_port" {
  description = "External port exposed for the database"
  type        = number
  default     = 5432
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "staging_db"
}

variable "db_user" {
  description = "Database username"
  type        = string
  default     = "staging_admin"
}

variable "db_password" {
  description = "Database password injected dynamically via TF_VAR_db_password"
  type        = string
  sensitive   = true
}
